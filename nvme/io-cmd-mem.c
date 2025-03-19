// SPDX-License-Identifier: GPL-2.0
/*
 * NVMe Over Fabrics Target Memorybacked command implementation.
 *
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#include <linux/blkdev.h>
#include <linux/blk-integrity.h>
#include <linux/memremap.h>
#include <linux/module.h>
#include "nvmet.h"

void nvmet_mem_set_limits(struct block_device *bdev, struct nvme_id_ns *id)
{
	/* Logical blocks per physical block, 0's based. */
	const __le16 lpp0b = to0based(bdev_physical_block_size(bdev) /
				      bdev_logical_block_size(bdev));

	/*
	 * For NVMe 1.2 and later, bit 1 indicates that the fields NAWUN,
	 * NAWUPF, and NACWU are defined for this namespace and should be
	 * used by the host for this namespace instead of the AWUN, AWUPF,
	 * and ACWU fields in the Identify Controller data structure. If
	 * any of these fields are zero that means that the corresponding
	 * field from the identify controller data structure should be used.
	 */
	id->nsfeat |= 1 << 1;
	id->nawun = lpp0b;
	id->nawupf = lpp0b;
	id->nacwu = lpp0b;

	/*
	 * Bit 4 indicates that the fields NPWG, NPWA, NPDG, NPDA, and
	 * NOWS are defined for this namespace and should be used by
	 * the host for I/O optimization.
	 */
	id->nsfeat |= 1 << 4;
	/* NPWG = Namespace Preferred Write Granularity. 0's based */
	id->npwg = lpp0b;
	/* NPWA = Namespace Preferred Write Alignment. 0's based */
	id->npwa = id->npwg;
	/* NPDG = Namespace Preferred Deallocate Granularity. 0's based */
	id->npdg = to0based(bdev_discard_granularity(bdev) /
			    bdev_logical_block_size(bdev));
	/* NPDG = Namespace Preferred Deallocate Alignment */
	id->npda = id->npdg;
	/* NOWS = Namespace Optimal Write Size */
	id->nows = to0based(bdev_io_opt(bdev) / bdev_logical_block_size(bdev));
}

void nvmet_bdev_ns_disable(struct nvmet_ns *ns)
{
	
}

int nvmet_bdev_ns_enable(struct nvmet_ns *ns)
{
	int ret;

	ns->size = (ns->gb * 1024 * 1024 * 1024);

	ns->pi_type = 0;
	ns->metadata_size = 0;

	return 0;
}

static void nvmet_bdev_execute_rw(struct nvmet_req *req)
{
	unsigned int sg_cnt = req->sg_cnt;
	struct scatterlist *sg;
	unsigned int total_len = nvmet_rw_data_len(req);
	sector_t sector;

	if (!nvmet_check_transfer_len(req, total_len))
		return;

	if (!req->sg_cnt) {
		nvmet_req_complete(req, 0);
		return;
	}

	if (req->cmd->rw.opcode == nvme_cmd_write)
		iter_flags = SG_MITER_TO_SG;
	else
		iter_flags = SG_MITER_FROM_SG;

	sector = nvmet_lba_to_sect(req->ns, req->cmd->rw.slba);

	for_each_sg(req->sg, sg, req->sg_cnt, i) {
		do_bvec(sg_page(sg), sg->length, sg->offset != sg->length)

		sector += sg->length >> 9;
		sg_cnt--;
	}
}

u16 nvmet_mem_parse_io_cmd(struct nvmet_req *req)
{
	switch (req->cmd->common.opcode) {
	case nvme_cmd_read:
	case nvme_cmd_write:
		req->execute = nvmet_mem_execute_rw;
	default:
		return nvmet_report_invalid_opcode(req);
	}
}
