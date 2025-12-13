#!/bin/sh

report_dir="$(pwd)/reports";
function summary_to_console {
    if [ -d $1 ]; then
	cat $1/*-summary.txt  2>/dev/null;
    fi
}

function reports_to_console {
    if [ -d $1 ]; then
	cat $1/*-services.txt 2>/dev/null;
	echo "";
	cat $1/*-clusternode_compare.txt 2>/dev/null;
	echo "";
	cat $1/*-evaluator.txt 2>/dev/null;
    fi
}

function footer_to_console {
    echo -e "\n-------------------------------------------------------------------------------------------------\n";
    echo -e "I will review the logs and comments next, please DO NOT make a public update based on information \nin this comment until my analysis is complete or stated otherwise.";
    echo -e "\n\n----------------------\nCluster Node ID Order:\n----------------------\n";
    grep -ie Hostname -ie "Node ID" $1/*-summary.txt | paste -d "\t"  - - | awk '{print $2," id: ",$5}';
    echo "PWD: $(pwd)";
    echo "";
    pdir=$(dirname $1);
    pdir=$(dirname $pdir)
    for ereport in $pdir/*; do 
	bname=$(basename $ereport);
	if [[ ! $bname == reports ]]; then
	    echo $ereport;
	fi
    done;
}

# Main
# Print main summary.
if [ -d $report_dir/clusterha2 ]; then
    summary_to_console $report_dir/clusterha2;
elif [ -d $report_dir/clusterha ]; then
    summary_to_console $report_dir/clusterha;
fi

# Print all other reports
if [ -d $report_dir/clusterha ]; then
    reports_to_console $report_dir/clusterha;
fi

# Print footer
if [ -d $report_dir/clusterha2 ]; then
    footer_to_console $report_dir/clusterha2;
elif [ -d $report_dir/clusterha ]; then
    footer_to_console $report_dir/clusterha;
fi
exit;
