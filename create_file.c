#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/errno.h>

#define UNUSED          __attribute__ ((unused))
#define PATH_SIZE       100

int initialize(const char *dir)
{
	int ret;

	ret = mkdir(dir, 0775);
	if (ret && ret != -EEXIST) {
		perror("init fail - mkdir failed\n");
		goto err;
	}

	ret = chdir(dir);
	if (ret) {
		perror("init fail - chdir failed\n");
		rmdir(dir);
	}
err:
	return ret;
}

int cleanup(const char *dir)
{
	int ret;

	ret = chdir("..");
	if (ret) {
		perror("cleanup fail - chdir failed\n");
		goto err;
	}

	ret = rmdir(dir);
	if (ret)
		perror("cleanup fail - rmdir failed\n");

err:
	return ret;
}

int create_files(int nfiles)
{
	int i, fd;
	char fpath[PATH_SIZE];

	for (i = 0; i < nfiles; i++) {
		sprintf(fpath, "%d", i);
		fd = creat(fpath, 0555);
		if (fd < 0) {
			perror("creat file failed.\n");
			break;
		}
		close(fd);
	}
	return i;
}

// expect "directory path, nfiles
int main(int argc, char **argv)
{
	int nfiles, n_done, ret;

	/* parse the options */
	if (argc != 3) {
		fprintf(stderr, "options is wrong.\n");
		fprintf(stderr, "%s [nfiles]\n", argv[0]);
		exit(1);
	}

	nfiles = atoi(argv[2]);
	if (nfiles <= 0) {
		fprintf(stderr, "option nfiles is wrong.");
		exit(1);
	}

	/* initialize - create the test directory and change the current dir */
	ret = initialize(argv[1]);
	if (ret)
		exit(1);

	n_done = create_files(nfiles);
	if (n_done != nfiles) {
		cleanup(argv[1]);
		exit(1);
	}
	return 0;
}
