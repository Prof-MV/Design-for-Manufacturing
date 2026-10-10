# "Try it yourself" exercises: the student commits to an answer and the page
# marks it.
#
# Companion to the calculator cards in helpers.R. A calculator card lets the
# student change an input and watch the output; a tryit exercise makes the
# student do the method and then checks the result. Each exercise is ONE call
# in a `results='asis'` chunk -- no hand-written HTML or <script> in chapters:
#
#   tryit_number()  one or more numeric answers, each marked against a tolerance
#   tryit_grid()    a table with blank cells to fill in, marked cell by cell
#   tryit_sort()    cards to assign to categories
#   tryit_order()   steps to put in the right sequence
#   tryit_diagram() boxes joined by lines, with blank values to fill in
#   tryit_balance() tasks on a precedence diagram to assign to stations
#   tryit_layout()  departments to place on a grid for the lowest
#                   load-distance score
#
# How it fits together:
#   - The helper serialises the exercise (including its answer key) to JSON
#     inside a `.tryit` div. `js/tryit.js` finds every such div on the page
#     and builds the widget. Plain JavaScript, no webR, so it also works in
#     chapters that do not load webR.
#   - Answer keys are computed here, at render time, from the same R objects
#     the chapter uses to print its worked solution, so the checker and the
#     solution cannot disagree.
#   - A `<details class="tryit-solution">` placed directly after an exercise
#     stays locked until the student has checked an answer at least once.
#   - PDF/EPUB get a printable worksheet instead (blanks to fill in by hand).
#   - Every exercise given a `question` also gets a graded twin: a Brightspace
#     import file is written to quizzes/tryit_<chapter>.csv on each HTML
#     render. Answers sit in the page source, so the on-page version is
#     practice only; pass `show = FALSE` to declare a twin with different
#     numbers that is exported but never shown in the book.
#
# Styling lives in style.css (".tryit-*" rules).

# Course code used as the prefix of exported Brightspace question IDs.
# Set options(tryit.course = "...") before sourcing this file to change it.
tryit_course <- function() getOption("tryit.course", "COURSE")

.tryit_state <- new.env()
.tryit_state$questions <- list()

tryit_html <- function() knitr::is_html_output(excludes = "epub")

tryit_id <- function(id) gsub("[^a-zA-Z0-9]+", "-", id)

# Decimal places a student is expected to give, inferred from the tolerance
# (tol = 0.01 -> 2 places, tol = 0.0005 -> 4 places).
tryit_digits <- function(tol) if (tol <= 0) 0 else max(0, ceiling(-log10(tol)))

#' One numeric answer for tryit_number() or the `answers` of tryit_grid()
#'
#' @param label Reader-facing label for the answer field.
#' @param answer The correct value -- pass the R object the solution is
#'   computed from, not a retyped literal.
#' @param tol Absolute tolerance. An entry is correct within +/- `tol`.
#' @param tol_pct Optional relative tolerance in percent; an entry within
#'   either tolerance is accepted.
#' @param prefix,suffix Short strings shown beside the field ("$", "mm").
#' @param hint Shown under the field after a wrong entry.
#' @param digits Decimal places asked for in the print/Brightspace versions.
tryit_answer <- function(label, answer, tol = 0.01, tol_pct = NULL,
                         prefix = "", suffix = "", hint = NULL,
                         digits = tryit_digits(tol)) {
  stopifnot(is.numeric(answer), length(answer) == 1, !is.na(answer))
  list(label = label, answer = answer, tol = tol, tolPct = tol_pct,
       prefix = prefix, suffix = suffix, hint = hint, digits = digits)
}

# Emit the widget shell. `spec` becomes the JSON that js/tryit.js reads.
tryit_emit <- function(type, id, spec, wide = FALSE) {
  json <- jsonlite::toJSON(spec, auto_unbox = TRUE, null = "null", digits = NA)
  # Keep a literal "</script>" in any label from closing the JSON block early.
  json <- gsub("<", "\\u003c", json, fixed = TRUE)
  # `wide` lets a diagram spill a little past the text column on a large
  # screen (Quarto's own column class), so fewer of them need to scroll.
  cat(sprintf('
%s```{=html}
<script src="js/tryit.js"></script>
<div class="tryit" id="tryit-%s" data-tryit="%s">
<script type="application/json">%s</script>
</div>
```
%s', if (wide) "::: {.column-body-outset}\n" else "", tryit_id(id), type, json,
              if (wide) ":::\n" else ""))
}

