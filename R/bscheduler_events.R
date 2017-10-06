#!/usr/bin/Rscript
source(file.path("R", "arma.load_events.R"))
#pdf(width=10,height=5)

#attempt <- "a9-bscheduler-fast"
attempt <- "a8-bscheduler"
hostname <- "gpulab1"
all_data = data.frame(
	framework=rep(NA,0),
	size=rep(NA,0),
	t=rep(NA,0)
)
row <- 1
for (size in seq(10000, 30000, 2500)) {
	for (framework in c("openmp", "bscheduler")) {
		data <- arma.load_events(
			file.path("output", hostname, attempt, size, framework, "ar"),
			c("programme")
		)
		ev_prog <- data[data$event == "programme",]
		all_data[row, 'framework'] <- framework
		all_data[row, 'size'] <- size
		all_data[row, 't'] <- mean(ev_prog$t1 - ev_prog$t0)*1e-6
		row <- row + 1
	}
}
print(all_data)
plot.new()
plot.window(xlim=range(all_data$size), ylim=range(0,all_data$t))
conf <- list(
	a=list(
		framework='openmp',
		color='#000000',
		lty="solid",
		lwd=3,
		name="OpenMP"
	),
	b=list(
		framework='bscheduler',
		color='#f00000',
		lty="solid",
		lwd=3,
		name="Bscheduler"
	)
)
for (c in conf) {
	data <- all_data[all_data$framework==c$framework, ]
	lines(data$size, data$t, col=c$color)
	points(data$size, data$t, col=c$color)
}
legend(
	"bottomright",
	legend=sapply(conf, function (c) c$name),
	col=sapply(conf, function (c) c$color),
	lty=sapply(conf, function (c) c$lty),
	lwd=sapply(conf, function (c) c$lwd)
)
axis(1)
axis(2)
box()
title(xlab='Wavy surface size', ylab='Time, s')
