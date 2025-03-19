// SPDX-License-Identifier: GPL-2.0
/*
 * NVMe ZNS-ZBD command implementation.
 * Copyright (C) 2021 Western Digital Corporation or its affiliates.
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#include <linux/nvme.h>
#include <linux/blkdev.h>
#include "nvmet.h"

/*
 * We set the Memory Page Size Minimum (MPSMIN) for target controller to 0
 * which gets added by 12 in the nvme_enable_ctrl() which results in 2^12 = 4k
 * as page_shift value. When calculating the ZASL use shift by 12.
 */
#define NVMET_MPSMIN_SHIFT	12

static u16 nvmet_bdev_validate_zone_mgmt_recv(struct nvmet_req *req)
{
	sector_t sect = nvmet_lba_to_sect(req->ns, req->cmd->zmr.slba);
	u32 out_bufsize = (le32_to_cpu(req->cmd->zmr.numd) + 1) << 2;

	if (sect > get_capacity(req->ns->bdev->bd_disk)) {
		req->error_loc = offsetof(struct nvme_zone_mgmt_recv_cmd, slba);
		return NVME_SC_INVALID_FIELD | NVME_SC_DNR;
	}

	if (out_bufsize < sizeof(struct nvme_zone_report)) {
		req->error_loc = offsetof(struct nvme_zone_mgmt_recv_cmd, numd);
		return NVME_SC_INVALID_FIELD | NVME_SC_DNR;
	}

	if (req->cmd->zmr.zra != NVME_ZRA_ZONE_REPORT) {
		req->error_loc = offsetof(struct nvme_zone_mgmt_recv_cmd, zra);
		return NVME_SC_INVALID_FIELD | NVME_SC_DNR;
	}

	switch (req->cmd->zmr.pr) {
	case 0:
	case 1:
		break;
	default:
		req->error_loc = offsetof(struct nvme_zone_mgmt_recv_cmd, pr);
		return NVME_SC_INVALID_FIELD | NVME_SC_DNR;
	}

	switch (req->cmd->zmr.zrasf) {
	case NVME_ZRASF_ZONE_REPORT_ALL:
	case NVME_ZRASF_ZONE_STATE_EMPTY:
	case NVME_ZRASF_ZONE_STATE_IMP_OPEN:
	case NVME_ZRASF_ZONE_STATE_EXP_OPEN:
	case NVME_ZRASF_ZONE_STATE_CLOSED:
	case NVME_ZRASF_ZONE_STATE_FULL:
	case NVME_ZRASF_ZONE_STATE_READONLY:
	case NVME_ZRASF_ZONE_STATE_OFFLINE:
		break;
	default:
		req->error_loc =
			offsetof(struct nvme_zone_mgmt_recv_cmd, zrasf);
		return NVME_SC_INVALID_FIELD | NVME_SC_DNR;
	}

	return NVME_SC_SUCCESS;
}

static inline u8 nvmet_zasl(unsigned int zone_append_sects)
{
	/*
	 * Zone Append Size Limit is the value expressed in the units of minimum
	 * memory page size (i.e. 12) and is reported as power of 2.
	 */
	return ilog2(zone_append_sects >> (NVMET_MPSMIN_SHIFT - 9));
}

static int nvmet_bdev_validate_zns_zones_cb(struct blk_zone *z,
					    unsigned int i, void *data)
{
	if (z->type == BLK_ZONE_TYPE_CONVENTIONAL)
		return -EOPNOTSUPP;
	return 0;
}

bool nvmet_bdev_zns_enable(struct nvmet_ns *ns)
{
	struct request_queue *q = ns->bdev->bd_disk->queue;
	u8 zasl = nvmet_zasl(queue_max_zone_append_sectors(q));
	int ret;

	if (ns->subsys->zasl) {
		if (ns->subsys->zasl > zasl)
			return false;
	}
	ns->subsys->zasl = zasl;

	if (ns->bdev->bd_disk->queue->conv_zones_bitmap)
		return true;

	/*
	 * ZNS does not define the conventional zone type. Exclude any device
	 * that has such zones.
	 */
	ret = blkdev_report_zones(ns->bdev, 0,
				  blkdev_nr_zones(ns->bdev->bd_disk),
				  nvmet_bdev_validate_zns_zones_cb, NULL);
	if (ret < 0)
		return false;

	ns->blksize_shift = blksize_bits(bdev_logical_block_size(ns->bdev));

	/*
	 * Generic zoned block devices may have a smaller last zone which is
	 * not supported by ZNS. Exclude zoned drives that have such smaller
	 * last zone.
	 */
	return !(get_capacity(ns->bdev->bd_disk) &
			(bdev_zone_sectors(ns->bdev) - 1));
}

