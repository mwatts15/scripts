#!/bin/bash
# eigene öffentliche ip anzeigen

if [ x$1 = 'x-l' ] ;then
    hostname -I | sed -r 's/([^ ]+).*/\1/'
else
    wget http://checkip.dyndns.org/ --timeout=2 -q -O - |
    grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
fi
