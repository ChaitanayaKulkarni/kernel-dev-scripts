
#define _GNU_SOURCE

#include <endian.h>
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/prctl.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <linux/capability.h>

uint64_t r[1] = {0xffffffffffffffff};

void loop(void)
{
  intptr_t res = 0;
  res = syscall(__NR_socket, /*domain=*/2ul, /*type=*/1ul, /*proto=*/0);
  if (res != -1)
    r[0] = res;
  *(uint16_t*)0x20000100 = 2;
  *(uint16_t*)0x20000102 = htobe16(0x1144);
  *(uint32_t*)0x20000104 = htobe32(0x7f000001);
  syscall(__NR_connect, /*fd=*/r[0], /*addr=*/0x20000100ul, /*addrlen=*/0x10ul);
  *(uint8_t*)0x200001c0 = 0;
  *(uint8_t*)0x200001c1 = 0;
  *(uint8_t*)0x200001c2 = 0x80;
  *(uint8_t*)0x200001c3 = 0;
  *(uint32_t*)0x200001c4 = 0x80;
  *(uint16_t*)0x200001c8 = 0;
  *(uint8_t*)0x200001ca = 0;
  *(uint8_t*)0x200001cb = 0;
  *(uint32_t*)0x200001cc = 0;
  memcpy((void*)0x200001d0,
         "\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf"
         "\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf"
         "\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35"
         "\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86"
         "\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf"
         "\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf"
         "\\x35\\x86\\xcf\\xbf\\x35\\x86\\xcf\\xbf\\x35\\x86",
         112);
  syscall(__NR_sendto, /*fd=*/r[0], /*pdu=*/0x200001c0ul, /*len=*/0x80ul,
          /*f=*/0ul, /*addr=*/0ul, /*addrlen=*/0ul);
  *(uint8_t*)0x20000080 = 6;
  *(uint8_t*)0x20000081 = 3;
  *(uint8_t*)0x20000082 = 0x18;
  *(uint8_t*)0x20000083 = 0x1c;
  *(uint32_t*)0x20000084 = 2;
  *(uint16_t*)0x20000088 = 0x5d;
  *(uint16_t*)0x2000008a = 3;
  *(uint32_t*)0x2000008c = 0;
  *(uint32_t*)0x20000090 = 7;
  memcpy((void*)0x20000094, "\\x83\\x9e\\x4f\\x1a", 4);
  syscall(__NR_sendto, /*fd=*/r[0], /*pdu=*/0x20000080ul, /*len=*/0x80ul,
          /*f=*/0ul, /*addr=*/0ul, /*addrlen=*/0ul);
}
int main(void)
{
  syscall(__NR_mmap, /*addr=*/0x1ffff000ul, /*len=*/0x1000ul, /*prot=*/0ul,
          /*flags=*/0x32ul, /*fd=*/-1, /*offset=*/0ul);
  syscall(__NR_mmap, /*addr=*/0x20000000ul, /*len=*/0x1000000ul, /*prot=*/7ul,
          /*flags=*/0x32ul, /*fd=*/-1, /*offset=*/0ul);
  syscall(__NR_mmap, /*addr=*/0x21000000ul, /*len=*/0x1000ul, /*prot=*/0ul,
          /*flags=*/0x32ul, /*fd=*/-1, /*offset=*/0ul);
  loop();
  return 0;
}
