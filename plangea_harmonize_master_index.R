plangea_harmonize_master_index = function(cfg, file_log, flag_log, lu_ras, lu_aux,
                                          verbose=T, force_comp=F){
  
  # Adding 'master' control flag to flag_log
  flag_log$master = F
  
  # Update checks
  type_check = (cfg$scenarios$problem_type != file_log$start$scenarios$problem_type) # problem type changed
  lu_check = flag_log$lu                                                     # land-use files were updated
  rds_check = (!file.exists(paste0(in_dir, 'master_index')))         # resulting data file not found
  
  if (type_check | lu_check | rds_check | force_comp) {
    # Modifies control structures to indicate master_index will be computed
    flag_log$master = T
    
    # Prints info on why master_index is being computed
    if (verbose) {cat(paste0('Computing master_index results. Reason(s): \n',
                             ifelse(type_check, 'different type of problem \n', ''),
                             ifelse(rds_check, 'land-use variables were changed \n', ''),
                             ifelse(force_comp, 'because you said so! \n', '')
    ))}
    
    
    # Unpacking needed quantities from lu_res
    lu_class_types = lu_aux$lu_class_types
    
    # Loading type of optimisation problem
    # Possible types of optimisation: "C"onservation, "R"estoration
    optim_type = cfg$scenarios$problem_type
    
    # Building list relating type of LU to type of optimisation
    lu_to_optim = lu_class_types
    lu_to_optim[lu_to_optim == 'N'] = 'C'
    lu_to_optim[lu_to_optim == 'A'] = 'R'
    
    # Builds raster of interest areas
    interest_areas = Reduce('+', lu_ras[lu_to_optim %in% optim_type])
    
    # Building master_index of pixels of interest
    master_index = which(values(interest_areas > 0))
    
    # Computing upper bounds to conservation / restoration of each cell
    ub_vals = interest_areas[master_index]
    
    # Computing overall area of interest
    overall_area = sum(ub_vals)
    
    # Computing pixel area
    # (for some strange reason area is returning a value compatible with
    # m2 units, instead of km2 units as stated in the command's help. 
    # Thus, a conversion to km2 is applied here, to conform with units in help.
    px_area = area(lu_ras[[1]])[master_index] * 1e-6
    
    mi_aux = list(ub_vals = ub_vals, overall_area = overall_area,
                  px_area = px_area)
    
    pigz_save(master_index, file = paste0(in_dir, 'master_index'))  
    pigz_save(mi_aux, file = paste0(in_dir, 'mi_aux'))
  } else {
    if (verbose) {cat('Loading master index data \n')}
    master_index = pigz_load(paste0(in_dir, 'master_index'))
    mi_aux = pigz_load(paste0(in_dir, 'mi_aux'))
    ub_vals = mi_aux$ub_vals
    overall_area = mi_aux$overall_area
    px_area = mi_aux$px_area
}
  return(list(master_index = master_index, px_area = px_area,
              ub_vals = ub_vals, overall_area = overall_area,
              file_log = file_log, flag_log = flag_log))
}