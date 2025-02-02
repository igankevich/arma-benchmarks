arma.load <- function (dir, tag, regex, ...) {
	args <- list(...)
	if (!("numeric" %in% names(args))) {
		args$numeric = TRUE
	}
	files <- sort(list.files(dir, pattern="\\.log$"))
	message(paste("Reading", dir))
	result <- c()
	for (f in files) {
		lines <- readLines(file.path(dir, f))
		tag_list <- tag
		if (length(tag) > 1) {
			tag_list <- paste(tag, collapse="|")
			tag_list <- paste("(", tag_list, ")", sep="")
		}
		lines <- lines[grepl(tag_list, lines, perl=TRUE)]
		lines <- gsub(regex, "\\1", lines, perl=TRUE)
		if (args$numeric) {
			lines <- as.numeric(lines)
			if (length(tag) > 1 && length(lines) > 0) {
				lines <- sum(lines)
			}
		}
		if (length(lines) == 0) {
			lines <- NA
		}
		result <- c(result, lines)
	}
	result
}