void nvmet_execute_identify_cns_cs_ctrl(struct nvmet_req *req)
{
	u8 zasl = req->sq->ctrl->subsys->zasl;
	struct nvmet_ctrl *ctrl = req->sq->ctrl;
	struct nvme_id_ctrl_zns *id;
	u16 status;

	id = kzalloc(sizeof(*id), GFP_KERNEL);
	if (!id) {
		status = NVME_SC_INTERNAL;
		goto out;
	}

	if (ctrl->ops->get_mdts)
		id->zasl = min_t(u8, ctrl->ops->get_mdts(ctrl), zasl);
	else
		id->zasl = zasl;

	status = nvmet_copy_to_sgl(req, 0, id, sizeof(*id));

	kfree(id);
out:
	nvmet_req_complete(req, status);
}

void nvmet_execute_identify_cns_cs_ns(struct nvmet_req *req)
{
	struct nvme_id_ns_zns *id_zns;
	struct block_device *bdev = req->ns->bdev;
	u64 zsze;
	u16 status;

	if (le32_to_cpu(req->cmd->identify.nsid) == NVME_NSID_ALL) {
		req->error_loc = offsetof(struct nvme_identify, nsid);
		status = NVME_SC_INVALID_NS | NVME_SC_DNR;
		goto out;
	}

	id_zns = kzalloc(sizeof(*id_zns), GFP_KERNEL);
	if (!id_zns) {
		status = NVME_SC_INTERNAL;
		goto out;
	}

	status = nvmet_req_find_ns(req);
	if (status) {
		status = NVME_SC_INTERNAL;
		goto done;
	}

	if (!bdev_is_zoned(bdev)) {
		req->error_loc = offsetof(struct nvme_identify, nsid);
		status = NVME_SC_INVALID_NS | NVME_SC_DNR;
		goto done;
	}

	nvmet_ns_revalidate(req->ns);
	zsze = (bdev_zone_sectors(bdev) << 9) >>
					req->ns->blksize_shift;
	id_zns->lbafe[0].zsze = cpu_to_le64(zsze);
	id_zns->mor = cpu_to_le32(bdev_max_open_zones(bdev));
	id_zns->mar = cpu_to_le32(bdev_max_active_zones(bdev));

done:
	status = nvmet_copy_to_sgl(req, 0, id_zns, sizeof(*id_zns));
	kfree(id_zns);
out:
	nvmet_req_complete(req, status);
}

struct nvmet_report_zone_data {
	struct nvmet_req *req;
	u64 out_buf_offset;
	u64 out_nr_zones;
	u64 nr_zones;
	u8 zrasf;
};

static int nvmet_bdev_report_zone_cb(struct blk_zone *z, unsigned i, void *d)
{
	struct nvmet_report_zone_data *rz = d;
	static const unsigned int nvme_zrasf_to_blk_zcond[] = {
		[NVME_ZRASF_ZONE_STATE_EMPTY]	 = BLK_ZONE_COND_EMPTY,
		[NVME_ZRASF_ZONE_STATE_IMP_OPEN] = BLK_ZONE_COND_IMP_OPEN,
		[NVME_ZRASF_ZONE_STATE_EXP_OPEN] = BLK_ZONE_COND_EXP_OPEN,
		[NVME_ZRASF_ZONE_STATE_CLOSED]	 = BLK_ZONE_COND_CLOSED,
		[NVME_ZRASF_ZONE_STATE_READONLY] = BLK_ZONE_COND_READONLY,
		[NVME_ZRASF_ZONE_STATE_FULL]	 = BLK_ZONE_COND_FULL,
		[NVME_ZRASF_ZONE_STATE_OFFLINE]	 = BLK_ZONE_COND_OFFLINE,
	};

	if (rz->zrasf != NVME_ZRASF_ZONE_REPORT_ALL &&
	    z->cond != nvme_zrasf_to_blk_zcond[rz->zrasf])
		return 0;

	if (rz->nr_zones < rz->out_nr_zones) {
		struct nvme_zone_descriptor zdesc = { };
		u16 status;

		zdesc.zcap = nvmet_sect_to_lba(rz->req->ns, z->capacity);
		zdesc.zslba = nvmet_sect_to_lba(rz->req->ns, z->start);
		zdesc.wp = nvmet_sect_to_lba(rz->req->ns, z->wp);
		zdesc.za = z->reset ? 1 << 2 : 0;
		zdesc.zs = z->cond << 4;
		zdesc.zt = z->type;

		status = nvmet_copy_to_sgl(rz->req, rz->out_buf_offset, &zdesc,
					   sizeof(zdesc));
		if (status)
			return -EINVAL;

		rz->out_buf_offset += sizeof(zdesc);
	}

	rz->nr_zones++;

	return 0;
}

