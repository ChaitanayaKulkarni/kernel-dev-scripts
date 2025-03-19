#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/uio.h>

#define COUNT (10)
#define LEN (1024)
int main(void)
{
#if 0
        struct iovec iov[COUNT];
	char *p[COUNT];
        ssize_t nr;
        int fd, i;

        fd = open ("/dev/nvme1n1", O_WRONLY | O_CREAT | O_TRUNC);
        if (fd == -1) {
                perror ("open");
                return 1;
        }

        /* fill out three iovec structures */
        for (i = 0; i < COUNT; i++) {
		p[i] = malloc(LEN);

                iov[i].iov_base = p[i] + 128;
                iov[i].iov_len = LEN - 128;
        }
        /* with a single call, write them all out */
        nr = writev (fd, iov, COUNT);
        if (nr == .1) {
                perror ("writev");
                return 1;
        }
        printf ("wrote %d bytes\n", nr);

        for (i = 0; i < COUNT; i++)
		free(p[i]);

        if (close(fd)) {
                perror ("close");
                return 1;
        }

#endif
	0 || printf("hi 0\n");
	1 || printf("hi 1\n");

	0 && printf("hi 0\n");
	1 && printf("hi 1\n");
        return 0;
}
