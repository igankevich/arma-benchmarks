#!/usr/bin/Rscript

middle_element <- function (x) {
	x[round(length(x) + 0.5)/2]
}

for (test_no in c('velocity')) {
	cairo_pdf(filename=paste(test_no,".pdf",sep=""), width=7, height=8)
	par(mfrow=c(2,1))
	root <- file.path('verification', test_no)
	conf <- list()
	conf[["linear"]] <- list()
	conf[["our-formula"]] <- list()
	conf[["linear"]][["title"]] <- "Linear wave theory"
	conf[["our-formula"]][["title"]] <- "Our formula"
	print(conf)

	for (test_case in c('linear', 'our-formula')) {
		phi <- read.csv(file.path(root, test_case, 'phi.csv'))
		left_top_x <- 0
		right_top_x <- max(phi$x)
# slice time and Y ranges through the center
		slice_t <- middle_element(unique(phi$t))
		slice_y <- middle_element(unique(phi$y))
		print(paste('Middle elements of phi (TY) = ', slice_t, slice_y))
		phi_slice <- phi[phi$t == slice_t & phi$y == slice_y & phi$x >= left_top_x & phi$z >= -5,]
		x <- unique(phi_slice$x)
		z <- unique(phi_slice$z)
		left_top_z <- max(phi_slice$z)
		right_top_z <- left_top_z
		print(paste('Velocity field size (XZ) = ', length(x), length(z)))

# convert data frame to matrix
		seq_x <- seq_along(x)
		seq_z <- seq_along(z)
		indices <- data.matrix(expand.grid(seq_x, seq_z))
		u <- with(phi_slice, {
			out <- matrix(nrow=length(seq_x), ncol=length(seq_z))
			out[indices] <- phi
			out
		})
#summary(u)

# get wave profile
		zeta <- read.csv(file.path(root, test_case, 'zeta.csv'))
		slice_t_2 <- slice_t
		slice_y_2 <- middle_element(unique(zeta$y))
		print(paste('Middle elements of zeta (TY) = ', slice_t_2, slice_y_2))
		zeta_slice <- zeta[zeta$t == slice_t_2 & zeta$y == slice_y_2 & zeta$x >= left_top_x,]
#print(zeta_slice)
#print(x)



		phi_range <- range(phi_slice[phi_slice$z <= zeta_slice$z, "phi"])
		print(phi_range)
		large_phi_slice <- phi_slice[phi_slice$z <= zeta_slice$z & phi_slice$phi > 13.5490,]
		print(large_phi_slice)

		nlevels <- 81
		levels <- pretty(c(-25,25), nlevels)
		palette <- colorRampPalette(c("blue", "lightyellow", "red"))
		col <- palette(nlevels-1)

		plot.new()
		plot.window(xlim=range(x),ylim=range(z),asp=1)
		axis(1); axis(2); box()
		
#	.filled.contour(
#		x, z, u,
#		levels=levels,
#		col=col
#	)
		
		
		contour(
			x, z, u,
			nlevels=nlevels,
			asp=1,
			drawlabels=TRUE,
			add=TRUE,
			vfont=c('sans serif', 'bold'),
			labcex=0.8
		)

		top_area_x <- c(left_top_x*0.99, zeta_slice$x, right_top_x*1.01)
		top_area_z <- c(left_top_z*1.10, zeta_slice$z, right_top_z*1.10)
		polygon(top_area_x, top_area_z, lwd=2, border='white', col='white')
		lines(zeta_slice$x, zeta_slice$z, lwd=2)
		points(
			large_phi_slice$x,
			large_phi_slice$z,
			col='black',
			bg='black',
			pch=19
		)
		title(main=conf[[test_case]][["title"]], xlab='x', ylab='z')
		box()
	}
	dev.off()
}
