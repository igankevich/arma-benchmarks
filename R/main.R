#!/usr/bin/Rscript
source(file.path("R", "arma.load.R"))
library(ascii)
options(asciiType="org")

models <- c("ar", "ma", "lh");
frameworks <- c("openmp", "opencl")
tags <- list(
	coefs=c("deteremine_coefficients","determine_coefficients"),
	"validate",
	"generate_surface",
#	"generate_white_noise",
	"nit",
	velocity=c("window_function", "second_function", "fft", "dev_to_host_copy")
)
param_tags <- list(
	"Output grid size"
)
attempt <- "a2"
for (framework in frameworks) {
	data <- data.frame()
	for (m in models) {
		if (!(m %in% colnames(data))) {
			data[,m] <- rep(NA, nrow(data))
		}
		idx <- 1
		for (t in tags) {
			all_data <- arma.load(
				"output",
				"gpulab1",
				attempt,
				10000,
				framework,
				m,
				t,
				".*\\s+([0-9]+)us.*"
			)
			name <- names(tags)[idx]
			data[if (nchar(name) == 0) t else name,m] <- mean(all_data/1000/1000)
			idx <- idx + 1
		}
		for (t in param_tags) {
			all_data <- arma.load(
				"output",
				"gpulab1",
				attempt,
				10000,
				framework,
				m,
				t,
				".*=\\s+\\(([0-9,]+)\\).*",
				numeric=FALSE
			)
			print(t)
			print(unique(all_data))
		}
	}

#	print(data)
	
	# translate and pretty print in org-mode format
	framework_names <- list(
		openmp="OpenMP",
		opencl="OpenCL"
	)
	model_names <- list(
		ar="AR",
		ma="MA",
		lh="LH"
	)
	colnames(data) <- sapply(colnames(data), function (c) get(c, model_names))
	#rownames(data) <- sapply(rownames(data), function (c) get(c, framework_names))
	print(ascii(data))
}
