#!/bin/sh


function usage() {
    echo "Please give a man section number.";
}
man_section=$1;
if [ -z $man_section ]; then
    usage;
    exit 1;
fi
if [[ $man_section == [1-8] || "$man_section" == "L" || "$man_section" == "M" ]]; then
    path_to_output_dir=/tmp/man/man$(basename $man_section);
    if [ ! -d $path_to_output_dir ]; then
        mkdir -p $path_to_output_dir;
    fi
    path_to_man_section=/usr/share/man/man$man_section;
    if [ -d $path_to_man_section ]; then
        cd $path_to_man_section;
        for i in `find -name '*.gz'`; do
            basename_html_file=${i%.*};
            basename_html_file=$(basename $basename_html_file);
            echo $path_to_output_dir/$basename_html_file.html
            zcat $i | groff -mandoc -Thtml > $path_to_output_dir/$basename_html_file.html;
        done
    else
        echo "ERROR: The man section $man_section did not exist.";
        exit 1;
    fi
else
    echo "ERROR: $man_section is not an integer 1 - 8.";
    usage;
    exit 1;
fi
exit;
