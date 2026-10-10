# Helper functions for ENGR-3027 Process Engineering Book
# These functions provide conditional output for HTML vs PDF rendering

# ───────────────────────────────────────────────────────────────
# Global chart text scaling
# ───────────────────────────────────────────────────────────────
# Figures in this book are authored wide (fig.width ~9-12in) but displayed
# in a much narrower book column, so ggplot2's default text sizes look tiny
# once the browser scales the image down. diagram_text_scale is the single
# knob controlling all chart text; chunks multiply their geom_text()/
# geom_label()/annotate("text", ...)/element_text(size = ...) literals by
# it, and theme_minimal()/theme_void() below pick it up automatically.
diagram_text_scale <- 1.4

theme_minimal <- function(base_size = 11 * diagram_text_scale, ...) {
  ggplot2::theme_minimal(base_size = base_size, ...)
}

theme_void <- function(base_size = 11 * diagram_text_scale, ...) {
  ggplot2::theme_void(base_size = base_size, ...)
}

ggplot2::update_geom_defaults("text", list(size = 3.88 * diagram_text_scale))

#' Embed a YouTube video with conditional output
#'
#' In HTML output, displays a responsive iframe embed.
#' In PDF/LaTeX output, displays a formatted link to the video.
#'
#' @param video_id The YouTube video ID (e.g., "dQw4w9WgXcQ")
#' @param title The title to display (used in PDF link text)
#' @return NULL (outputs directly via cat)
#' @examples
#' embed_youtube("dQw4w9WgXcQ", "Example Video")
embed_youtube <- function(video_id, title = "Watch Video") {
  # Clean video ID (remove any URL parts if full URL passed)
  if (grepl("youtube.com|youtu.be", video_id)) {
    # Extract video ID from URL
    video_id <- gsub(".*(?:youtube\\.com/embed/|youtube\\.com/watch\\?v=|youtu\\.be/)([^&?/]+).*", "\\1", video_id)
  }

  if (knitr::is_html_output()) {
    # HTML output - responsive iframe
    cat(sprintf('
<div style="position: relative; padding-bottom: 56.25%%; height: 0; overflow: hidden; max-width: 100%%;">
  <iframe
    style="position: absolute; top: 0; left: 0; width: 100%%; height: 100%%;"
    src="https://www.youtube.com/embed/%s"
    title="%s"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    referrerpolicy="strict-origin-when-cross-origin"
    allowfullscreen>
  </iframe>
</div>
', video_id, title))
  } else {
    # PDF/LaTeX output - formatted link
    cat(sprintf('\n\n**%s:** [https://www.youtube.com/watch?v=%s](https://www.youtube.com/watch?v=%s)\n\n',
                title, video_id, video_id))
  }
}

#' Inject the bundled jQuery dependency for kableExtra's kePrint.js
#'
#' Quarto's Bootstrap 5 HTML theme dropped jQuery, but kableExtra's
#' kable_styling() still loads kePrint.js, which calls $(...) immediately.
#' Call this once per chapter, before any kable_styling() table, so the
#' jquery script tag is emitted ahead of kePrint.js in the rendered <head>.
#' knitr::is_html_output() also returns TRUE for epub (it's HTML-based
#' internally), but Quarto's epub writer rejects raw HTML dependencies, so
#' epub must be excluded explicitly.
inject_jquery <- function() {
  if (knitr::is_html_output(excludes = "epub")) {
    htmltools::tagList(rmarkdown::html_dependency_jquery())
  }
}

#' Create a styled info box with conditional output
#'
#' In HTML output, displays a colored box.
#' In PDF output, displays a simple formatted block.
#'
#' @param content The content to display
#' @param type The type of box: "info", "warning", "tip", "note"
#' @return NULL (outputs directly via cat)
info_box <- function(content, type = "info") {
  colors <- list(
    info = "#3498DB",
    warning = "#E74C3C",
    tip = "#2ECC71",
    note = "#F39C12"
  )

  icons <- list(
    info = "Info",
    warning = "Warning",
    tip = "Tip",
    note = "Note"
  )

  color <- colors[[type]]
  icon <- icons[[type]]

  if (knitr::is_html_output()) {
    cat(sprintf('
<div style="padding: 15px; margin: 10px 0; border-left: 5px solid %s; background-color: %s20;">
<strong>%s:</strong> %s
</div>
', color, color, icon, content))
  } else {
    cat(sprintf('\n\n**%s:** %s\n\n', icon, content))
  }
}

#' Escape LaTeX special characters in table cells without touching inline math
#'
#' Tables built with kable(..., escape = FALSE) (needed so genuine $...$ math
#' in a "Governing Equation" column renders correctly) leave every other
#' character in every other column raw too -- including plain-English rule-
#' of-thumb text that routinely contains %, _, ~, or ^ (e.g. "125%", "N_cr",
#' "~1 MHz"). In LaTeX, an unescaped % starts a comment that swallows the
#' rest of the line (including the row's \\\\ terminator), which corrupts or
#' outright breaks the table. This escapes everything in a string EXCEPT
#' any $...$ math spans, which are left untouched, so a single cell can
#' safely mix real LaTeX math with plain text. It's a no-op for HTML output.
#' @param x A character vector (typically one data.frame/tibble column).
tex_safe <- function(x) {
  if (!knitr::is_latex_output()) return(x)
  vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    maths <- regmatches(s, gregexpr("\\$[^$]*\\$", s))[[1]]
    if (length(maths) == 0) return(knitr:::escape_latex(s))
    tokens <- paste0("@@MATH", seq_along(maths), "@@")
    placeholder_s <- s
    for (i in seq_along(maths)) placeholder_s <- sub(maths[i], tokens[i], placeholder_s, fixed = TRUE)
    escaped <- knitr:::escape_latex(placeholder_s)
    for (i in seq_along(maths)) escaped <- sub(tokens[i], maths[i], escaped, fixed = TRUE)
    escaped
  }, character(1), USE.NAMES = FALSE)
}

#' One input field/slider for qwebr_calc_card()
#'
#' @param var The R variable name this input controls. Must match a
#'   `var <- value` (or `var = value`) assignment somewhere near the top of
#'   the paired `{webr-r}` cell's source — the calculator substitutes the
#'   input's current value into that exact line every time it re-runs the
#'   cell, so the card and the "show the code" panel never drift apart.
#' @param label Reader-facing label for the row.
#' @param value Default numeric value (should match the cell's own default).
#' @param min,max,step Passed straight through to the HTML `<input>`.
#' @param type `"number"` (a plain numeric field, optionally with a
#'   `prefix`/`suffix`) or `"slider"` (a `<input type="range">` with a live
#'   readout next to the label — use this for the one variable that's the
#'   "main" thing being explored, typically a volume/quantity/count).
#' @param prefix,suffix Optional short strings shown beside a `"number"`
#'   input, e.g. `prefix = "$"`, `suffix = "kg"`.
qwebr_calc_input <- function(var, label, value, min = NULL, max = NULL, step = NULL,
                              type = c("number", "slider"), prefix = "", suffix = "") {
  type <- match.arg(type)
  list(var = var, label = label, value = value, min = min, max = max, step = step,
       type = type, prefix = prefix, suffix = suffix)
}

#' Render an interactive "calculator" card in front of a {webr-r} cell
#'
#' Emits a styled card (see `style.css`, `.qwebr-calc-*` rules) with one row
#' per `input`, a results area, and a chart area. The card is wired up
#' entirely client-side by `js/qwebr-calculator.js`, which finds the
#' `{webr-r}` cell carrying `label` (via quarto-webr's own `qwebrCellDetails`
#' registry), substitutes the card's current input values into that cell's
#' *actual source*, and re-runs it headlessly through the page's existing
#' webR engine on every input change.
#'
#' Call this immediately before the `{webr-r}` cell it drives, then wrap that
#' cell in `<details class="qwebr-calc-source">` so curious students can
#' still open it, read it, edit it, and run it directly (see
#' 01-Types-of-Manufacturing.qmd, "Injection Molding", for the full
#' reference pattern — card, then collapsed source).
#'
#' Only produces output for HTML (webR doesn't run in PDF/EPUB); the
#' `{webr-r}` cell underneath already degrades to a plain static code block
#' there on its own, so nothing further is needed for those formats.
#'
#' @param label Must exactly match the `#| label:` of the `{webr-r}` cell
#'   this card drives.
#' @param title Card heading.
#' @param icon A Font Awesome solid-icon name, no prefix (e.g. `"gears"`,
#'   `"flask"`, `"bolt"`) — Font Awesome is already loaded on every page by
#'   quarto-webr itself.
#' @param inputs A list of `qwebr_calc_input()` calls, top to bottom.
#' @param fig_width,fig_height Pixel size for the captured plot (if the cell
#'   produces one); scales to fit the card via CSS either way.
#' @param goal Optional challenge shown under the results, e.g. "Get the cost
#'   per part below $4.00 without changing the equipment cost." Turns the
#'   card from "explore" into "solve".
#' @param goal_test An R expression (as a string) over the cell's own
#'   variables that is TRUE once the goal is reached, e.g.
#'   `"cost_per_part < 4"`. It is evaluated after the cell on every run. It
#'   must be FALSE at the default inputs, or there is nothing to solve.
#' @param rerun For a cell that simulates with random numbers: the name of
#'   the cell's seed variable (e.g. `"seed"`). The card gets a "Run again"
#'   button that moves that input on by one, so the student sees how much the
#'   result changes from run to run. The seed must also be one of `inputs`,
#'   and the cell must call `set.seed()` with it. In class, teams can each
#'   enter their team number as the run number to get different data.
qwebr_calc_card <- function(label, title, icon = "gears", inputs,
                             fig_width = 1200, fig_height = 700,
                             goal = NULL, goal_test = NULL, rerun = NULL) {
  if (!knitr::is_html_output(excludes = "epub")) return(invisible(NULL))

  sanitize <- function(x) gsub("[^a-zA-Z0-9]+", "-", x)
  card_id <- paste0("qcalc-", sanitize(label))

  render_input <- function(inp) {
    input_id <- paste0(card_id, "-", sanitize(inp$var))
    # Plain decimals, never scientific notation: a field showing "5e+06" is
    # unreadable, and "1e+05" is not something a student would type back in.
    plain <- function(x) format(x, scientific = FALSE, trim = TRUE)
    attrs <- sprintf(
      'id="%s" data-var="%s" value="%s"%s%s%s',
      input_id, inp$var, plain(inp$value),
      if (!is.null(inp$min)) sprintf(' min="%s"', plain(inp$min)) else "",
      if (!is.null(inp$max)) sprintf(' max="%s"', plain(inp$max)) else "",
      if (!is.null(inp$step)) sprintf(' step="%s"', plain(inp$step)) else ""
    )

    if (inp$type == "slider") {
      readout_id <- paste0(input_id, "-readout")
      sprintf('
    <div class="qwebr-calc-row qwebr-calc-row-slider">
      <label for="%s">%s <span class="qwebr-calc-slider-readout" data-readout-for="%s" id="%s">%s</span></label>
      <input type="range" class="qwebr-calc-slider" %s>
    </div>',
        input_id, inp$label, input_id, readout_id,
        format(inp$value, big.mark = " ", scientific = FALSE), attrs)
    } else {
      sprintf('
    <div class="qwebr-calc-row">
      <label for="%s">%s</label>
      <div class="qwebr-calc-field">
        %s<input type="number" %s>%s
      </div>
    </div>',
        input_id, inp$label,
        if (nzchar(inp$prefix)) sprintf('<span class="qwebr-calc-prefix">%s</span>\n        ', inp$prefix) else "",
        attrs,
        if (nzchar(inp$suffix)) sprintf('\n        <span class="qwebr-calc-suffix">%s</span>', inp$suffix) else "")
    }
  }

  input_rows <- paste(vapply(inputs, render_input, character(1)), collapse = "\n")

  rerun_row <- if (is.null(rerun)) "" else {
    stopifnot(rerun %in% vapply(inputs, function(inp) inp$var, character(1)))
    sprintf('
    <button type="button" class="qwebr-calc-rerun" data-seed-var="%s">Run again with new random numbers</button>', rerun)
  }

  stopifnot(is.null(goal) == is.null(goal_test))
  goal_row <- if (is.null(goal)) "" else sprintf('
  <div class="qwebr-calc-goal" data-goal-test="%s">
    <span><span class="qwebr-calc-goal-label">Challenge:</span> %s</span>
    <span class="qwebr-calc-goal-status" role="status" aria-live="polite"></span>
  </div>', htmltools::htmlEscape(goal_test, attribute = TRUE), goal)

  cat(sprintf('
```{=html}
<script src="js/qwebr-calculator.js"></script>

<div class="qwebr-calc-card" data-qwebr-label="%s" data-fig-width="%d" data-fig-height="%d">
  <div class="qwebr-calc-header">
    <i class="fa-solid fa-%s qwebr-calc-icon"></i>
    <h4>%s</h4>
  </div>
  <div class="qwebr-calc-inputs">%s%s
  </div>
  <div class="qwebr-calc-results"></div>%s
  <div class="qwebr-calc-graph"></div>
</div>
```
', label, fig_width, fig_height, icon, title, input_rows, rerun_row, goal_row))
}

# "Try it yourself" exercises: tryit_number(), tryit_grid(), tryit_sort(), ...
# Course code prefixes the exported Brightspace question IDs.
options(tryit.course = "ENGR-1025")
source("R/tryit.R")
