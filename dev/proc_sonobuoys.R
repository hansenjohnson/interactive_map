# process sonobuoy positions

# user input --------------------------------------------------------------

sonobuoy_file = 'sonobuoys.rda'

# process -----------------------------------------------------------------

# read in data
sono = read.csv('sonobuoys.csv', header = T)

# set col names
colnames(sono) = c('date', 'lat', 'lon')

# fix date
sono$date = as.Date(sono$date, format = '%m/%d/%Y')

# save for use in the app
save(sono, file = sonobuoy_file)