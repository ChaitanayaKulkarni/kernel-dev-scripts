#!/bin/bash -x

run()
{
	file=/tmp/kernel_compile

	rm -fr ${file} 

	make -j $(nproc) #2>&1 >> ${file}
	make -j $(nproc) modules #2>&1 >> ${file}
	make -j $(nproc) modules_install #2>&1 >> ${file} 
	make -j $(nproc) install #2>&1 >> ${file}
	grub2-mkconfig -o "$(readlink -e /etc/grub2.cfg)"
	grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
}

time run