static unsigned long nvmet_req_nr_zones_from_slba(struct nvmet_req *req)
{
	unsigned int sect = nvmet_lba_to_sect(req->ns, req->cmd->zmr.slba);

	return blkdev_nr_zones(req->ns->bdev->bd_disk) -
		(sect >> ilog2(bdev_zone_sectors(req->ns->bdev)));
}

static unsigned long get_nr_zones_from_buf(struct nvmet_req *req, u32 bufsize)
{
	if (bufsize <= sizeof(struct nvme_zone_report))
		return 0;

	return (bufsize - sizeof(struct nvme_zone_report)) /
		sizeof(struct nvme_zone_descriptor);
}

void nvmet_bdev_execute_zone_mgmt_recv(struct nvmet_req *req)
{
	sector_t start_sect = nvmet_lba_to_sect(req->ns, req->cmd->zmr.slba);
	unsigned long req_slba_nr_zones = nvmet_req_nr_zones_from_slba(req);
	u32 out_bufsize = (le32_to_cpu(req->cmd->zmr.numd) + 1) << 2;
	__le64 nr_zones;
	u16 status;
	int rc;
	struct nvmet_report_zone_data rz_data = {
		.out_nr_zones = get_nr_zones_from_buf(req, out_bufsize),
		/* leave the place for report zone header */
		.out_buf_offset = sizeof(struct nvme_zone_report),
		.zrasf = req->cmd->zmr.zrasf,
		.nr_zones = 0,
		.req = req,
	};

	status = nvmet_bdev_validate_zone_mgmt_recv(req);
	if (status)
		goto out;

	if (!req_slba_nr_zones) {
		status = NVME_SC_SUCCESS;
		goto out;
	}

	rc = blkdev_report_zones(req->ns->bdev, start_sect, req_slba_nr_zones,
				 nvmet_bdev_report_zone_cb, &rz_data);
	if (rc < 0) {
		status = NVME_SC_INTERNAL;
		goto out;
	}

	if (req->cmd->zmr.pr) {
		/*
		 * When partial bit is set nr_zones must indicate the number of
		 * zone descriptors actually transferred.
		 */
		rz_data.nr_zones = min(rz_data.nr_zones, rz_data.out_nr_zones);
	}

	nr_zones= cpu_to_le64(rz_data.nr_zones);
	status = nvmet_copy_to_sgl(req, 0, &nr_zones, sizeof(nr_zones));

out:
	nvmet_req_complete(req, status);
}

static enum req_opf nvmet_zsa_to_req_op(u8 zsa)
{
	switch (zsa) {
	case NVME_ZONE_OPEN:
		return REQ_OP_ZONE_OPEN;
	case NVME_ZONE_CLOSE:
		return REQ_OP_ZONE_CLOSE;
	case NVME_ZONE_FINISH:
		return REQ_OP_ZONE_FINISH;
	case NVME_ZONE_RESET:
		return REQ_OP_ZONE_RESET;
	default:
		return REQ_OP_LAST;
	}
}

enum zmgmt_act {
	ZMGMT_ACT_CHANGE = 1,
	ZMGMT_ACT_IGNORE,
	ZMGMT_ACT_ERR,
};

static enum zmgmt_act zmgmt_default_act(bool all)
{
	return all ? ZMGMT_ACT_IGNORE : ZMGMT_ACT_ERR;
}

