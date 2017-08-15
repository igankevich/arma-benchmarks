#!/usr/bin/Rscript
source(file.path("R", "arma.load.R"))
library(ascii)
options(asciiType="org")

tags <- c(
	"harts_g1",
	"harts_g2",
	"harts_fft",
	"harts_copy_to_host"
)
sizes <- 2^c(7:14)
frameworks <- c("openmp", "opencl")
attempt <- "a6"
data <- data.frame()
row <- 1
for (framework in frameworks) {
	for (m in sizes) {
		for (t in tags) {
			all_data <- arma.load(
				file.path("output", "storm", attempt, m, framework),
				t,
				".*\\s+([0-9]+)us.*"
			)
			data[row,"framework"] <- framework
			data[row,"size"] <- as.integer(m)
			data[row,"t"] <- mean(all_data/1000/1000)
			data[row,"routine"] <- t
			row <- row + 1
		}
	}
}
print(ascii(data))
