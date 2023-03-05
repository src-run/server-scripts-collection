#!/usr/bin/env zsh

DATASETS=('pool/backup-twoface/bpool' 'pool/backup-twoface/bpool/BOOT' 'pool/backup-twoface/bpool/BOOT/ubuntu' 'pool/backup-twoface/rpool' 'pool/backup-twoface/rpool/ROOT' 'pool/backup-twoface/rpool/ROOT/ubuntu' 'pool/backup-twoface/rpool/home' 'pool/backup-twoface/rpool/home/rmf' 'pool/backup-twoface/rpool/home/root' 'pool/backup-twoface/rpool/opt' 'pool/backup-twoface/rpool/srv' 'pool/backup-twoface/rpool/usr' 'pool/backup-twoface/rpool/usr/local' 'pool/backup-twoface/rpool/var' 'pool/backup-twoface/rpool/var/cache' 'pool/backup-twoface/rpool/var/lib' 'pool/backup-twoface/rpool/var/lib/docker' 'pool/backup-twoface/rpool/var/lib/nfs' 'pool/backup-twoface/rpool/var/lib/pms' 'pool/backup-twoface/rpool/var/log' 'pool/backup-twoface/rpool/var/spool' 'pool/backup-twoface/rpool/var/tmp')
DATAROOT='pool/backup-twoface/'
#DATASETS=('tank/sends/bpool' 'tank/sends/bpool/BOOT' 'tank/sends/bpool/BOOT/ubuntu' 'tank/sends/rpool' 'tank/sends/rpool/ROOT' 'tank/sends/rpool/ROOT/ubuntu' 'tank/sends/rpool/home' 'tank/sends/rpool/home/rmf'
#'tank/sends/rpool/home/root' 'tank/sends/rpool/opt' 'tank/sends/rpool/srv' 'tank/sends/rpool/usr' 'tank/sends/rpool/usr/local' 'tank/sends/rpool/var' 'tank/sends/rpool/var/cache' 'tank/sends/rpool/var/lib' 'tank/sends/rpool/var/lib/docker' 'tank/sends/rpool/var/lib/nfs' 'tank/sends/rpool/var/lib/pms' 'tank/sends/rpool/var/log' 'tank/sends/rpool/var/spool' 'tank/sends/rpool/var/tmp')
#tDATAROOT=''

for d in ${(v)DATASETS};do
	sudo zfs get all "${d}" | grep mount
	sudo zfs set canmount=off "${d}"
#	sudo zfs set mountpoint="/${DATAROOT}${d}" "${d}"
	sudo zfs get all "${d}" | grep mount
	printf '=======================\n'
	read
done
