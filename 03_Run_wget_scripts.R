# 3: Download of CMIP6 data
#   Written by Dave Schoeman (david.schoeman@gmail.com)
    # March/April 2022; modified December 2022

# wget files are downloaded from ESGF

# Packages ---------------------------------------------------------------------

  source("Helpers.R")


# Folders and other parameters to set ------------------------------------------
  data_path <- make_folder("/Volumes/Mega_Disk/Mangroves/CMIP_Raw")
  wget_path <- "/Users/davidschoeman/wgets"
  pth <- getwd()
  w <- 15 # Number of workers (parallel processes) to use


# Purrr the files via terminal -------------------------------------------------

  wget_files <-  function(script) {
      setwd(data_path)
      system(paste0("bash ", script, " -s")) # Change the path to where you want the data stored, then run wget from there
      setwd(pth)
      }

  files <- dir(wget_path, pattern = "wget", full.names = TRUE)

  plan(multisession, workers = w)
    future_walk(files, wget_files)
  plan(sequential)

# Goto 4_Merge_and_trim_CMIP_netCDFs.R

