#!/bin/sh
# Example fo sorting on just package name:
# ./split_package_name.sh rpminfo.txt | cut -d " " -f1 | sort
# Find duplicates on just package name:
# ./split_package_name.sh rpminfo.txt | cut -d " " -f1 | sort | uniq -d
if [ -z $1 ]; then
   echo "Usage: $0 <filename>"
   exit 1
fi
filename=$1;

split_pkgname_pipe() {  # split x-x-1.3-1.x -> x-x 1.3-1.x
  local line namever name ver rel
  while read line ; do
    namever="${line%-*}"
    rel="${line##*-}"
    if [ `expr match $rel '[0-9]'` = 0 ] ; then # rel is 'i386/any'...
      name="${namever%-*}"
      ver="${namever##*-}"
      namever="$name"
      rel="$ver-$rel"
    fi
    name="${namever%-*}"
    ver="${namever##*-}"
    echo "$name $ver-$rel";
  done
}

if [ -f $filename ]; then
    while read -r line
    do
	split_pkgname_pipe line;
    done < "$filename"
else
    echo "The file does not exist: $filename.";
    exit 1;
fi
exit