tryit_blank <- function(a) {
  sprintf("%s\\_\\_\\_\\_\\_\\_\\_\\_ %s", a$prefix, a$suffix)
}

# Printable version of a list of tryit_answer()s.
tryit_print_answers <- function(answers) {
  for (a in answers) {
    cat(sprintf("- %s: %s *(to %d decimal place%s)*\n", a$label, tryit_blank(a),
                a$digits, if (a$digits == 1) "" else "s"))
  }
  cat("\n")
}

#---- Brightspace graded twins -------------------------------------------------

tryit_csv_field <- function(x) {
  x <- as.character(x)
  quote <- grepl('[",\n]', x)
  x[quote] <- paste0('"', gsub('"', '""', x[quote], fixed = TRUE), '"')
  x
}

# Register one question (a list of rows, each a character vector of fields)
# and rewrite this chapter's import file with everything registered so far.
tryit_export <- function(rows) {
  input <- knitr::current_input()
  if (is.null(input) || !tryit_html()) return(invisible(NULL))

  .tryit_state$questions[[length(.tryit_state$questions) + 1]] <- rows

  stem <- tools::file_path_sans_ext(basename(input))
  header <- list(
    sprintf("//Graded twins of the 'Try it yourself' exercises in %s", stem),
    "//Generated by R/tryit.R on every HTML render of the chapter -- do not edit by hand.",
    "//Import into the Brightspace Question Library. Save as CSV UTF-8 before importing."
  )
  lines <- vapply(header, function(r) paste(tryit_csv_field(r), collapse = ","), character(1))
  for (q in .tryit_state$questions) {
    lines <- c(lines, "", vapply(q, function(r) paste(tryit_csv_field(r), collapse = ","), character(1)))
  }

  if (!dir.exists("quizzes")) dir.create("quizzes")
  con <- file(file.path("quizzes", sprintf("tryit_%s.csv", stem)), open = "wb")
  on.exit(close(con))
  writeLines(enc2utf8(c(paste0("﻿", lines[1]), lines[-1])), con, useBytes = TRUE)
  invisible(NULL)
}

tryit_qid <- function(id, n) {
  sprintf("%s-TRYIT-%s-%02d", tryit_course(), toupper(tryit_id(id)), n)
}

# The strings a Short Answer twin accepts for one numeric answer: the rounded
# value, its neighbours in the last decimal place where the tolerance allows
# them (0.0475 may be rounded to 0.047 or 0.048), and each of those without
# trailing zeros.
tryit_accepted <- function(a) {
  scale <- 10^a$digits
  nearest <- round(a$answer * scale)
  nearby <- nearest + c(0, -1, 1)
  nearby <- nearby[nearby == nearest | abs(nearby / scale - a$answer) <= a$tol + 1e-9]
  full <- formatC(nearby / scale, digits = a$digits, format = "f")
  trimmed <- if (a$digits > 0) sub("\\.$", "", sub("0+$", "", full)) else full
  unique(c(full, trimmed))
}

# Short Answer question for one numeric answer. Brightspace matches text, so
# the rounding is stated and the common ways of writing the value are accepted.
tryit_export_answer <- function(id, n, title, question, a) {
  accepted <- tryit_accepted(a)
  unit <- trimws(paste(a$prefix, a$suffix))
  text <- sprintf("%s<p><b>%s</b>: give your answer to %d decimal place%s%s. Enter the number only.</p>",
                  question, a$label, a$digits, if (a$digits == 1) "" else "s",
                  if (nzchar(unit)) sprintf(" (%s)", unit) else "")
  tryit_export(c(
    list(c("NewQuestion", "SA"),
         c("ID", tryit_qid(id, n)),
         c("Title", sprintf("%s - %s", title, a$label)),
         c("QuestionText", text, "HTML"),
         c("Points", "1"),
         c("Difficulty", "3"),
         c("InputBox", "1", "20")),
    lapply(accepted, function(x) c("Answer", "100", x)),
    if (!is.null(a$hint)) list(c("Hint", a$hint))
  ))
}

