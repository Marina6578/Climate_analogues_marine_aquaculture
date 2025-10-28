# 7: Crop products to new grid, regrid ESM to JPL MUR grid and add the observed daily mean
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # November 2024


# Startup ----------------------------------------------------------------------

  source("Helpers.R")


# Set up details ---------------------------------------------------------------

  xmin <- 141.0
  ymin <- -47.25
  xmax <- 153.0
  ymax <- -39.0
  input_folder <- "/Volumes/Jet_drive_too/TAS_regridded_anomalies"
  tmp_folder <- make_folder("/Volumes/Jet_drive/TAS_JPL_Bias_Corrected")
  output_folder <- make_folder("/Volumes/Mega_Disk/TAS_JPL_Bias_Corrected")
  w <- 4  # Number of workers (parallel processes) to use
  # base_rast_folder <- "Base_raster"


# Make base-grid raster --------------------------------------------------------

  mn_file <- "/Volumes/Mega_Disk/JPL_MUR_SST_Combo/jplMUR41_mean_sst_20030101-20141231.nc"
  # mn_out <- dir("Base_raster", full.names = TRUE)
  mn_out <- mn_file %>%
    str_replace("_mean_", "_cropped_mean_")
  cdo_code <- paste0("cdo -L -sellonlatbox,", xmin, ",", xmax, ",", ymin, ",", ymax," ", mn_file, " ", mn_out)
    system(cdo_code)


# Remap files ------------------------------------------------------------------

  remap_netCDF <- function(f, fill_missing = TRUE) {
    bits <- get_CMIP6_bits(basename(f))
    out_file <- f %>%
      str_replace(input_folder, tmp_folder) %>%
      str_replace("_1982", "_2015")
    if(!file.exists(out_file)) {
      cdo_code <- paste0("cdo -s -L -selyear,2015/2100 -remapbil,", mn_out, " [ -sellonlatbox,",
                         xmin, ",", xmax, ",", ymin, ",", ymax, " ",
                         f, " ] ", out_file)
          system(cdo_code)
      f1 <- out_file
      out_file <- f1 %>%
        str_replace("_RegriddedAnomalies_", "_BC_") %>%
        str_replace(tmp_folder, output_folder)
      cdo_code <- paste0("cdo -L -ydayadd ", f1, " ", mn_out, " ", out_file)
        system(cdo_code)
      terminal_code <- paste0("rm ", f1)
        system(terminal_code)
        }
      }

  # Get files and remap
  files <- dir(input_folder, full.names = TRUE) %>%
    str_subset("ssp534-over", negate = TRUE)
  # plan(multisession, workers = w)
    walk(files, remap_netCDF)
  # plan(sequential)
  system(paste0("rm -r ", base_rast_folder))

# Goto 8_Get_days_hotter_than.R