static enum zmgmt_act zmgmt_act_open(struct blk_zone *z, bool all)
{
	switch (z->cond) {
	/* zone is already open don't send REQ_OP_ZONE_OPEN */
	case BLK_ZONE_COND_EXP_OPEN:
		return ZMGMT_ACT_IGNORE;
	case BLK_ZONE_COND_IMP_OPEN:
		if (all)
			return ZMGMT_ACT_IGNORE;
		return ZMGMT_ACT_CHANGE;
	case BLK_ZONE_COND_CLOSED:
		if (all)
			return ZMGMT_ACT_IGNORE;
		return ZMGMT_ACT_CHANGE;
	case BLK_ZONE_COND_EMPTY:
		if (all)
			return ZMGMT_ACT_IGNORE;
		return ZMGMT_ACT_CHANGE;
	default:
		return zmgmt_default_act(all);
	}
}

static enum zmgmt_act zmgmt_act_close(struct blk_zone *z, bool all)
{
	switch (z->cond) {
	/* zone is already closed don't send REQ_OP_ZONE_CLOSE */
	case BLK_ZONE_COND_CLOSED:
		return ZMGMT_ACT_IGNORE;
	case BLK_ZONE_COND_IMP_OPEN:
	case BLK_ZONE_COND_EXP_OPEN:
		return ZMGMT_ACT_CHANGE;
	default:
		return zmgmt_default_act(all);
	}
}

static enum zmgmt_act zmgmt_act_finish(struct blk_zone *z, bool all)
{
	switch (z->cond) {
	/* zone is already full don't send REQ_OP_ZONE_FINISH */
	case BLK_ZONE_COND_FULL:
		return ZMGMT_ACT_IGNORE;
	case BLK_ZONE_COND_IMP_OPEN:
	case BLK_ZONE_COND_EXP_OPEN:
	case BLK_ZONE_COND_CLOSED:
		if (all)
			return ZMGMT_ACT_CHANGE;
		fallthrough;
	case BLK_ZONE_COND_EMPTY:
		if (all)
			return ZMGMT_ACT_IGNORE;
		return ZMGMT_ACT_CHANGE;
	default:
		return zmgmt_default_act(all);
	}
}

static enum zmgmt_act zmgmt_act_reset(struct blk_zone *z, bool all)
{
	switch (z->cond) {
	/* zone is already empty don't send REQ_OP_ZONE_RESET */
	case BLK_ZONE_COND_EMPTY:
		return ZMGMT_ACT_IGNORE;
	case BLK_ZONE_COND_IMP_OPEN:
	case BLK_ZONE_COND_EXP_OPEN:
	case BLK_ZONE_COND_CLOSED:
	case BLK_ZONE_COND_FULL:
		return ZMGMT_ACT_CHANGE;
	default:
		return zmgmt_default_act(all);
	}
}

static enum zmgmt_act zmgmt_op_decide_act(struct blk_zone *z, int op, bool all)
{
	switch (op) {
	case REQ_OP_ZONE_OPEN:
		return zmgmt_act_open(z, all);
	case REQ_OP_ZONE_CLOSE:
		return zmgmt_act_close(z, all);
	case REQ_OP_ZONE_FINISH:
		return zmgmt_act_finish(z, all);
	case REQ_OP_ZONE_RESET:
		return zmgmt_act_reset(z, all);
	default:
		return ZMGMT_ACT_ERR;
	}
}

static int nvmet_bdev_zmgmt_send_cb(struct blk_zone *z, unsigned i, void *d)
{
	struct nvmet_req *req = d;
	enum req_opf op = nvmet_zsa_to_req_op(req->cmd->zms.zsa);
	enum zmgmt_act zmgmt_act;

	zmgmt_act = zmgmt_op_decide_act(z, op, req->cmd->zms.select_all);
	switch (zmgmt_act) {
	case ZMGMT_ACT_IGNORE:
		return 0;
	case ZMGMT_ACT_CHANGE:
		return blkdev_zone_mgmt(req->ns->bdev,
					nvmet_zsa_to_req_op(req->cmd->zms.zsa),
					z->start,
					bdev_zone_sectors(req->ns->bdev),
					GFP_KERNEL);
	case ZMGMT_ACT_ERR:
		fallthrough;
	default:
		return -EINVAL;
	}
}

