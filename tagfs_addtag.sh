#!/bin/bash

if [ ! -e "#LISTEN#" ] ; then
    zenity --error --text="Can only tag files in a mounted TagFS"
    exit;
fi

name=$1
tname=`zenity --entry --text "Tag name:" --title "Tag Name"`
value=`zenity --entry --text "Tag value:" --title "Tag Value"`

addtags $name $tname:$value
