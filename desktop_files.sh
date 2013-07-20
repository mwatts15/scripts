#!/bin/bash

echo '<openbox_pipe_menu>'

for file in `ls ~/desktop/* -d --group-directories-first` 
do
if [ $file ] ; then
    echo '<item label="'`basename ${file}`'">'
    echo '<action name="Execute"><execute>'
    echo "gnome-open ${file}"
    echo '</execute></action>'
    echo '</item>'
fi
done

echo '</openbox_pipe_menu>'