tryit_html_table <- function(header, rows) {
  cells <- function(x, tag) paste0("<", tag, ">", x, "</", tag, ">", collapse = "")
  paste0('<table border="1" cellpadding="4"><tr>', cells(header, "th"), "</tr>",
         paste0("<tr>", vapply(rows, cells, character(1), tag = "td"), "</tr>", collapse = ""),
         "</table>")
}

#---- tryit_number -------------------------------------------------------------

#' Numeric answers the student types in and checks
#'
#' Put the problem statement in the chapter text above the call, and the
#' worked solution in a `<details class="tryit-solution">` directly below it
#' (it unlocks after the first check).
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param answers A list of `tryit_answer()` calls, top to bottom.
#' @param intro Optional one-line instruction shown under the heading.
#' @param question The full problem statement as HTML. Supplying it exports a
#'   Brightspace twin (one Short Answer question per answer).
#' @param show `FALSE` exports the twin without showing the exercise.
tryit_number <- function(id, title, answers, intro = NULL, question = NULL, show = TRUE) {
  if (!is.null(question)) {
    for (i in seq_along(answers)) tryit_export_answer(id, i, title, question, answers[[i]])
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("number", id, list(title = title, intro = intro, answers = answers))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    tryit_print_answers(answers)
  }
}

#---- tryit_grid ---------------------------------------------------------------

#' A table with blank cells for the student to fill in
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param data The SOLVED table as a data frame -- the same object the chapter
#'   prints in its worked solution. Column names become the column headings.
#' @param blank Names of the (numeric) columns the student fills in. Every
#'   other column is shown as given.
#' @param tol Absolute tolerance for blank cells: one number, or a named
#'   vector with one entry per blank column.
#' @param hints Optional named character vector, one hint per blank column,
#'   shown under the table after a wrong entry in that column.
#' @param digits Decimal places for displaying given numeric columns.
#' @param answers Optional list of `tryit_answer()`s asked below the table
#'   (totals, averages, limits, ...).
#' @param intro,question,show As for `tryit_number()`. The twin is one Short
#'   Answer question per entry in `answers`, plus one Written Response
#'   question for the table itself.
tryit_grid <- function(id, title, data, blank, tol = 0.005, hints = NULL, digits = 2,
                       answers = list(), intro = NULL, question = NULL, show = TRUE) {
  stopifnot(is.data.frame(data), all(blank %in% names(data)))
  if (is.null(names(tol))) tol <- stats::setNames(rep(tol, length(blank)), blank)

  given <- function(x) if (is.numeric(x)) formatC(x, digits = digits, format = "f") else as.character(x)
  given_cols <- setdiff(names(data), blank)
  given_rows <- lapply(seq_len(nrow(data)), function(i) {
    vapply(given_cols, function(col) given(data[[col]][i]), character(1))
  })

  if (!is.null(question)) {
    stated <- paste0(question, tryit_html_table(given_cols, given_rows))
    solved <- lapply(seq_len(nrow(data)), function(i) {
      vapply(names(data), function(col) {
        if (col %in% blank) formatC(data[[col]][i], digits = tryit_digits(tol[[col]]), format = "f")
        else given(data[[col]][i])
      }, character(1))
    })
    tryit_export(list(
      c("NewQuestion", "WR"),
      c("ID", tryit_qid(id, 0)),
      c("Title", sprintf("%s - table", title)),
      c("QuestionText", sprintf("%s<p>For every row, calculate: <b>%s</b>. Show one sample calculation.</p>",
                                stated, paste(blank, collapse = ", ")), "HTML"),
      c("Points", as.character(length(blank))),
      c("Difficulty", "3"),
      c("AnswerKey", tryit_html_table(names(data), solved), "HTML")
    ))
    for (i in seq_along(answers)) tryit_export_answer(id, i, title, stated, answers[[i]])
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    columns <- lapply(names(data), function(col) {
      is_blank <- col %in% blank
      list(label = col, blank = is_blank,
           tol = if (is_blank) tol[[col]] else NULL,
           hint = if (is_blank && !is.null(hints) && col %in% names(hints)) hints[[col]] else NULL)
    })
    rows <- lapply(seq_len(nrow(data)), function(i) {
      lapply(names(data), function(col) {
        if (col %in% blank) data[[col]][i] else given(data[[col]][i])
      })
    })
    tryit_emit("grid", id, list(title = title, intro = intro, columns = columns,
                                rows = rows, answers = answers))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    sheet <- data
    for (col in names(sheet)) {
      sheet[[col]] <- if (col %in% blank) "" else given(data[[col]])
    }
    print(knitr::kable(sheet, align = "c"))
    cat("\n\n")
    tryit_print_answers(answers)
  }
}

