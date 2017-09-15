#!/bin/bash
# download glider data (detections and tracklines), then process using R script

# Select app directory
DESTDIR=/srv/shiny-server/right_whale_map # server
#DESTDIR=/Users/hansenjohnson/Projects/interactive_map # local

# OTN URL (do not change)
OTN=http://gliders.oceantrack.org/ge

# initiate array
declare -A URL

# assign paths to detection data for each glider
URL=(
	[dal556]=http://dcs.whoi.edu/dal0617_dal556/dal556_html/ptracks/manual_analysis.csv
	[otn200]=http://dcs.whoi.edu/dal0817/dal0817_otn200_html/ptracks/manual_analysis.csv
	#[bond]=http://dcs.whoi.edu/dal0617_bond/bond_html/ptracks/manual_analysis.csv
)

# download data
for i in "${!URL[@]}"; do   	
	
	# define data directory
	DATADIR=${DESTDIR}/data_${i}

	# make data directory
	mkdir -p ${DATADIR}

	# download glider tracklines
	wget -q -N ${OTN}/${i}.kml -P ${DATADIR}

	# download glider detections
	wget -q -N ${URL[$i]} -P ${DATADIR}
		
done

# process data
( cd ${DESTDIR}; Rscript -e "source('proc_glider_data.R')" )
