#!/bin/bash

. ./CONFIG

__error()
{
	echo $1
	exit 1
}

[ ! -d "$TEST_DIR" ] && __error "please set a valid TEST_DIR in config, create test dir firstly"
[ -z $THREAD_NR ] && __error "please set a numeric THREAD_NR"
[ -z $NUMBER_TEST ] && __error "please set a valid NUMBER_TEST"
[ ! -b $TEST_DEV ] && __error "please set a valid TEST_DEV"
[ -z $MDTEST ] && __error "please set valid path for MDTEST"
[ ! -f $MDTEST ] && __error "please set valid path for MDTEST"
[ ! -f "./create_file" ] && __error "please run make firstly"

# $1 this is inode number
function refill_inodes()
{
	filled_number=$1
	directory_index=0
	while [ $filled_number -gt 0 ]
	do
		create_files=0
		# every directory, we filled 50W a file
		if [ $filled_number -gt 500000 ];then
			create_files=500000
		else
			create_files=$filled_number
		fi

		# using create_file.c is much faster rather than touch, this could
		# speed up test time a lot.
		./create_file $TEST_DIR/filled_inodes_dir_""$directory_index/$i $create_files

		let filled_number=$(($filled_number-$create_files))
		((directory_index++))
	done
	
}

function remount_fs()
{
	umount $TEST_DIR >&/dev/null
	mount -t $FSTYPE $TEST_DEV $TEST_DIR || __error "mount.ldiskfs failed"
}

function test_setup()
{
	umount $TEST_DEV >&/dev/null
	if [ $FSTYPE = "ldiskfs" ];then
		mkfs.lustre --fsname lustre --mdt --reformat --mgsnode=172.16.102.129@tcp \
		$TEST_DEV >&/dev/null || __error "mkfs.lustre failed"
	elif [ $FSTYPE = "ext4" ];then
		mkfs.ext4 -F $TEST_DEV >&/dev/null || __error "Ext4 mkfs failed"
	fi
}

function inode_ratio_test()
{
	factor=10
	test_setup
	# get total inode numbers
	total_inodes=`dumpe2fs $TEST_DEV -h 2> /dev/null | grep "Free inodes" | awk '{print $3}'`
	increment=$(($total_inodes/10))
	echo $total_inodes
	this_number_test=$(($increment/$(($THREAD_NR*$NUMBER_TEST*2))))

	cnt=0
	while [ $cnt -lt 9 ]
	do
		let filled_number=$(($increment * $cnt))
		remount_fs
		echo $filled_number
		#refill_inodes $filled_number

		mkdir $TEST_DIR/mdtest""$cnt
		echo "Mdtest with used inode: $(($cnt * 10))%:"
		mpirun --allow-run-as-root  -np $THREAD_NR $MDTEST -d $TEST_DIR/mdtest""$cnt -n $this_number_test -C -i $NUMBER_TEST || exit 1
		((cnt++))
	done
}
inode_ratio_test
