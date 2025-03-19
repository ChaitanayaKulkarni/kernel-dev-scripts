// SPDX-License-Identifier: GPL-2.0
/*
 * NVMe I/O command implementation for NO-OP Backend.
 * Copyright (c) 2023 NVIDIA.
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#include <linux/blkdev.h>
#include <linux/module.h>
#include "nvmet.h"

int nvmet_noop_ns_enable(struct nvmet_ns *ns)
{
	memset(&ns->size, 0xff, sizeof(ns->size));
	ns->blksize_shift = blksize_bits(PAGE_SIZE);

	ns->pi_type = 0;
	ns->metadata_size = 0;

	return 0;
}

static void nvmet_noop_execute_rw(struct nvmet_req *req)
{
	unsigned int total_len = nvmet_rw_data_len(req) + req->metadata_len;

	if (!nvmet_check_transfer_len(req, total_len))
		return;

	nvmet_req_complete(req, NVME_SC_SUCCESS);
}

u16 nvmet_noop_parse_io_cmd(struct nvmet_req *req)
{
	switch (req->cmd->common.opcode) {
	case nvme_cmd_read:
	case nvme_cmd_write:
	case nvme_cmd_flush:
	case nvme_cmd_dsm:
	case nvme_cmd_write_zeroes:
		req->execute = nvmet_noop_execute;
		return 0;
	default:
		return nvmet_report_invalid_opcode(req);
	}
}
