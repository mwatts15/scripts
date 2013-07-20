#!/bin/zsh 
videos=(/tmp/Flash*)
video=true
if [ $videos[1] ] ; then
    while [ $1 ] ; do
        case $1 in
        '-v'|"--video")
            video=true;
            ;;
        '-a'|"--audio")
            video=false;
            ;;
         *)
            name=$1
            ;;
        esac
        shift
    done

    vid=$videos[1]
    while [ ! "`ls -s $vid`" = "$last_size" ] ; do
        last_size=`ls -s $vid`
        sleep 5
    done
    if [ ! $name ] ; then
       if [ ! $video ] ; then
            ffmpeg -i $vid -sameq -f flac `md5sum $vid | sed -e 's/ .*$//'`.flac
        else
            cp $vid `md5sum $vid | sed -e 's/ .*$//'`
        fi
     else       
        if [ ! $video ] ; then
            ffmpeg -i $vid -f flac $name.flac
        else
            cp $vid $name
        fi
    fi
    rm $vid
fi
exit 0
