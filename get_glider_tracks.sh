#!/bin/sh
# download glider files

DESTDIR=/srv/shiny-server/right_whale_map # server
# DESTDIR=/Users/hansenjohnson/Projects/interactive_map # local
URL=http://gliders.oceantrack.org/ge

for product in bond dal556 otn200
do
   wget -q ${URL}/${product}.kml -O ${DESTDIR}/${product}_tracks.kml
   if [ 0 -ne $? ] ; then { echo "Failed downloading ${product}"; exit 1; }; fi
done

# run R script to process these data
( cd ${DESTDIR}; Rscript -e "source('proc_glider_tracks.R')" )
