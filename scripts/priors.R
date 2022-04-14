# RQ1
# informative priors (based on grand average)
priors <- c(
	prior("normal(4, 2)", class = "b", coef = "Intercept"), 
	prior("normal(0, 1)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)

# weakly-informative priors (based on grand average)
priors <- c(
	prior("normal(4, 4)", class = "b", coef = "Intercept"), 
	prior("normal(0, 4)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)

# non-informative priors (based on grand average)
priors <- c(
	prior("normal(4, 10)", class = "b", coef = "Intercept"), 
	prior("normal(0, 10)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)

# RQ2 
# informative priors (based on grand average)
priors <- c(
	prior("normal(-8, 2)", class = "b", coef = "Intercept"), 
	prior("normal(0, 1)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)

# weakly-informative priors (based on grand average)
priors <- c(
	prior("normal(-8, 4)", class = "b", coef = "Intercept"), 
	prior("normal(0, 4)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)

# non-informative priors (based on grand average)
priors <- c(
	prior("normal(-8, 10)", class = "b", coef = "Intercept"), 
	prior("normal(0, 10)", class = "b"),
	prior("student_t(3, 0, 2)", class = "sd")
)
