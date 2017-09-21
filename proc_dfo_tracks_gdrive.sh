#!/bin/bash
# download and process dfo plane trackline data using an R script

# Select app directory
DESTDIR=/srv/shiny-server/right_whale_map # server
#DESTDIR=/Users/hansenjohnson/Projects/interactive_map # local

# process data
( cd ${DESTDIR}; Rscript -e "source('proc_dfo_tracks_gdrive.R')" )
