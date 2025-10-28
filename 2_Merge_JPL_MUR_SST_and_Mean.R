# 2: Merge JPL MUR monthly SST netCDFs and compute the mean (for adjusting projected anomalies)
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # November 2024


# Packages ---------------------------------------------------------------------

  source("Helpers.R")


# Set up details ---------------------------------------------------------------

  input_folder <- "/Volumes/Mega_Disk/JPL_MUR_SST"
  output_folder <- make_folder("/Volumes/Mega_Disk/JPL_MUR_SST_Combo")


# Combine files ----------------------------------------------------------------

  files <- dir(input_folder, full.names = TRUE)
  yr1 <- first(files) %>%
    str_sub(-11, -4)
  yr2 <- last(files) %>%
    str_sub(-11, -4)
  out_file <- files[1] %>%
    str_replace(input_folder, output_folder) %>%
    str_replace(str_sub(., -20, -1), paste0(yr1, "-", yr2, ".nc"))
  cdo_code <- paste0("cdo -L -mergetime ", paste0(files, collapse = " "), " ", out_file)
    system(cdo_code)


# Get mean ---------------------------------------------------------------------

  yr_start <- 2003
  yr_end <- 2014
  f <- dir(output_folder, full.names = TRUE) %>%
      str_subset("_mean_", negate = TRUE)
  out_file <- f %>%
    str_replace("_analysed_", "_mean_") %>%
    str_replace(str_sub(., -20, -1), paste0(yr_start, "0101-", yr_end, "1231.nc"))
  cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Sea Surface Temperature' -chname,analysed_sst,tos -delete,month=2,day=29 -ydaymean ", "-selyear,", yr_start, "/", yr_end," ", f, " ", out_file)
  # cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Sea Surface Temperature' -chname,analysed_sst,tos -timmean ", "-selyear,", yr_start, "/", yr_end," ", f, " ", out_file)
    system(cdo_code)

# Goto 3_Run_wget_scripts.R