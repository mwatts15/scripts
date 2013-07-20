#!/bin/bash
echo "Downloading $2 pages from $1"
url=`echo $1 | sed -e 's/\/$//'`
if [ ${url: -1} = "/" ]; then
    url=${url:0:-1}
fi
if [[ $2 =~ [0-9]* ]]; then
    pagenums=`seq 1 $2`
else
    if [[ $url =~ (/page/[0-9]*)$ ]]; then
        pagenums=$(echo $url | egrep -o "[0-9]*$")
        url=$(echo $url | sed -r "s%(.*)/page/[0-9]*$%\1%")
    else
        pagenums=1
    fi
fi
if [[ $url =~ (/page/[0-9]*)$ ]]; then
    pagenums=$(echo $url | egrep -o "[0-9]*$")
    $url=$(echo $url | sed -r "s%(.*)/page/[0-9]*$%\1%")
fi
if [ -d $3 ]; then
    cd ${3:-.}
else
    mkdir tumblrrip
    cd tumblrrip
fi
echo $url
echo $pagenums
pwd
for npage in ${pagenums:-1} ; do
    echo downloading page $url/page/$npage
    wget -O - $url/page/$npage | grep -o -e "http://[[:alnum:]/._-]*" | grep --no-group-separator -B 1 -e ".*jpg\$" | sort -u | wget -i -
done
