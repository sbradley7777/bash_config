#!/bin/bash
if [ -z $1 ]; then
    echo "`basename $0`";
    echo "Usage: rpm-source <source rpm file>"
    echo "Usage: rpm-source <path to url for file>"
    echo "`basename $0` ~/conga-0.12.src.rpm";
    echo "`basename $0` http://example.com/conga-0.12.src.rpm";
    exit 1
fi

echo "Installing the rpm: $1"
name=`rpm -qp --qf %{NAME} $1`
vers=`rpm -qp --qf %{VERSION} $1`
spec=`rpm -qlp $1 | grep ".spec$"`
mkdir -p ~/redhat/$name/$vers/{RPMS,SRPMS,SPECS,SOURCES,BUILD}
rpm -ivh $1
cd ~/redhat/$name/$vers/
rpmbuild -bp --target=x86_64 SPECS/$spec  --nodeps

rm -rf ~/redhat/%\{name\}/
rm -rf ~/redhat/BUILD ~/redhat/RPMS  ~/redhat/SRPMS ~/redhat/SPECS ~/redhat/SOURCES
exit