#---- tryit_sort ---------------------------------------------------------------

#' Cards the student assigns to categories
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param bins Character vector of category names, in display order.
#' @param cards A data frame with columns `text` (the card), `bin` (its
#'   correct category, one of `bins`) and optionally `why` (a one-line
#'   explanation shown once the card has been checked).
#' @param intro,question,show As for `tryit_number()`. The twin is a single
#'   Matching question; `question` defaults to the intro.
#' @param print_key Print the answer key under the worksheet in PDF/EPUB.
tryit_sort <- function(id, title, bins, cards, intro = NULL, question = intro,
                       show = TRUE, print_key = TRUE) {
  stopifnot(is.data.frame(cards), all(c("text", "bin") %in% names(cards)),
            all(cards$bin %in% bins))
  has_why <- "why" %in% names(cards)

  if (!is.null(question)) {
    tryit_export(c(
      list(c("NewQuestion", "M"),
           c("ID", tryit_qid(id, 1)),
           c("Title", title),
           c("QuestionText", question, "HTML"),
           c("Points", as.character(nrow(cards))),
           c("Difficulty", "2"),
           c("Scoring", "EquallyWeighted")),
      lapply(seq_along(bins), function(i) c("Choice", as.character(i), bins[i])),
      lapply(seq_len(nrow(cards)), function(i) {
        c("Match", as.character(match(cards$bin[i], bins)), cards$text[i])
      })
    ))
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("sort", id, list(
      title = title, intro = intro, bins = as.list(bins),
      cards = lapply(seq_len(nrow(cards)), function(i) {
        list(text = cards$text[i], bin = match(cards$bin[i], bins) - 1,
             why = if (has_why) cards$why[i] else NULL)
      })
    ))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    cat(sprintf("Categories: %s\n\n", paste(bins, collapse = " / ")))
    cat(sprintf("%d. %s \\_\\_\\_\\_\\_\\_\\_\\_\n", seq_len(nrow(cards)), cards$text), sep = "")
    if (print_key) {
      cat(sprintf("\n*Answers: %s.*\n\n",
                  paste(sprintf("%d %s", seq_len(nrow(cards)), cards$bin), collapse = "; ")))
    }
  }
}

#---- tryit_order --------------------------------------------------------------

#' Steps the student puts in the right sequence
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param steps Character vector of steps IN THE CORRECT ORDER. The page
#'   shuffles them; the student moves each one up or down.
#' @param intro,question,show As for `tryit_number()`. The twin is a single
#'   Ordering question; `question` defaults to the intro.
#' @param print_key Print the answer key under the worksheet in PDF/EPUB.
tryit_order <- function(id, title, steps, intro = NULL, question = intro,
                        show = TRUE, print_key = TRUE) {
  stopifnot(is.character(steps), length(steps) >= 2, !anyDuplicated(steps))

  if (!is.null(question)) {
    tryit_export(c(
      list(c("NewQuestion", "O"),
           c("ID", tryit_qid(id, 1)),
           c("Title", title),
           c("QuestionText", question, "HTML"),
           c("Points", as.character(length(steps))),
           c("Difficulty", "2"),
           c("Scoring", "EquallyWeighted")),
      lapply(steps, function(step) c("Item", step, "NOT HTML"))
    ))
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("order", id, list(title = title, intro = intro, steps = as.list(steps)))
  } else {
    # Alphabetical rather than random, so printing never touches the
    # chapter's random-number stream.
    listed <- order(steps)
    cat(sprintf("\n\n**%s**\n\n", title))
    # The intro describes the on-screen buttons, so it is not printed.
    cat("Number these in the correct order:\n\n")
    cat(sprintf("- \\_\\_\\_\\_ %s\n", steps[listed]), sep = "")
    if (print_key) {
      cat(sprintf("\n*Answers, in the order listed: %s.*\n\n",
                  paste(listed, collapse = ", ")))
    }
  }
}

#---- tryit_diagram ------------------------------------------------------------

