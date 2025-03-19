nvme (nvme-6.4) # git log -1 
commit 5951887634ddeee1959a65f617f5962b84e4297a (HEAD -> nvme-6.4)
Author: Chaitanya Kulkarni <kch@nvidia.com>
Date:   Wed May 3 14:54:14 2023 -0700

    Iens's reoder
nvme (nvme-6.4) # pahole target/nvmet.ko |  grep "struct nvmet_ns {" -A 42 
struct nvmet_ns {
	struct percpu_ref          ref;                  /*     0    16 */
	struct block_device *      bdev;                 /*    16     8 */
	struct file *              file;                 /*    24     8 */
	bool                       readonly;             /*    32     1 */
	bool                       buffered_io;          /*    33     1 */
	bool                       enabled;              /*    34     1 */
	u8                         csi;                  /*    35     1 */
	u32                        nsid;                 /*    36     4 */
	u32                        blksize_shift;        /*    40     4 */
	u32                        anagrpid;             /*    44     4 */
	loff_t                     size;                 /*    48     8 */
	u8                         nguid[16];            /*    56    16 */
	/* --- cacheline 1 boundary (64 bytes) was 8 bytes ago --- */
	uuid_t                     uuid;                 /*    72    16 */
	struct nvmet_subsys *      subsys;               /*    88     8 */
	const char  *              device_path;          /*    96     8 */
	struct completion          disable_done;         /*   104    32 */
	/* --- cacheline 2 boundary (128 bytes) was 8 bytes ago --- */
	mempool_t *                bvec_pool;            /*   136     8 */
	struct pci_dev *           p2p_dev;              /*   144     8 */
	int                        use_p2pmem;           /*   152     4 */
	int                        pi_type;              /*   156     4 */
	int                        metadata_size;        /*   160     4 */

	/* XXX 4 bytes hole, try to pack */

	struct config_group        device_group;         /*   168   136 */
	/* --- cacheline 4 boundary (256 bytes) was 48 bytes ago --- */
	struct config_group        group;                /*   304   136 */

	/* size: 440, cachelines: 7, members: 23 */
	/* sum members: 436, holes: 1, sum holes: 4 */
	/* last cacheline: 56 bytes */
};
struct nvmet_subsys {
	enum nvme_subsys_type      type;                 /*     0     4 */

	/* XXX 4 bytes hole, try to pack */

	struct mutex               lock;                 /*     8    32 */
	struct kref                ref;                  /*    40     4 */

nvme (nvme-6.4) # vim nvmet-ns-
nvmet-ns-bdev-file-union.diff  nvmet-ns-union-wip.diff        
nvme (nvme-6.4) # vim p/nvmet-ns-
nvmet-ns-clear/ nvmet-ns-flags/ 
nvme (nvme-6.4) # vim p/nvmet-ns-flags/0001-nvmet-dynamically-allocate-nvmet_ns-nguid.patch 
nvme (nvme-6.4) # git diff 
diff --git a/drivers/nvme/target/admin-cmd.c b/drivers/nvme/target/admin-cmd.c
index 39cb570f833d..21129ad15320 100644
--- a/drivers/nvme/target/admin-cmd.c
+++ b/drivers/nvme/target/admin-cmd.c
@@ -551,7 +551,7 @@ static void nvmet_execute_identify_ns(struct nvmet_req *req)
        id->nmic = NVME_NS_NMIC_SHARED;
        id->anagrpid = cpu_to_le32(req->ns->anagrpid);
 
-       memcpy(&id->nguid, &req->ns->nguid, sizeof(id->nguid));
+       memcpy(&id->nguid, req->ns->nguid, sizeof(id->nguid));
 
        id->lbaf[0].ds = req->ns->blksize_shift;
 
@@ -646,10 +646,10 @@ static void nvmet_execute_identify_desclist(struct nvmet_req *req)
                if (status)
                        goto out;
        }
-       if (memchr_inv(req->ns->nguid, 0, sizeof(req->ns->nguid))) {
+       if (memchr_inv(req->ns->nguid, 0, NVME_NIDT_NGUID_LEN)) {
                status = nvmet_copy_ns_identifier(req, NVME_NIDT_NGUID,
                                                  NVME_NIDT_NGUID_LEN,
-                                                 &req->ns->nguid, &off);
+                                                 req->ns->nguid, &off);
                if (status)
                        goto out;
        }
diff --git a/drivers/nvme/target/core.c b/drivers/nvme/target/core.c
index f66ed13d7c11..cc95ba3c2835 100644
--- a/drivers/nvme/target/core.c
+++ b/drivers/nvme/target/core.c
@@ -665,6 +665,7 @@ void nvmet_ns_free(struct nvmet_ns *ns)
        up_write(&nvmet_ana_sem);
 
        kfree(ns->device_path);
+       kfree(ns->nguid);
        kfree(ns);
 }
 
@@ -676,6 +677,12 @@ struct nvmet_ns *nvmet_ns_alloc(struct nvmet_subsys *subsys, u32 nsid)
        if (!ns)
                return NULL;
 
+       ns->nguid = kzalloc(NVME_NIDT_NGUID_LEN, GFP_KERNEL);
+       if (!ns) {
+               kfree(ns);
+               return NULL;
+       }
+
        init_completion(&ns->disable_done);
 
        ns->nsid = nsid;
