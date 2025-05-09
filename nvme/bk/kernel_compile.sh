#!/bin/bash

run()
{
	make -j $(nproc) 
	make -j $(nproc) modules 
	make -j $(nproc) modules_install 
	make -j $(nproc) install
	grub2-mkconfig -o "$(readlink -e /etc/grub2.cfg)"
}

time run
