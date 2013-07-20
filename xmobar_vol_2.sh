#!/bin/sh

bars=$(amixer get $1 | awk -F'[]%[]' '/%/ {if ($7 == "off") { print "MM" } else { print $2 }}' | head -n 1)

bars=$((bars / 10))

case $bars in
  0)     bar='[-----]' ;;
  1|2)   bar='[=----]' ;;
  3|4)   bar='[==---]' ;;
  5|6)   bar='[===--]' ;;
  7|8)   bar='[====-]' ;;
  9|10)  bar='[=====]' ;;
  *)     bar='[--!--]' ;;
esac
echo $bar
