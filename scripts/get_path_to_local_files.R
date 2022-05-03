args = commandArgs(TRUE)

if (length(args) == 0) {
	stop("You need to provide arguments", call. = FALSE)
} else {
	project_seed    <- as.numeric(args[1])
	DIR_local_files <- args[2]
}

project_info <- list(project_seed    = project_seed,
					 DIR_local_files = DIR_local_files)

save(project_info, file = "tmp/initial_setup.RData")