#' One box in a tryit_diagram()
#'
#' @param id Short unique id, used by `edges`.
#' @param label Heading of the box.
#' @param layer Which layer the box sits in, counting from 1. Layers run left
#'   to right (`direction = "right"`) or top to bottom (`direction = "down"`).
#' @param given Named vector/list of values shown as given, e.g.
#'   `c("C/T" = "40 s")`.
#' @param blank A list of `tryit_answer()`s the student fills in inside the
#'   box. Their labels are the field names.
#' @param sub Small line under the heading (e.g. "OR gate").
tryit_node <- function(id, label, layer, given = NULL, blank = list(), sub = NULL) {
  list(id = id, label = label, layer = layer, sub = sub,
       given = lapply(names(given), function(n) list(label = n, value = as.character(given[[n]]))),
       blank = blank)
}

#' Boxes joined by lines, with blank values for the student to fill in
#'
#' For a method that is worked on a diagram: a fault tree, a value stream
#' map, a network of activities.
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param nodes A list of `tryit_node()`s.
#' @param edges A list of `c(from, to)` id pairs. Lines are drawn from the
#'   earlier layer to the later one.
#' @param direction `"right"` (layers are columns) or `"down"` (layers are rows).
#' @param arrows Draw arrowheads (a flow) or plain lines (a tree).
#' @param answers Optional list of `tryit_answer()`s asked below the diagram.
#' @param intro,question,show As for `tryit_number()`. The twin is one Written
#'   Response question for the boxes plus a Short Answer per entry in `answers`.
tryit_diagram <- function(id, title, nodes, edges, direction = c("right", "down"),
                          arrows = TRUE, answers = list(), intro = NULL,
                          question = NULL, show = TRUE) {
  direction <- match.arg(direction)
  ids <- vapply(nodes, function(n) n$id, character(1))
  stopifnot(!anyDuplicated(ids), all(unlist(edges) %in% ids))

  # One row per box, for the print worksheet and the Brightspace twin.
  as_rows <- function(solved) {
    lapply(nodes, function(n) {
      givens <- vapply(n$given, function(g) sprintf("%s = %s", g$label, g$value), character(1))
      blanks <- vapply(n$blank, function(b) {
        sprintf("%s = %s", b$label,
                if (solved) trimws(paste(b$prefix, formatC(b$answer, digits = b$digits, format = "f"), b$suffix))
                else "______")
      }, character(1))
      feeds <- ids[vapply(ids, function(other) any(vapply(edges, function(e) e[1] == n$id && e[2] == other, logical(1))), logical(1))]
      c(paste0(n$label, if (!is.null(n$sub)) sprintf(" (%s)", n$sub) else ""),
        paste(c(givens, blanks), collapse = "; "),
        if (length(feeds)) paste(vapply(nodes[match(feeds, ids)], function(x) x$label, character(1)), collapse = ", ") else "-")
    })
  }
  header <- c("Box", "Values", if (arrows) "Leads to" else "Inputs from below")

  if (!is.null(question)) {
    stated <- paste0(question, tryit_html_table(header, as_rows(FALSE)))
    tryit_export(list(
      c("NewQuestion", "WR"),
      c("ID", tryit_qid(id, 0)),
      c("Title", sprintf("%s - diagram", title)),
      c("QuestionText", paste0(stated, "<p>Calculate every blank value. Show your working for one of them.</p>"), "HTML"),
      c("Points", as.character(max(1, sum(lengths(lapply(nodes, function(n) n$blank)))))),
      c("Difficulty", "3"),
      c("AnswerKey", tryit_html_table(header, as_rows(TRUE)), "HTML")
    ))
    for (i in seq_along(answers)) tryit_export_answer(id, i, title, stated, answers[[i]])
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("diagram", id, wide = TRUE, spec = list(
      title = title, intro = intro, direction = direction, arrows = arrows,
      nodes = lapply(nodes, function(n) {
        n
      }),
      edges = lapply(edges, function(e) I(as.character(e))), answers = answers))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    sheet <- as.data.frame(do.call(rbind, as_rows(FALSE)), stringsAsFactors = FALSE)
    names(sheet) <- header
    print(knitr::kable(sheet))
    cat("\n\n")
    tryit_print_answers(answers)
  }
}

#---- tryit_balance ------------------------------------------------------------

