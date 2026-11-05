# Usage: Rscript scripts/goal_check.R <chapter.qmd> <cell-label> '<goal_test>' '<solution, e.g. list(x=3,y=4)>' [seeds=1:10]
# Checks a calculator-card goal in plain R: unmet at the defaults, met by the solution.
a <- commandArgs(TRUE)
txt <- paste(readLines(a[1], warn = FALSE), collapse = "\n")
open <- paste0("```", "{webr-r}\n#| label: ", a[2], "\n")
start <- regexpr(open, txt, fixed = TRUE)
if (start < 0) stop("cell not found")
rest <- substring(txt, start + nchar(open))
code <- substring(rest, 1, regexpr("\n```", rest, fixed = TRUE) - 1)
run <- function(over) {
  lines <- strsplit(code, "\n")[[1]]
  for (n in names(over)) {
    i <- grep(paste0("^", n, "[[:space:]]*(<-|=)"), lines)[1]
    if (is.na(i)) stop("no line for ", n)
    lines[i] <- sub("(<-|=).*$", paste0("\\1 ", deparse(over[[n]])), lines[i])
  }
  env <- new.env(); pdf(NULL)
  invisible(capture.output(try(eval(parse(text = lines), env), silent = TRUE)))
  isTRUE(tryCatch(eval(parse(text = a[3]), env), error = function(e) { message("goal error: ", conditionMessage(e)); FALSE }))
}
sol <- eval(parse(text = a[4]))
if (length(a) >= 5) {
  seeds <- eval(parse(text = sub("seeds=", "", a[5])))
  d <- sapply(seeds, function(s) run(list(seed = s)))
  v <- sapply(seeds, function(s) run(c(sol, list(seed = s))))
  cat("default met per seed:", d, "\nsolution met per seed:", v, "\n")
} else {
  cat("default met:", run(list()), "(must be FALSE)\nsolution met:", run(sol), "(must be TRUE)\n")
}