diff --git a/drivers/nvme/target/nvmet.h b/drivers/nvme/target/nvmet.h
index 790d7513e442..3bc91a4ee4ee 100644
--- a/drivers/nvme/target/nvmet.h
+++ b/drivers/nvme/target/nvmet.h
@@ -68,7 +68,7 @@ struct nvmet_ns {
        u32                     blksize_shift;
        u32                     anagrpid;
        loff_t                  size;
-       u8                      nguid[16];
+       u8                      *nguid;
        uuid_t                  uuid;
 
        struct nvmet_subsys     *subsys;
nvme (nvme-6.4) # makej M=drivers/nvme/target/
  MODPOST drivers/nvme/target/Module.symvers
nvme (nvme-6.4) # git diff 
diff --git a/drivers/nvme/target/admin-cmd.c b/drivers/nvme/target/admin-cmd.c
index 39cb570f833d..21129ad15320 100644
--- a/drivers/nvme/target/admin-cmd.c
+++ b/drivers/nvme/target/admin-cmd.c
@@ -551,7 +551,7 @@ static void nvmet_execute_identify_ns(struct nvmet_req *req)
        id->nmic = NVME_NS_NMIC_SHARED;
        id->anagrpid = cpu_to_le32(req->ns->anagrpid);
 
-       memcpy(&id->nguid, &req->ns->nguid, sizeof(id->nguid));
+       memcpy(&id->nguid, req->ns->nguid, sizeof(id->nguid));
 
        id->lbaf[0].ds = req->ns->blksize_shift;
 
@@ -646,10 +646,10 @@ static void nvmet_execute_identify_desclist(struct nvmet_req *req)
                if (status)
                        goto out;
        }
-       if (memchr_inv(req->ns->nguid, 0, sizeof(req->ns->nguid))) {
+       if (memchr_inv(req->ns->nguid, 0, NVME_NIDT_NGUID_LEN)) {
                status = nvmet_copy_ns_identifier(req, NVME_NIDT_NGUID,
                                                  NVME_NIDT_NGUID_LEN,
-                                                 &req->ns->nguid, &off);
+                                                 req->ns->nguid, &off);
                if (status)
                        goto out;
        }
diff --git a/drivers/nvme/target/core.c b/drivers/nvme/target/core.c
index f66ed13d7c11..cc95ba3c2835 100644
--- a/drivers/nvme/target/core.c
+++ b/drivers/nvme/target/core.c
@@ -665,6 +665,7 @@ void nvmet_ns_free(struct nvmet_ns *ns)
        up_write(&nvmet_ana_sem);
 
        kfree(ns->device_path);
+       kfree(ns->nguid);
        kfree(ns);
 }
 
@@ -676,6 +677,12 @@ struct nvmet_ns *nvmet_ns_alloc(struct nvmet_subsys *subsys, u32 nsid)
        if (!ns)
                return NULL;
 
+       ns->nguid = kzalloc(NVME_NIDT_NGUID_LEN, GFP_KERNEL);
+       if (!ns) {
+               kfree(ns);
+               return NULL;
+       }
+
        init_completion(&ns->disable_done);
 
        ns->nsid = nsid;
diff --git a/drivers/nvme/target/nvmet.h b/drivers/nvme/target/nvmet.h
index 790d7513e442..3bc91a4ee4ee 100644
--- a/drivers/nvme/target/nvmet.h
+++ b/drivers/nvme/target/nvmet.h
@@ -68,7 +68,7 @@ struct nvmet_ns {
        u32                     blksize_shift;
        u32                     anagrpid;
        loff_t                  size;
-       u8                      nguid[16];
+       u8                      *nguid;
        uuid_t                  uuid;
 
        struct nvmet_subsys     *subsys;
nvme (nvme-6.4) # pahole target/nvmet.ko |  grep "struct nvmet_ns {" -A 42 
struct nvmet_ns {
	struct percpu_ref          ref;                  /*     0    16 */
	struct block_device *      bdev;                 /*    16     8 */
	struct file *              file;                 /*    24     8 */
	bool                       readonly;             /*    32     1 */
	bool                       buffered_io;          /*    33     1 */
	bool                       enabled;              /*    34     1 */
	u8                         csi;                  /*    35     1 */
	u32                        nsid;                 /*    36     4 */
	u32                        blksize_shift;        /*    40     4 */
	u32                        anagrpid;             /*    44     4 */
	loff_t                     size;                 /*    48     8 */
	u8 *                       nguid;                /*    56     8 */
	/* --- cacheline 1 boundary (64 bytes) --- */
	uuid_t                     uuid;                 /*    64    16 */
	struct nvmet_subsys *      subsys;               /*    80     8 */
	const char  *              device_path;          /*    88     8 */
	struct completion          disable_done;         /*    96    32 */
	/* --- cacheline 2 boundary (128 bytes) --- */
	mempool_t *                bvec_pool;            /*   128     8 */
	struct pci_dev *           p2p_dev;              /*   136     8 */
	int                        use_p2pmem;           /*   144     4 */
	int                        pi_type;              /*   148     4 */
	int                        metadata_size;        /*   152     4 */

	/* XXX 4 bytes hole, try to pack */

	struct config_group        device_group;         /*   160   136 */
	/* --- cacheline 4 boundary (256 bytes) was 40 bytes ago --- */
	struct config_group        group;                /*   296   136 */

	/* size: 432, cachelines: 7, members: 23 */
	/* sum members: 428, holes: 1, sum holes: 4 */
	/* last cacheline: 48 bytes */
};
struct nvmet_subsys {
	enum nvme_subsys_type      type;                 /*     0     4 */

	/* XXX 4 bytes hole, try to pack */

	struct mutex               lock;                 /*     8    32 */
	struct kref                ref;                  /*    40     4 */

nvme (nvme-6.4) # 