# Fewest stations that can hold the tasks without breaking precedence or the
# cycle time. `tasks` must be in an order where predecessors come first.
tryit_min_stations <- function(tasks, cycle) {
  n <- nrow(tasks)
  preds <- lapply(strsplit(tasks$pred, ","), function(p) match(trimws(p[nzchar(trimws(p))]), tasks$id))
  fits <- function(k) {
    place <- function(i, station, load) {
      if (i > n) return(TRUE)
      earliest <- max(1, station[preds[[i]]])
      for (s in seq(earliest, k)) {
        if (s > k) break
        if (load[s] + tasks$time[i] <= cycle + 1e-9) {
          station[i] <- s; load[s] <- load[s] + tasks$time[i]
          if (place(i + 1, station, load)) return(TRUE)
          load[s] <- load[s] - tasks$time[i]
        }
      }
      FALSE
    }
    place(1, integer(n), numeric(k))
  }
  k <- ceiling(sum(tasks$time) / cycle)
  while (!fits(k)) k <- k + 1
  k
}

#' Line balancing: assign tasks on a precedence diagram to stations
#'
#' There is no single answer key. The page checks that every task has a
#' station, that no task sits upstream of one of its predecessors, and that
#' no station exceeds the cycle time, then compares the number of stations
#' used with the fewest possible (found here by exhaustive search).
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param tasks Data frame with columns `id`, `label`, `time` and `pred`
#'   (comma-separated predecessor ids, "" for none), listed so that every
#'   task comes after its predecessors.
#' @param cycle Cycle time, in the same unit as `time`.
#' @param unit Unit label for times.
#' @param intro,question,show As for `tryit_number()`. The twin is a Written
#'   Response question.
tryit_balance <- function(id, title, tasks, cycle, unit = "s", intro = NULL,
                          question = NULL, show = TRUE) {
  stopifnot(is.data.frame(tasks), all(c("id", "label", "time", "pred") %in% names(tasks)),
            all(tasks$time <= cycle))
  preds <- lapply(strsplit(tasks$pred, ","), function(p) trimws(p[nzchar(trimws(p))]))
  for (i in seq_len(nrow(tasks))) stopifnot(all(preds[[i]] %in% tasks$id[seq_len(i - 1)]))

  # A task's layer is one more than the deepest of its predecessors.
  layer <- integer(nrow(tasks))
  for (i in seq_len(nrow(tasks))) {
    layer[i] <- if (length(preds[[i]])) max(layer[match(preds[[i]], tasks$id)]) + 1 else 1
  }
  best <- tryit_min_stations(tasks, cycle)
  rows <- lapply(seq_len(nrow(tasks)), function(i) {
    c(tasks$id[i], tasks$label[i], sprintf("%s %s", tasks$time[i], unit),
      if (length(preds[[i]])) paste(preds[[i]], collapse = ", ") else "-")
  })
  header <- c("Task", "Description", "Time", "Predecessors")

  if (!is.null(question)) {
    tryit_export(list(
      c("NewQuestion", "WR"),
      c("ID", tryit_qid(id, 1)),
      c("Title", title),
      c("QuestionText", paste0(question, tryit_html_table(header, rows), sprintf(
        "<p>Cycle time: %s %s. Assign every task to a station without breaking precedence or exceeding the cycle time, using as few stations as you can. List the tasks and total time at each station, and give the line efficiency.</p>",
        cycle, unit)), "HTML"),
      c("Points", "4"),
      c("Difficulty", "4"),
      c("AnswerKey", sprintf(
        "Fewest possible stations: %d. Efficiency at that number = %s / (%d x %s) = %.1f%%. Any assignment that respects precedence and the cycle time earns the method marks.",
        best, sum(tasks$time), best, cycle, sum(tasks$time) / (best * cycle) * 100))
    ))
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("balance", id, wide = TRUE, spec = list(
      title = title, intro = intro, cycle = cycle, unit = unit, best = best,
      stations = nrow(tasks),
      tasks = lapply(seq_len(nrow(tasks)), function(i) {
        list(id = tasks$id[i], label = tasks$label[i], time = tasks$time[i],
             pred = I(preds[[i]]), layer = layer[i])
      })))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    sheet <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
    names(sheet) <- header
    sheet$Station <- ""
    print(knitr::kable(sheet))
    cat(sprintf("\n\nCycle time: %s %s. Stations used: \\_\\_\\_\\_ Line efficiency: \\_\\_\\_\\_ %%\n\n", cycle, unit))
    cat(sprintf("*The fewest stations possible is %d.*\n\n", best))
  }
}

