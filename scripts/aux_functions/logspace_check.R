my_logspace <- function(x_start, x_end, n_values) {
	aux_vector <- array(0, dim = c(n_values))
	aux_power_values <- seq(from = x_start, to = x_end, length.out = n_values)
	
	for(i in 1:n_values) {
		aux_vector[i] <- 10 ^ aux_power_values[i]
	}
	
	return(aux_vector)
}

my_logspace(x_start = 2, x_end = 3, n_values = 4)

cbind(0:17,
	  my_logspace(x_start = log(4, base = 10), 
	  			  x_end = log(40, base = 10),
	  			  n_values = 18))




