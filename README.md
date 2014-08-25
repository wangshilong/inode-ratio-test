inode-ratio-test
================

setup:

1. run command 'make'
2. edit CONFIG, set proper arg

Example:
TEST_DIR=/mnt/test
THREAD_NR=100
NUMBER_TEST=3
TEST_DEV=/dev/sdf
MDTEST=./mdtest
FSTYPE=ldiskfs

Here NUMBER_TEST is times that mdtest will run.
MDTEST is pathname that where executable mdtest locates.
FSTYPE now supports ldiskfs and ext4

Inode ratio test for ldiskfs with mdtest