#---- tryit_layout -------------------------------------------------------------

# All orderings of 1..n (n is small: one per grid cell).
tryit_permutations <- function(n) {
  if (n == 1) return(matrix(1L, 1, 1))
  smaller <- tryit_permutations(n - 1)
  do.call(rbind, lapply(seq_len(n), function(i) {
    cbind(i, matrix(seq_len(n)[-i][smaller], nrow = nrow(smaller)))
  }))
}

#' Block plan: place departments on a grid for the lowest load-distance score
#'
#' The student puts one department in each cell. The page totals load x
#' rectilinear distance over every flow and compares the score with the best
#' possible (found here by trying every arrangement).
#'
#' @param id Unique within the chapter.
#' @param title Card heading.
#' @param departments Character vector, one per grid cell.
#' @param flows Data frame with columns `from`, `to` and `load`.
#' @param rows,cols Grid size; `rows * cols` must equal the number of
#'   departments (at most 8, to keep the search quick).
#' @param intro,question,show As for `tryit_number()`. The twin is a Written
#'   Response question.
tryit_layout <- function(id, title, departments, flows, rows = 2, cols = 3,
                         intro = NULL, question = NULL, show = TRUE) {
  n <- length(departments)
  stopifnot(n == rows * cols, n <= 8, is.data.frame(flows),
            all(c("from", "to", "load") %in% names(flows)),
            all(c(flows$from, flows$to) %in% departments))
  cell_row <- (seq_len(n) - 1) %/% cols
  cell_col <- (seq_len(n) - 1) %% cols
  from <- match(flows$from, departments)
  to <- match(flows$to, departments)
  # perms[p, d] = the cell that department d occupies in arrangement p
  perms <- tryit_permutations(n)
  scores <- vapply(seq_len(nrow(perms)), function(p) {
    cell <- perms[p, ]
    sum(flows$load * (abs(cell_row[cell[from]] - cell_row[cell[to]]) +
                        abs(cell_col[cell[from]] - cell_col[cell[to]])))
  }, numeric(1))
  best <- min(scores)

  flow_rows <- lapply(seq_len(nrow(flows)), function(i) c(flows$from[i], flows$to[i], as.character(flows$load[i])))
  header <- c("From", "To", "Loads per day")

  if (!is.null(question)) {
    tryit_export(list(
      c("NewQuestion", "WR"),
      c("ID", tryit_qid(id, 1)),
      c("Title", title),
      c("QuestionText", paste0(question, tryit_html_table(header, flow_rows), sprintf(
        "<p>Place the %d departments on a grid of %d rows by %d columns, one per cell. Distance between cells is rectilinear (rows apart plus columns apart). Sketch your layout and calculate its total load-distance score.</p>",
        n, rows, cols)), "HTML"),
      c("Points", "4"),
      c("Difficulty", "4"),
      c("AnswerKey", sprintf(
        "Lowest possible score: %s. Worst possible: %s. Award method marks for a correct calculation of the student's own layout, and full marks at or near the lowest score.",
        best, max(scores)))
    ))
  }
  if (!show) return(invisible(NULL))

  if (tryit_html()) {
    tryit_emit("layout", id, list(
      title = title, intro = intro, rows = rows, cols = cols, best = best, worst = max(scores),
      departments = as.list(departments),
      flows = lapply(seq_len(nrow(flows)), function(i) list(from = from[i] - 1, to = to[i] - 1, load = flows$load[i]))))
  } else {
    cat(sprintf("\n\n**%s**\n\n", title))
    if (!is.null(intro)) cat(intro, "\n\n")
    sheet <- as.data.frame(do.call(rbind, flow_rows), stringsAsFactors = FALSE)
    names(sheet) <- header
    sheet$Distance <- ""
    sheet$`Load x distance` <- ""
    print(knitr::kable(sheet))
    cat(sprintf("\n\nDepartments: %s. Place one in each cell of a %d x %d grid, then fill in the table. Total score: \\_\\_\\_\\_\\_\\_\n\n",
                paste(departments, collapse = ", "), rows, cols))
    cat(sprintf("*The lowest score possible is %s.*\n\n", best))
  }
}
