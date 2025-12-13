// fsync_files.cc
// Author: Shane Bradley (sbradley at redhat.com)
// Description: This binary demostrates the use of fsync on 2 differnet mounted
// filesystems. This script writes integers to 2 files. It writes an integer to
// path1 the fsync() the data. If fsync() fails, then it errors out. If fsync()
// is successfully, then it does the same procedure on the second file.  The
// binary will only exit when loop is complete or the fsync errors out. Once the
// loop has written all the integers to both files, the files sizes in bytes of
// both files are compared. Returns 1 is files are identical and not 1 if there
// is error or not identical.
//
// NOTE: The parent directory will be fsync() after the file has had fsync()
// executed. fsync() on parent directory does have a performance penalty cause
// this will run a lot slower in my tests. Results will vary. Normally the parent
// directory would only by fsync() after writing has completed and not after
// every write.
//
// The maximum number of iterations in the loop ca n be set by changing the
// variable: MAXIMUM_INTEGER. Which is the last integer that will be written.
//
// Usage: ./fsync_files <path to mount point 1> <path to mount point 2>
//        ./fsync_files /mnt/gfs1vol1 /mnt/ext3vol1;
// Compile: g++ -o fsync_files fsync_files.cc

// TODO:
// - Add option parser for options: path1, path2, max_int, int_print,
//   fsync_parent_enabled.
// - Add fsync() on parent directory of both paths after last write.

#include <iostream>
#include <fstream>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <dirent.h>
using namespace std;

// The maximum integer to write to the file.
int MAXIMUM_INTEGER = 1000000;
//int MAXIMUM_INTEGER = 10000000;

// An integer that will be used for printing every X integer. For example, print
// integer after every 10000 complete.
int INTEGER_PRINT = 1000;

// IF this int is 1 then an fsync() on parent directory after ever write will be
// done.
int FSYNC_PARENT_AFTER_WRITE = 1;

u_int32_t get_file_size(const char *path_to_file) {
  if(access(path_to_file, F_OK ) != -1 ) {
    struct stat buf;
    if (stat(path_to_file, &buf) == 0 ) {
      return(buf.st_size);
    }
  }
  return(0);
}

int remove_file(const char* path_to_file) {
  if(access(path_to_file, F_OK ) != -1 ) {
    if (unlink(path_to_file) != 0) {
      return -1;
    }
  }
  return 0;
}

int main (int argc, char* argv[]) {
  if (argc != 3) {
    printf("Usage: %s <path to mount point 1> <path to mount point 2>\n", argv[0]);
    return -1;
  }

  // Create path1 and check that it is valid.
  string path1 = argv[1];
  if ((path1.length() > 0) && (path1[path1.length() - 1] == '/')) {
    path1 = path1.substr(0, path1.length() - 1);
  }
  if(access(path1.c_str(), F_OK ) == -1 ) {
    printf("ERROR: The path to mount point 1 does not exists or cannnot be accessed: %s.\n", path1.c_str());
    return -1;
  }
  DIR *dp1 = NULL;
  if (FSYNC_PARENT_AFTER_WRITE) {
    if((dp1 = opendir(path1.c_str())) == NULL) {
      printf("ERROR: Cannot open path 1 directory: %s\n", path1.c_str());
      return -1;
    }
  }
  path1 += "/fsync_test.txt";

  // Create path2 and check that it is valid.
  string path2 = argv[2];
  if ((path2.length() > 0) && (path2[path2.length() - 1] == '/')) {
    path2 = path2.substr(0, path2.length() - 1);
  }
  if(access(path2.c_str(), F_OK ) == -1 ) {
    printf("ERROR: The path to mount point 2 does not exists or cannnot be accessed: %s.\n", path2.c_str());
    return -1;
  }
  DIR *dp2 = NULL;
  if (FSYNC_PARENT_AFTER_WRITE) {
    if((dp2 = opendir(path2.c_str())) == NULL) {
      printf("ERROR: Cannot open path 2 directory: %s\n", path2.c_str());
      return -1;
    }
  }
  path2 += "/fsync_test.txt";

  // Remove any exisiting files.
  if (remove_file(path1.c_str()) != 0){
    printf("ERROR: The file could not be deleted: %s.\n", path1.c_str());
    return -1;
  }
  if (remove_file(path2.c_str()) != 0){
    printf("ERROR: The file could not be deleted: %s.\n", path2.c_str());
    return -1;
  }

  // Create the files that integers will be written to.
  printf("Creating the files that will have %d integers written to them.\n  File 1: %s\n  File 2: %s\n\n", MAXIMUM_INTEGER, path1.c_str(), path2.c_str());
  FILE * file1 = fopen(path1.c_str(), "w");
  int fd1 = fileno(file1);
  FILE * file2 = fopen(path2.c_str(), "w");
  int fd2 = fileno(file2);

  long unsigned i = 1;
  int rc = 0;
  // Write the integers to the files.
  while (i <= MAXIMUM_INTEGER) {
    fprintf(file1, "%lu\n", i);
    // fsync file1 data after writing it.
    rc = fsync(fd1);
    if (rc != 0) {
      printf("WARNING: Sync failed on file 1: %s.", path1.c_str());
      fclose(file1);
      fclose(file2);
      return -1;
    }
    // fsync the parent directory to make sure data is written to disk.
    if (dp1 != NULL) {
      int dpfd1 = dirfd(dp1);
      rc = fsync(dpfd1);
      if (rc != 0) {
        printf("ERROR: Sync failed on parent directory for the file : %s.\n", path1.c_str());
        return -1;
      }
    }
    // fsync file2 data after writing it.
    fprintf(file2, "%lu\n", i);
    // fsync file2 data.
    rc = fsync(fd2);
    if (rc != 0) {
      printf("WARNING: Sync failed on file 2: %s.", path2.c_str());
      fclose(file1);
      fclose(file2);
      return -1;
    }
    // fsync the parent directory to make sure data is written to disk.
    if (dp2 != NULL) {
      int dpfd2 = dirfd(dp2);
      rc = fsync(dpfd2);
      if (rc != 0) {
        printf("ERROR: Sync failed on parent directory for the file : %s.\n", path2.c_str());
        return -1;
      }
    }

    if ((i != 0) && (i%INTEGER_PRINT == 0)) {
      printf("The counter has wrote %d/%d lines.\n", i, MAXIMUM_INTEGER);
    }
    i += 1;
  }
  printf("The counter has wrote %d lines.\n\n", MAXIMUM_INTEGER);

  // Close the files and exit.
  fclose(file1);
  fclose(file2);
  if (dp1 != NULL) {
    closedir(dp1);
  }
  if (dp2 != NULL) {
    closedir(dp2);
  }

  // Compare the sizes of both the files.
  u_int32_t file1_size = get_file_size(path1.c_str());
  u_int32_t file2_size = get_file_size(path2.c_str());

  if (file1_size == file2_size) {
    printf("The files are identical in size.\n");

  }
  else {
    printf("The files are not identical in size.\n");
  }
  printf("  The size of the file is %s :  %u bytes.\n", path1.c_str(), file1_size);
  printf("  The size of the file is %s :  %u bytes.\n", path2.c_str(), file2_size);
  return file1_size == file2_size;
}

