#!/bin/sh

dirlist=(/home/twock/pictures/co /home/twock/pictures/co/pco)
for d in ${dirlist[@]}; do
    echo IN $d
    find $d -maxdepth 1 -type d -atime +1 -printf "\t%f\n" -exec tar vcjf {} {}.tar.bz2 \; >> pack_dirs.log
#    ls -lu $files
done
