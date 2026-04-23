# Climate_analogues_marine_aquaculture

This repository is related to the Manuscript sent for Publication with the title: Title: Climate analogues as a tool for marine aquaculture planning and adaptation

Authors: Marina Christofidis, David Schoeman, Jeremy Harte, Vanessa Adams, Jackson Stockbridge, Caitlin D. Kuempel

Marina Christofidis 1,2 David Schoeman 3,4 Jeremy Harte 1 Vanessa Adams 5,6 Jackson Stockbridge 1 Caitlin D. Kuempel 1

Affiliations: 1 School of Environment and Science, Australian Rivers Institute, Griffith University, Nathan, QLD, Australia 2 Ministry of Management and Innovation in Public Services (MGI), Brazilian Federal Government, Brasilia, Brazil. 3 Ocean Futures Research Cluster, School of Science, Technology, and Engineering, University of the Sunshine Coast, Maroochydore, Queensland, Australia 4 Centre for African Conservation Ecology, Department of Zoology, Nelson Mandela University, Gqeberha, South Africa 5 School of Geography, Planning, and Spatial Sciences, University of Tasmania, Hobart, TAS, Australia 6 Centre for Marine Socioecology, University of Tasmania, Hobart, Australia

Corresponding author: Marina Christofidis marina.christofidis@griffithuni.edu.au marina.christofidis@gmail.com

As mentioned in the methods, we used daily SST projections (2015–2100) and corresponding historical runs (2003–2014) downloaded from the Earth System Grid Federation (ESGF — https://esgf.nci.org.au/search) and historical Multiscale Ultrahigh Resolution (MUR) Level-4 daily product developed by NASA's Jet Propulsion Laboratory (JPL) (https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1). The datasets of uses and habitats that we considered as constraints to aquaculture are detailed in Table 1 *Depth (Bathymetry) <- (Australian Bathymetry and Topography Grid, June 2009; *Kelp (sensitive habitats) <- Seacare Inc (2020): Aerial surveys of giant kelp (Macrocystis pyrifera) from Eddystone Point to Southeast Cape, Tasmania, 2009. dataset. https://metadata.imas.utas.edu.au/geonetwork/srv/eng/catalog.search#/metadata/1597c354-8782-4d55-81d9-60ff737febd2 ; *Reefs<- (Lucieer VL, 2007) SeaMap Tasmania Habitat Data. Tasmanian Aquaculture and Fisheries Institute. Data accessed at http://metadata.imas.utas.edu.au/geonetwork/srv/eng/metadata.show?uuid=7a6751e0-1ad5-11dc-9e36-00188b4c0af8 accessed on January 2025; *MPAs<- Collaborative Australian Protected Areas Database (CAPAD) 2024(DCCEEW, 2024) — Marine; modified based on the South-east Network management plan (Australian Marine Parks, 2025) *Tasmnaian protected areas<- The Marine Nature Reserve dataset includes areas of Tasmanian State Waters that have been defined as Marine Nature Reserves by the Tasmanian Fisheries Rules 1999. *Shipping<- AMSA Vessel traffic data August 2024 Digital Data

The Data analysis and visualization for this project were conducted in R using several key packages:

Oceanographic data were accessed through rerddap (Chamberlain, 2015). Spatial data processing was performed using sf (Pebesma, 2018) and terra(Hijmans, 2020), Data manipulation and visualization foundation were provided by: The tidyverse collection of packages (Wickham et al., 2019), including dplyr (Wickham et al., 2019, 2014), ggplot2 (Wickham, 2016), purrr (Wickham and Henry, 2015), stringr (Wickham, 2009), and readr (Wickham et al., 2015). The Interactive maps were created using tmap (Tennekes, 2018) and leaflet (Cheng et al., 2015), while reactable (Lin, 2019) was used for interactive tables. The Color palettes were implemented through viridis(Garnier, 2015), and project organization was managed with here (Müller, 2017). Other additional visualization tools included rasterVis (Perpinan Lamigueiro and Hijmans, 2011) and table formatting with kableExtra (Zhu, 2017).

| Script Used | Description of code |
|-------------|---------------------|
| Helpers | functions to help with other codes |
| 1_Download_JPL_MUR_SST | code to download historical SST data |
| 2_MergeJPL_MUR_SST_and_Mean.Rmd | merge historical data SST and find mean |
| 3_Run_Wget_scripts.Rmd | find SST projections |
| 4_Merge_and_trim_CMIP_netCDFs.Rmd | merge and trim SST projections to region |
| 5_Crop_Regrid_and_Add.Rmd | recrop and regrid and bias correction |
| 6_Get_days_Hotter_than_historicaldata.Rmd | get days hotter than SST thresholds in historical data |
| 7_Crop_Regrid_and_Add.Rmd | recrop and regrid and bias correction |
| 8_Get_days_hotter_than.Rmd | get days hotter than SST thresholds in projections 17C and 21.5C |
| 9_A_values_historical_data_aqua_sites_EF_Oct25.Rmd | Check historical values of number of days above the SST thresholds in current finfish aquaculture sites |
| 9_B_reclass_17C_EF_Oct25.Rmd | reclassify the daysabove17C data considering the historical frequency of days over 17C |
| 9_C_reclass_21C_EF_Oct25.Rmd | reclassify the daysabove 21.5C data considering the historical frequency of days over 21.5C |
| 10_projection_ensemble_17C_EF_Oct25.Rmd | gather the reclassified 17C data of all ESMs in an ensemble |
| 10_projection_ensemble_21C_EF_Oct25.Rmd | gather the reclassified 21.5C data of all ESMs in an ensemble |
| 11_Overlapping_suitable_analogues_EF_Oct25.Rmd | Overlap the reclassified 17C ensembles and the 21.5C ensembles |
| 12_Reclass_ESM_agreement_viridis_EF_Oct25 | Confidence level calculation and map creation showing the agreement between ESMs. Last step is the creation of a composite map |
| 13_A_MSP_contraints_shipping_EF_Oct25 | Make the shipping constraints layer |
| 13_B_MSP_FINAL_Code_function_Constraints_EF_Oct25 | Make the constraint layer to aquaculture to later overlap with the climate data |
| 14_km2_suitability_over_time_results_EF_Oct25 | Check amount of area that is analogue of suitable and optimal condition over time without constraints to aquaculture |
| 15_climate_MSP_combined_analysis_viridis_EF_Oct25 | Make maps of analogues with ESM agreements and constraints - individually, then makes composite plot (Viridis) |
| 16_km2_area_climate_and_constraints_plots_EF_Oct25 | Check amount of area that is analogue of suitable and optimal condition over time with constraints to aquaculture |
| 17_km2_fold_area_available_marine_territory_overtime_EF_Oct25 | fold area available over time by marine territory |
| 18_Marine territories_map_with_inset_EF_OCt25 | make map for publication in R with inset map |
| 19_plots_unconstrained_by_territory_EF_Oct25 | make plots of analogues of suitable and optimal conditions without constraints to aquaculture |
| 20_plots_paper_constrained_by_territory_EF_Oct25 | make plots of analogues of suitable and optimal conditions with constraints to aquaculture |
| 21_comparison_contrained_not_table_EF_Ot25 | compare areas of analogues of suitable and optimal conditions with and without constraints and make a table to facilitate writing |
| 22_comparison_before_after_constraints_EF_Oct25 | making texts and other comparisons that we can use to write about the results and the discussion |
