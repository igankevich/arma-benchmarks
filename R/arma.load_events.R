arma.load_events <- function (dir, tags, ...) {
	args <- list(...)
	if (!("numeric" %in% names(args))) {
		args$numeric = TRUE
	}
	files <- sort(list.files(dir, pattern="\\.log$"))
	message(paste("Reading", dir))
	# consruct regex
	tag_list <- tags
	if (length(tags) > 1) {
		tag_list <- paste(tags, collapse="|")
		tag_list <- paste("(", tag_list, ")", sep="")
	}
	event_regex <- paste("^evnt\\s+.*", tag_list, ".*$", sep="")
	event_ids <- list()
	events <- list()
	result <- data.frame()
	for (f in files) {
		lines <- readLines(file.path(dir, f))
		lines <- lines[grepl(event_regex, lines, perl=TRUE)]
		for (ln in lines) {
			row <- strsplit(ln, "\\s+", perl=TRUE)[[1]]
			thread_name <- row[2]
			thread_no <- as.integer(row[3])
			event_kind <- row[4]
			event_tag <- row[5]
			t <- as.numeric(strsplit(row[6], "us", fixed=TRUE)[1])
			key <- paste(thread_name, thread_no, event_tag, sep="-")
			if (!(key %in% names(event_ids))) {
				event_ids[[key]] <- 1
			}
			event_id <- event_ids[[key]]
			full_key <- paste(key, sprintf("%05d", event_id), sep="-")
			if (event_kind == "strt") {
				events[[full_key]] <- list(
					thread_name=thread_name,
					thread_no=thread_no,
					t0=t,
					tag=event_tag
				)
			} else {
				events[[full_key]][["t1"]] <- t
				event_ids[[key]] <- event_id + 1
			}
		}
	}
	n <- length(events)
	result <- data.frame(
		thread_name=rep(NA, n),
		thread_no=rep(NA, n),
		event=rep(NA, n),
		t0=rep(NA, n),
		t1=rep(NA, n)
	)
	row <- 1
	for (name in names(events)) {
		ev <- events[[name]]
		if (!("thread_no" %in% names(ev))) {
			print(name)
			print(ev)
		}
		result[row,"thread_name"] <- ev[["thread_name"]]
		result[row,"thread_no"] <- ev[["thread_no"]]
		result[row,"event"] <- ev[["tag"]]
		result[row,"t0"] <- ev[["t0"]]
		result[row,"t1"] <- ev[["t1"]]
		row <- row + 1
	}
	result
}

