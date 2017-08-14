#!/usr/bin/Rscript
source(file.path("R", "arma.load_events.R"))
pdf(width=10,height=5)

attempt <- "a5-xfs-events"
data <- arma.load_events(
	file.path("output", "gpulab1", attempt, 10000, "openmp", "ar"),
	c("write_surface", "generate_surface", "programme")
)
ev_prog <- data[data$event == "programme",]
ev_gen <- data[data$event == "generate_surface",]
ev_write <- data[data$event == "write_surface",]
ev_write$thread_no = max(ev_gen$thread_no) + 1
threads <- 0:max(ev_write$thread_no)
max_x <- max(ev_write$t1, ev_gen$t1)/1000/1000
plot.new()
plot.window(xlim=c(0,max_x), ylim=range(threads))
conf <- list(
	a=list(
		table=ev_gen,
		color='#000000',
		lty="solid",
		lwd=3,
		name="generate_surface"
	),
	b=list(
		table=ev_write,
		color='#f00000',
		lty="solid",
		lwd=3,
		name="write_surface"
	)
)
for (c in conf) {
	table <- c$table
	for (row in seq(1,nrow(table),1)) {
		ev <- table[row,]
		ys <- rep(ev$thread_no, 2)
		xs <- c(ev$t0, ev$t1)/1000/1000
#		points(xs[[1]], ys[[1]], pch=19, cex=0.4)
#		arrows(xs[[1]], ys[[1]], xs[[2]], ys[[2]], angle=10, length=0.05)
		lines(xs, ys, lwd=3, col=c$color)
	}
}
legend(
	"top",
	inset=c(0,-0.2),
	legend=sapply(conf, function (c) c$name),
	col=sapply(conf, function (c) c$color),
	lty=sapply(conf, function (c) c$lty),
	lwd=sapply(conf, function (c) c$lwd),
	xpd=TRUE
)
par(mai=c(1,1,1,1))
axis(1, at=pretty(c(0,max_x)))
axis(
	2,
	at=threads,
	labels=c(sapply(
		threads[1:(length(threads)-1)],
		function (t) paste("omp", t, sep="-")
	), "io-0"),
	las=2
)
mtext("Time, s", side=1, line=3)
mtext("Thread", side=2, line=4)
