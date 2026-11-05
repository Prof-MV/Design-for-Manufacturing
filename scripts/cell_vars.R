# Usage: Rscript scripts/cell_vars.R <chapter.qmd> <cell-label> '<overrides list>' 'expr1; expr2'
# Runs a {webr-r} cell with input overrides and prints variables from it.
a <- commandArgs(TRUE)
txt <- paste(readLines(a[1], warn = FALSE), collapse = "\n")
open <- paste0("```", "{webr-r}\n#| label: ", a[2], "\n")
start <- regexpr(open, txt, fixed = TRUE)
if (start < 0) stop("cell not found")
rest <- substring(txt, start + nchar(open))
code <- substring(rest, 1, regexpr("\n```", rest, fixed = TRUE) - 1)
over <- eval(parse(text = a[3])); lines <- strsplit(code, "\n")[[1]]
for (n in names(over)) {
  i <- grep(paste0("^", n, "[[:space:]]*(<-|=)"), lines)[1]
  if (is.na(i)) stop("no line for ", n)
  lines[i] <- sub("(<-|=).*$", paste0("\\1 ", deparse(over[[n]])), lines[i])
}
env <- new.env(); pdf(NULL); invisible(capture.output(eval(parse(text = lines), env)))
for (e in strsplit(a[4], ";")[[1]]) cat(trimws(e), "=", format(eval(parse(text = e), env)), "\n")
