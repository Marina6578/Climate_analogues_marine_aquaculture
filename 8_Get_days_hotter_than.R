# 8: Sum days per year hotter than a given temperature
  # Written by Dave Schoeman (david.schoeman@gmail.com)
      # November 2024


# Startup ----------------------------------------------------------------------

  source("Helpers.R")


# Set up details ---------------------------------------------------------------

  w <- 8
  input_folder <- "/Volumes/Mega_Disk/TAS_JPL_Bias_Corrected"
  output_folder <- make_folder("/Volumes/Mega_Disk/Annual_days_above_17")


# Write functions and deploy ---------------------------------------------------

  files <- dir(input_folder, full.names = TRUE)

  get_days1 <- function(f) {
    out_file <- f %>%
      str_replace(input_folder, output_folder) %>%
      str_replace("tos_Oday_", "daysover_17C_")
    cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days warmer than 17C' -chname,tos,days -yearsum -gec,17 ", f, " ", out_file)
      system(cdo_code)
    }

  plan(multisession, workers = w)
    future_walk(files, get_days1)
  plan(sequential)

  input_folder <- "/Volumes/Mega_Disk/TAS_JPL_Bias_Corrected"
  output_folder <- make_folder("/Volumes/Mega_Disk/Annual_days_above_21_5")

  files <- dir(input_folder, full.names = TRUE)

  get_days2 <- function(f) {
    out_file <- f %>%
      str_replace(input_folder, output_folder) %>%
      str_replace("tos_Oday_", "daysover_21.5C_")
    cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days warmer than 21.5C' -chname,tos,days -yearsum -gec,21.5 ", f, " ", out_file)
    system(cdo_code)
    }

  plan(multisession, workers = w)
    future_walk(files, get_days2)
  plan(sequential)


# Do the same for JPL MUR (observational) data ---------------------------------

  xmin <- 141.0
  ymin <- -47.25
  xmax <- 153.0
  ymax <- -39.0

  # Make obs spatRaster
    MUR_file <- "/Volumes/Stripe_Raid/JPL_MUR_SST_Combo/jplMUR41_analysed_sst_20020831-20241031.nc"
    obs_out <- MUR_file %>%
      str_replace("_20020831-20241031", "_TAS_20110101-20201231")
    cdo_code <- paste0("cdo -L -selyear,2011/2020 -sellonlatbox,", xmin, ",", xmax, ",", ymin, ",", ymax," ", MUR_file, " ", obs_out)
    system(cdo_code)

  # Restate the functions, with slight modifications to account for file-naming conventions
    get_days1 <- function(f) {
      out_file <- f %>%
        str_replace(input_folder, output_folder) %>%
        str_replace("analysed_sst_", "daysover_17C_")
      cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days warmer than 17C' -chname,tos,days -yearsum -gec,17 ", f, " ", out_file)
      system(cdo_code)
      }

    get_days2 <- function(f) {
      out_file <- f %>%
        str_replace(input_folder, output_folder) %>%
        str_replace("analysed_sst_", "daysover_21.5C_")
      cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days warmer than 21.5C' -chname,tos,days -yearsum -gec,21.5 ", f, " ", out_file)
      system(cdo_code)
      }

  # Deploy the functions
    input_folder <- dirname(MUR_file)
    output_folder <- make_folder("/Volumes/Mega_Disk/Annual_days_above_17")
      walk(obs_out, get_days1)
    output_folder <- make_folder("/Volumes/Mega_Disk/Annual_days_above_21_5")
      walk(obs_out, get_days2)


# Extra temps requested --------------------------------------------------------
  # As per email on 29 November 2024
      # ...among the historical data (NASA), but I think it would be useful to know :
      # Number of days (if there are any) below:
      #   2 degrees Celsius (lower limit for Salmon)-just in case
      # 3 degrees Celsius (lower limit for amberjacks )
      # 7.5 degrees Celsius (lower limit for abalone/mussels)      #
      # Days over 26.8 Celsius. (upper value for amberjack and abalone in general)

  # Generic function for temp above "temp"
    get_days_over <- function(f, temp) {
      out_file <- f %>%
        str_replace(input_folder, output_folder) %>%
        str_replace("analysed_sst_", paste0("daysover_", temp %>% str_replace('\\.', '_'), "C_"))
      cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days warmer than ", temp, "' -chname,tos,days -yearsum -gec,", temp, " ", f, " ", out_file)
      system(cdo_code)
    }

# Generic function for temp below "temp"
      get_days_under <- function(f, temp) {
        out_file <- f %>%
          str_replace(input_folder, output_folder) %>%
          str_replace("analysed_sst_", paste0("daysunder_", temp %>% str_replace('\\.', '_'), "C_"))
        cdo_code <- paste0("cdo -L -setattribute,tos@long_name='Days cooler than ", temp, "' -chname,tos,days -yearsum -lec,", temp, " ", f, " ", out_file)
        system(cdo_code)
      }

  # Deploy functions
    input_folder <- "/Volumes/Stripe_Raid/JPL_MUR_SST_Combo"
    output_folder <- make_folder("/Volumes/Stripe_Raid/New_temps")

    get_days_under(MUR_file, 2)
    get_days_under(MUR_file, 3)
    get_days_under(MUR_file, 7.5)
    get_days_over(MUR_file, 26.8)

    input_folder <- "/Volumes/Stripe_Raid/TAS_JPL_Bias_Corrected"
    output_folder <- make_folder("/Volumes/Stripe_Raid/New_temps")
    files <- dir("/Volumes/Stripe_Raid/TAS_JPL_Bias_Corrected", full.names = TRUE)
    get_f <- function(f) {
      get_days_over(f, 26.8)
    }

    plan(multisession, workers = w)
      future_walk(files, get_f)
    plan(sequential)
