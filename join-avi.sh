mkfifo intermediate1.mpg
mkfifo intermediate2.mpg
ffmpeg -i $1 -sameq -y intermediate1.mpg < /dev/null &
ffmpeg -i $2 -sameq -y intermediate2.mpg < /dev/null &
cat intermediate1.mpg intermediate2.mpg |\
ffmpeg -f mpeg -i - -sameq -vcodec mpeg4 -acodec aac output.avi

