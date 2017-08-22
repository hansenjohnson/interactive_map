# download glider files

# bond
wget http://gliders.oceantrack.org/ge/bond.kml -O /home/hansen/shiny-server/whale_map/bond_tracks.kml

# dal556
wget http://gliders.oceantrack.org/ge/otn200.kml -O /home/hansen/shiny-server/whale_map/otn200_tracks.kml

# otn200
wget http://gliders.oceantrack.org/ge/dal556.kml -O /home/hansen/shiny-server/whale_map/dal556_tracks.kml

# run R script to process these data
Rscript -e "source('/home/hansen/shiny-server/whale_map/proc_glider_tracks.R')"