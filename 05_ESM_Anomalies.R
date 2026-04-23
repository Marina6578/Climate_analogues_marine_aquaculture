# 5: Make ESM daily anomaly projections using the period 2003—2014 (i.e., corresponding JPL MUR years)
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # November 2024


# Startup ----------------------------------------------------------------------

  source("Helpers.R")


# Set up details ---------------------------------------------------------------

  xmin <- 140.0
  ymin <- -57.0
  xmax <- 162.0
  ymax <- -36.0
  input_folder <- "/Volumes/Stripe_Raid/CMIP_merged"
  output_folder <- make_folder("/Volumes/Mega_Disk/TAS_std_anomalies")
  w <- detectCores()-10  # Number of workers (parallel processes) to use
  hist_year_start <- 2003 # To match JPL MUR
  hist_year_end <- 2014 # End of CMIP6 historical
  ssp_year_start <- 2015 # Standard for CMIP6
  ssp_year_end <- 2100 # Most models end here...alter if you are working with longer series


# Check and fix calendar and compute anomalies ---------------------------------

  files <- dir(input_folder, full.names = TRUE)

  get_anom <- function(f) {
    bits <- get_CMIP6_bits(f)
    frq <- bits$Frequency
    crop_file <- f %>%
      str_replace(bits$Frequency, "TAS")
    cdo_code <- paste0("cdo -L -sellonlatbox,", xmin, ",", xmax, ",", ymin, ",", ymax," ", f, " ", crop_file)
      system(cdo_code)
    mn_file <- f %>%
      str_replace(bits$Frequency, "Mean")
    # cdo_code <- paste0("cdo -L -timmean -selyear,", hist_year_start, "/", hist_year_end," ", crop_file, " ", mn_file) #***
    cdo_code <- paste0("cdo -L -ydaymean -selyear,", hist_year_start, "/", hist_year_end," ", crop_file, " ", mn_file)
      system(cdo_code)
    out_file <- f %>%
      str_replace(input_folder, output_folder) %>%
      str_replace(bits$Grid, "anomaly")
    n <- nc_open(f)	%>%
      ncvar_get(., "time") %>%
      length(.) %% 365 # Modulo...returns zero if number of days divides by 365 without remainder
      if(n != 0) {
        cdo_code <- paste0("cdo -L -setcalendar,365_day -delete,month=2,day=29 -ydaysub ", crop_file, " ", mn_file, " ", out_file)
        system(cdo_code)
        } else {
          cdo_code <- paste0("cdo -L -setcalendar,365_day -ydaysub ", crop_file, " ", mn_file, " ", out_file)
          system(cdo_code)
        }
    terminal_code <- paste0("rm ", mn_file, " ", crop_file)
    system(terminal_code)
  }

  plan(multisession, workers = w)
    future_walk(files, get_anom)
  plan(sequential)

  # Goto 6_ESM_Regrid_and_Fill.R
