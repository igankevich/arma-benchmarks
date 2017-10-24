#!/usr/bin/Rscript
source(file.path("R", "arma.load_events.R"))
#pdf(width=10,height=5)

all_data = data.frame(
	framework=rep(NA,0),
	size=rep(NA,0),
	t=rep(NA,0)
)
#all_test_cases <- list(c("a8", "openmp", "gpulab1"),
#					   c("a8", "bscheduler", "gpulab1"),
#					   c("a9-single-node", "bscheduler", "gpulab1"))
#all_test_cases <- list(c("a9-single-node-direct", "openmp", "m1"),
#					   c("a9-single-node-direct", "bscheduler", "m1"),
#					   c("a9-two-nodes-direct", "bscheduler", "m1"))
all_test_cases <- list(c("a10-failure-direct-slave", "bscheduler", "m1"),
					   c("a9-single-node-direct", "bscheduler", "m1"),
					   c("a10-failure-direct-master", "bscheduler", "m1"))
row <- 1
for (size in seq(10000, 30000, 2500)) {
	for (test_case in all_test_cases) {
		attempt <- test_case[[1]]
		framework <- test_case[[2]]
		hostname <- test_case[[3]]
		data <- arma.load_events(
			file.path("output", hostname, attempt, size, framework, "ar"),
			c("programme")
		)
		ev_prog <- data[data$event == "programme",]
		all_data[row, 'framework'] <- paste(attempt, framework, sep="-")
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
		framework='a10-failure-direct-slave-bscheduler',
		color='#000000',
		lty="solid",
		lwd=3,
		name="Bscheduler (slave failure)"
	),
	b=list(
		framework='a10-failure-direct-master-bscheduler',
		color='#0000f0',
		lty="solid",
		lwd=3,
		name="Bscheduler (master failure)"
	),
	c=list(
		framework='a9-single-node-direct-bscheduler',
		color='#f00000',
		lty="solid",
		lwd=3,
		name="Bscheduler (no failures)"
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
