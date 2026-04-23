# 6: Regrid cropped ESM daily anomalies to 0.25º and fill land with distance-weighted means
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # November 2024


# Startup ----------------------------------------------------------------------

  source("Helpers.R")


# Set up details ---------------------------------------------------------------

  xmin <- 140.0
  ymin <- -57.0
  xmax <- 162.0
  ymax <- -36.0
  input_folder <- "/Volumes/Mega_Disk/TAS_std_anomalies"
  output_folder <- make_folder("/Volumes/Mega_Disk/TAS_regridded_anomalies")
  # w <- detectCores()-4  # Number of workers (parallel processes) to use
  w <- 4  # Number of workers (parallel processes) to use
  base_rast_folder <- make_folder("Base_raster")
  cell_res = 0.25 # Resolution of base-grid raster
  domain_extent <- ext(c(xmin, xmax, ymin, ymax))


  # Make base-grid raster --------------------------------------------------------

  base_rast <- paste0(base_rast_folder, "/base_rast.nc")
  r <- rast(resolution = cell_res, ext = domain_extent)
  r[] <- 1
  mask2netCDF4(r, pth = base_rast_folder,
               ncName = basename(base_rast),
               dname = "tos",
               dlname = "tos")

  # Remap files ------------------------------------------------------------------
  # NOTE that by default missing cells (land) are filled using inverse distance-weighted means
  remap_netCDF <- function(f, fill_missing = TRUE) {
    bits <- get_CMIP6_bits(basename(f))
    out_file <- f %>%
      str_replace(input_folder, output_folder) %>%
      str_replace("_anomaly_", "_RegriddedAnomalies_")
    if(!file.exists(out_file)) {
      if(fill_missing == TRUE) {
        if(bits$Variable == "pr") { # For precipitation, use conservative remapping
          cdo_code <- paste0("cdo -s -L -setmisstodis -remapcon,", base_rast, " ", f, " ", out_file)
          system(cdo_code)
        } else { # For everything else, use bilinear interpolation
          cdo_code <- paste0("cdo -s -L -setmisstodis -remapbil,", base_rast, " ", f, " ", out_file)
          system(cdo_code)
        }
      } else {
        if(bits$Variable == "pr") { # For precipitation, use conservative remapping
          cdo_code <- paste0("cdo -s -L -remapcon,", base_rast, " ", f, " ", out_file)
          system(cdo_code)
        } else { # For everything else, use bilinear interpolation, although Bio-ORACLE uses remapdis, so consider changing to that
          cdo_code <- paste0("cdo -s -L -remapbil,", base_rast, " ", f, " ", out_file)
          system(cdo_code)
        }
      }
    }
  }

  # Get files and remap
  files <- dir(input_folder, full.names = TRUE)
  plan(multisession, workers = w)
    future_walk(files, remap_netCDF)
  plan(sequential)
  # system(paste0("rm -r ", base_rast_folder))

# Goto 7_Crop_Regrid_and_Add.R
