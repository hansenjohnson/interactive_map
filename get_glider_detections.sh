#!/bin/bash
# download glider detection files

# NOTE - this script makes use of associative arrays, 
# which are only available in bash --version >=4.0

# Choose destination of glider files
DESTDIR=/srv/shiny-server/right_whale_map # server
#DESTDIR=/Users/hansenjohnson/Projects/interactive_map # local

# initiate array
declare -A URL

# assign paths to data for each glider
URL=(
	[dal556]=http://dcs.whoi.edu/dal0617_dal556/dal556_html/ptracks/manual_analysis.csv
	[otn200]=http://dcs.whoi.edu/dal0817/dal0817_otn200_html/ptracks/manual_analysis.csv
	[bond]=http://dcs.whoi.edu/dal0617_bond/bond_html/ptracks/manual_analysis.csv
)

# download data
for i in "${!URL[@]}"; do   	
	wget -q ${URL[$i]} -O ${DESTDIR}/${i}_manual_analysis.csv
	if [ 0 -ne $? ] ; then { echo "Failed downloading data from ${i}"; exit 1; }; fi
done

# run R script to process these data
( cd ${DESTDIR}; Rscript -e "source('proc_glider_detections.R')" )