void nvmet_bdev_execute_zone_mgmt_send(struct nvmet_req *req)
{
	u16 status = NVME_SC_SUCCESS;
	unsigned int nr_zones;
	sector_t sect;
	int ret;

	/* don't even bother for invalid zsa value */
	if (nvmet_zsa_to_req_op(req->cmd->zms.zsa) == REQ_OP_LAST) {
		req->error_loc = offsetof(struct nvme_zone_mgmt_send_cmd, zsa);
		status = NVME_SC_INVALID_FIELD | NVME_SC_DNR;
		goto out;
	}

	if (req->cmd->zms.select_all) {
		sect = 0;
		nr_zones = blkdev_nr_zones(req->ns->bdev->bd_disk);
	} else {
		sect = nvmet_lba_to_sect(req->ns, req->cmd->zms.slba);
		nr_zones = 1;
	}

	ret = blkdev_report_zones(req->ns->bdev, sect, nr_zones,
				  nvmet_bdev_zmgmt_send_cb, req);
	if (ret < 0)
		status = NVME_SC_ZONE_INVALID_TRANSITION | NVME_SC_DNR;

out:
	nvmet_req_complete(req, status);
}

static void nvmet_bdev_zone_append_bio_done(struct bio *bio)
{
	struct nvmet_req *req = bio->bi_private;

	if (bio->bi_status == BLK_STS_OK) {
		req->cqe->result.u64 =
			nvmet_sect_to_lba(req->ns, bio->bi_iter.bi_sector);
	}

	nvmet_req_complete(req, blk_to_nvme_status(req, bio->bi_status));
	if (bio != &req->b.inline_bio)
		bio_put(bio);
}

void nvmet_bdev_execute_zone_append(struct nvmet_req *req)
{
	sector_t sect = nvmet_lba_to_sect(req->ns, req->cmd->rw.slba);
	u16 status = NVME_SC_SUCCESS;
	unsigned int total_len = 0;
	struct scatterlist *sg;
	int ret = 0, sg_cnt;
	struct bio *bio;

	/* Request is completed on len mismatch in nvmet_check_transter_len() */
	if (!nvmet_check_transfer_len(req, nvmet_rw_data_len(req)))
		return;

	if (!req->sg_cnt) {
		nvmet_req_complete(req, 0);
		return;
	}

	if (req->transfer_len <= NVMET_MAX_INLINE_DATA_LEN) {
		bio = &req->b.inline_bio;
		bio_init(bio, req->inline_bvec, ARRAY_SIZE(req->inline_bvec));
	} else {
		bio = bio_alloc(GFP_KERNEL, req->sg_cnt);
	}

	bio_set_dev(bio, req->ns->bdev);
	bio->bi_iter.bi_sector = sect;
	bio->bi_private = req;
	bio->bi_end_io = nvmet_bdev_zone_append_bio_done;
	bio->bi_opf = REQ_OP_ZONE_APPEND | REQ_SYNC | REQ_IDLE;
	if (req->cmd->rw.control & cpu_to_le16(NVME_RW_FUA))
		bio->bi_opf |= REQ_FUA;

	for_each_sg(req->sg, sg, req->sg_cnt, sg_cnt) {
		struct page *p = sg_page(sg);
		unsigned int l = sg->length;
		unsigned int o = sg->offset;

		ret = bio_add_zone_append_page(bio, p, l, o);
		if (ret != sg->length) {
			status = NVME_SC_INTERNAL;
			goto out_bio_put;
		}

		total_len += sg->length;
	}

	if (total_len != nvmet_rw_data_len(req)) {
		status = NVME_SC_INTERNAL | NVME_SC_DNR;
		goto out_bio_put;
	}

	submit_bio(bio);
	return;

out_bio_put:
	if (bio != &req->b.inline_bio)
		bio_put(bio);
	nvmet_req_complete(req, ret < 0 ? NVME_SC_INTERNAL : status);
}

u16 nvmet_bdev_zns_parse_io_cmd(struct nvmet_req *req)
{
	struct nvme_command *cmd = req->cmd;

	switch (cmd->common.opcode) {
	case nvme_cmd_zone_append:
		req->execute = nvmet_bdev_execute_zone_append;
		return 0;
	case nvme_cmd_zone_mgmt_recv:
		req->execute = nvmet_bdev_execute_zone_mgmt_recv;
		return 0;
	case nvme_cmd_zone_mgmt_send:
		req->execute = nvmet_bdev_execute_zone_mgmt_send;
		return 0;
	default:
		return nvmet_bdev_parse_io_cmd(req);
	}
}
