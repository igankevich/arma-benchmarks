#!/usr/bin/Rscript

library(plot3D)

middle_element <- function (x, fraction=0.5) {
	x[round(length(x) + 0.5)*fraction]
}

arma.wavy_plot <- function (data, t, ...) {
	slice <- data[data$t == t,]
	slice$t <- NULL
	x <- unique(slice$x)
	y <- unique(slice$y)
	nx <- length(x)
	ny <- length(y)
	z <- with(slice, {
	  out <- matrix(nrow=nx, ncol=ny)
	  for (i in seq(0,nx-1)) {
		  for (j in seq(0,ny-1)) {
			  r <- i*nx + j
			  out[i,j] <- z[[r+1]]
		  }
	  }
	  out
	})
	print("qwe")
	print(length(x))
	print(length(y))
	print(dim(z))
	nrz <- nrow(z)
	ncz <- ncol(z)
	# Create a function interpolating colors in the range of specified colors
	jet.colors <- colorRampPalette( c("black", "white") )
	# Generate the desired number of colors from this palette
	nbcol <- 1000
	color <- jet.colors(nbcol)
	# Compute the z-value at the facet centres
	zfacet <- z[-1, -1] + z[-1, -ncz] + z[-nrz, -1] + z[-nrz, -ncz]
	# Recode facet z-values into color indices
	facetcol <- cut(zfacet, nbcol)
#	persp3D(x, y, z, phi=30, theta=30, col=color[facetcol], ...)
	persp3D(x, y, z, phi=30, theta=30, col=color, ...)
}

root <- file.path('verification', 'velocity', 'our-formula')
cairo_pdf(filename='velocity-3d.pdf', width=7, height=8)

phi <- read.csv(file.path(root, 'phi.csv'))
zeta <- read.csv(file.path(root, 'zeta.csv'))

slice_t <- middle_element(unique(phi$t))
zeta_x <- unique(zeta$x)
zeta_y <- unique(zeta$y)
mid_t <- slice_t
mid_y <- middle_element(zeta_y)
mid_x <- middle_element(zeta_x)
max_y <- middle_element(zeta_y, 0.75)
min_y <- middle_element(zeta_y, 0.25)
max_x <- max(zeta_x)

print(paste('Zeta size (t,x,y) = ', range(zeta$t), range(zeta$x), range(zeta$y)))
print(paste('Slice zeta at (t,x,y) = ', mid_t, mid_x, mid_y))
print(paste('Slice phi at t=', slice_t))
phi_slice <- phi[phi$t == slice_t & phi$z >= -5,]
zeta_slice <- zeta[zeta$t == slice_t,]
phi_slice[phi_slice$z > zeta_slice$z,'phi'] <- NA
phi_slice <- phi_slice[phi_slice$y >= min_y & phi_slice$y <= max_y, ]
phi_x <- unique(phi_slice$x)
phi_y <- unique(phi_slice$y)
phi_z <- unique(phi_slice$z)
print(paste('Velocity field size (XZ) = ', length(phi_x), length(phi_z)))

# convert data frame to matrix
seq_x <- seq_along(phi_x)
seq_z <- seq_along(phi_z)
indices <- data.matrix(expand.grid(seq_x, seq_z))
phi_arr <- with(phi_slice, {
	nx <- length(phi_x)
	ny <- length(phi_y)
	nz <- length(phi_z)
	out <- array(0, dim=c(nx,ny,nz))
	for (k in seq(0,nz-1)) {
		for (i in seq(0,nx-1)) {
			for (j in seq(0,ny-1)) {
				r <- k*nx*ny + i*ny + j
				out[i,j,k] <- phi[[r+1]]
			}
	    }
	}
	out
})
#u <- with(phi_slice, {
#	out <- matrix(nrow=length(seq_x), ncol=length(seq_z))
#	out[indices] <- phi
#	out
#})
#summary(u)

# get wave profile



# remove 1/4 of the surface using NAs
zeta[zeta$t == slice_t & zeta$x > mid_x & zeta$y < mid_y | zeta$y > max_y | zeta$y < min_y, 'z'] <- NA
arma.wavy_plot(
	zeta,
	slice_t,
	xlim=range(c(0,1.05*max_x)),
	ylim=range(c(0.9*min_y,max_y)),
	scale=FALSE,
	colkey=list(plot=FALSE)
)

nlevels <- 31
levels <- pretty(c(-25,25), nlevels)
palette <- colorRampPalette(c("blue", "lightyellow", "red"))
color <- palette(nlevels-1)

slicecont3D(
	phi_x,
	phi_y,
	phi_z,
	colvar=phi_arr,
	xs=0.99*mid_x,
	ys=0.99*mid_y,
	zs=NULL,
	add=TRUE,
	col='#404040',
	NAcol=rgb(0,0,0,0),
	level=levels
)

quit()



phi_range <- range(phi_slice[phi_slice$z <= zeta_slice$z, "phi"])
print(phi_range)
large_phi_slice <- phi_slice[phi_slice$z <= zeta_slice$z & phi_slice$phi > 13.5490,]
print(large_phi_slice)

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

