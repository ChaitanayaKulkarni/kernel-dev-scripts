#include <linux/blkdev.h>
#include <linux/module.h>
#include <linux/sched/signal.h>
#include <linux/kthread.h>
#include <linux/list.h>
#include <linux/random.h>
#include <linux/delay.h>
#include <uapi/linux/sched/types.h>

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/blkdev.h>
#include <linux/slab.h>
#include <linux/gfp.h>

static char *dev_path = "/dev/nvme1n1";

module_param(dev_path, charp, 0000);
MODULE_PARM_DESC(dev_path, "Device pathname");

static const char *type_text[] = {
        "RESERVED",
        "CONVENTIONAL",
        "SEQ_WRITE_REQUIRED",
        "SEQ_WRITE_PREFERRED",
};

static const char *condition_str[] = {
        "nw", /* Not write pointer */
        "em", /* Empty */
        "oi", /* Implicitly opened */
        "oe", /* Explicitly opened */
        "cl", /* Closed */
        "x5", "x6", "x7", "x8", "x9", "xA", "xB", "xC", /* xN: reserved */
        "ro", /* Read only */
        "fu", /* Full */
        "of"  /* Offline */
};

static int test_report_zones_cb(struct blk_zone *zone, unsigned int idx, void *data)
{
	pr_info("start: 0x%09llx, len 0x%06llx"
		 ", cap 0x%06llx, wptr 0x%06llx"
		 " reset:%u non-seq:%u, zcond:%2u(%s) [type: %u(%s)]\n",
		 zone->start, zone->len, zone->capacity, (zone->type == 0x1) ? 0 : zone->wp - zone->start,
		 zone->reset, zone->non_seq,
		 zone->cond, condition_str[zone->cond & (ARRAY_SIZE(condition_str) - 1)],
		 zone->type, type_text[zone->type]);
	return 0;
}

static int report_zones(struct block_device *bdev)
{
	struct blk_zone *zones;
	int ret;

	zones = kvcalloc(blkdev_nr_zones(bdev->bd_disk),
			sizeof(struct blk_zone), GFP_KERNEL);
	if (!zones)
		return -ENOMEM;

	/* Get zones information from the device */
	ret = blkdev_report_zones(bdev, 0, BLK_ALL_ZONES, test_report_zones_cb,
				  NULL);
	if (ret < 0)
		return ret;
	kvfree(zones);

	return 0;
}


int test_zone_mgmt(struct block_device *bdev, unsigned int op)
{
	unsigned long zone_sect = blk_queue_zone_sectors(bdev->bd_disk->queue);
	unsigned long ranges = blk_queue_nr_zones(bdev->bd_disk->queue);
	unsigned long sect = get_capacity(bdev->bd_disk) - zone_sect;
	gfp_t gfp = GFP_KERNEL;
	int i, err;

	for (i = 0; i < ranges; sect -= zone_sect, i++) {
		pr_info("test: %s                   sector 0x%lx nr_sect 0x%lx\n",
				blk_op_str(op), sect, zone_sect);
		err = blkdev_zone_mgmt(bdev, op, sect, zone_sect, gfp);
		if (err)
			goto err;

		pr_info("Drive Zone Status after %s", blk_op_str(op));
	}

	report_zones(bdev);
	pr_info("----------------------------------------------------------\n");
err:
	return err;
}

int __init init_module(void)
{
	static fmode_t mode = FMODE_READ | FMODE_WRITE;
	struct block_device *bdev;
	int err = 0;

	bdev = blkdev_get_by_path(dev_path, mode, NULL);
	if (IS_ERR(bdev)) {
		pr_err("failed to open block device %s: (%ld)\n",
				dev_path, PTR_ERR(bdev));
		printk(KERN_INFO "ERROR : blkdev_get_by_path failed\n");
		return PTR_ERR(bdev);
	}

	if (!bdev_is_zoned(bdev)) {
		pr_err("Zoned Device expected\n");
		goto out;
	}

	err = blkdev_zone_mgmt(bdev, REQ_OP_ZONE_RESET, 0,
			       get_capacity(bdev->bd_disk), GFP_KERNEL);
#if 0
	pr_info("############### %s REQ_OP_ZONE_OPEN ############################\n",
			dev_path);
	err = test_zone_mgmt(bdev, REQ_OP_ZONE_OPEN);
	if (err)
		goto err;
	pr_info("############### %s REQ_OP_ZONE_CLOSE ###########################\n",
			dev_path);                                                   
	err = test_zone_mgmt(bdev, REQ_OP_ZONE_CLOSE);
	if (err)
		goto err;
	pr_info("############### %s REQ_OP_ZONE_FINISH ##########################\n",
			dev_path);                                                   
	err = test_zone_mgmt(bdev, REQ_OP_ZONE_FINISH);
	if (err)
		goto err;
	pr_info("################ %s REQ_OP_ZONE_RESET ##########################\n",
			dev_path);                                                    
	err = test_zone_mgmt(bdev, REQ_OP_ZONE_RESET);
	if (err)
		goto err;
#endif
	pr_info("################ %s REQ_OP_ZONE_RESET_ALL ######################\n",
			dev_path);                                                    

	err = blkdev_zone_mgmt(bdev, REQ_OP_ZONE_RESET, 0,
			       get_capacity(bdev->bd_disk), GFP_KERNEL);
	if (err)
		goto err;
out:
	blkdev_put(bdev, mode);
	return 0;

err:
	pr_info("ERROR %d\n", err);
	goto out;
}

void __exit cleanup_module(void)
{
       printk(KERN_INFO "Goodbye\n");
}
MODULE_LICENSE("GPL");
