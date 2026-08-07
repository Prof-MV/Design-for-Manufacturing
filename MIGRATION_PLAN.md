# Bookdown → Quarto Migration Plan

## Reusable: kableExtra/LaTeX gotchas found converting to PDF format

These are **generic bookdown→Quarto PDF issues**, not specific to this book —
worth checking for in any other kableExtra-heavy R Markdown/bookdown project
being converted, since bookdown's `pdf_book` target is often left untested
(CI usually only builds the HTML/gitbook target, so these bugs go unnoticed
until someone actually renders to PDF for the first time). All are things
that render fine in HTML/gitbook but break or silently corrupt LaTeX/PDF
output. Diagnostic approach: Quarto book PDF output is always ONE merged
LaTeX document (`index.tex`/`index.pdf`) — you cannot render a single
chapter's PDF in isolation to speed up iteration, so budget for full-book
recompiles (a few minutes each) while chasing these. (Learned on the sister
ENGR-3027/Process-Engineering migration; this book's Phase 4 should check
for the same patterns — see the Phase 4 entry below for this book's own
occurrence counts.)

1. **`kable(format = "html", ...)` hardcoded.** Forces HTML table generation
   regardless of actual render target → PDF render fails outright with
   *"Functions that produce HTML output found in document targeting pdf
   output."* Fix: delete the hardcoded `format = "html", ` argument entirely
   and let knitr/kableExtra auto-detect the real output format (this is the
   default, correct, portable behavior — visible already in any chapters
   that never had the hardcoded argument in the first place).
2. **`kable_styling(..., full_width = TRUE, ...)`.** For LaTeX, `full_width`
   pushes kableExtra into an auto column-width-balancing engine
   (`tabu`/`longtabu`) that can overflow and abort compilation with
   *"Dimension too large... I can't work with sizes bigger than about 19
   feet"* on wide/text-heavy tables. Fix: make it format-aware —
   `full_width = knitr::is_html_output()` — so HTML keeps the original
   full-width behavior and PDF falls back to normal fixed-width tables.
3. **`column_spec(N, width = "18%")`.** CSS percentage widths are valid for
   HTML but not a valid LaTeX `p{}` dimension — produces malformed LaTeX
   (`p{18%}`) that can cascade into unrelated-looking errors much later in
   the document (e.g. *"Paragraph ended before ...LT@array was complete"*
   right after some *other* table). Fix: format-aware again —
   `width = if (knitr::is_html_output()) "18%" else NULL` (kableExtra treats
   `NULL` as "don't set a width," which is a safe LaTeX default).
4. **Literal special characters (`&`, likely also `%`/`#`/`_`/`$`) inside
   `caption = "..."` strings.** `kable()`'s default `escape = TRUE` escapes
   table *body* content automatically, but captions are passed to LaTeX
   verbatim — an un-escaped `&` produces *"Misplaced alignment tab
   character &."* Fix: format-aware escaping —
   `caption = if (knitr::is_latex_output()) "Gauge R\\&R" else "Gauge R&R"`
   (HTML/EPUB render literal `&` fine via pandoc's own text escaping, so only
   the LaTeX branch needs it).
5. **CSS/R named colors that aren't valid base `xcolor` names** (e.g.
   `"steelblue"`) passed to `row_spec()`/`column_spec(..., background = ...)`.
   Valid in HTML/CSS and even valid as an R/ggplot2 color name (so
   `geom_point(color = "steelblue")` in a *plot* is completely unaffected —
   only kableExtra *table* styling calls route through LaTeX's `xcolor`,
   which only recognizes ~19 base names). Fails with *"Undefined color
   `steelblue`."* Fix: swap in the hex equivalent (`"#4682B4"`) — works
   identically in both HTML and LaTeX, no conditional needed. Search
   specifically inside `row_spec(`/`column_spec(`/`cell_spec(` calls; don't
   flag every `color =`/`background =` in the file, since most hits will be
   unrelated ggplot2 aesthetics.

6. **`ggplotly(p)` (plotly-wrapped ggplot) with no format guard — and a
   `knitr::is_html_output()` subtlety that breaks EPUB specifically.**
   Plotly widgets are interactive HTML/JS only, so PDF fails outright with
   *"Functions that produce HTML output found in document targeting pdf
   output"* (found in this book's `03-05-Machining.Rmd`, `plot-defense`
   chunk — this class of bug isn't limited to tables). The obvious fix,
   `if (knitr::is_html_output()) plotly::ggplotly(p) else p`, fixes PDF but
   **still fails EPUB** with the same error, because `knitr::is_html_output()`
   treats `epub` as an HTML-family format by default (EPUB content is
   XHTML) — so the guard's "html" branch fires for EPUB too, and Quarto's
   EPUB writer rejects live JS widgets even though EPUB is technically
   HTML-based. Fix: exclude epub explicitly —
   `knitr::is_html_output(excludes = "epub")`. Any project mixing
   htmlwidgets (plotly, DT, leaflet, etc.) with an EPUB target should check
   for this — a guard that "works" because PDF renders clean can still be
   silently wrong for EPUB, since PDF and EPUB fail on different targets and
   Quarto book builds all formats in separate passes.

7. **SVG images need `rsvg-convert` on PATH for the PDF target** (Quarto's
   LaTeX filter auto-converts SVG → PDF via that external tool; it's not
   bundled with Quarto or TinyTeX). If it's missing, PDF rendering fails
   late — only at the very end, during the merged-document LaTeX filter
   pass, after every chapter has already knit successfully — with *"Could
   not convert a SVG to a PDF for output. Please ensure that rsvg-convert is
   available on the path."* Installing `rsvg-convert` itself may need admin
   rights (chocolatey's package failed here without an elevated shell).
   Simpler and more portable (no extra system dependency to also install in
   CI later): find the SVG(s) actually referenced via
   `knitr::include_graphics()` (`grep -rn '\.svg' *.Rmd`), convert each to
   PNG once with any available tool (Inkscape's CLI:
   `inkscape file.svg --export-type=png --export-width=1200
   --export-filename=file.png` worked here), and swap the `.Rmd` reference
   from `.svg` to `.png`. Only convert files that are actually referenced —
   grep the codebase first, since a repo can have unused/orphaned SVGs
   alongside the real ones (true here: one of two SVGs in `images/` wasn't
   referenced anywhere).

8. **Files with a `.png` extension that are actually WebP.** `file <path>`
   revealed 4 images in this book's `images/` folder were really
   `RIFF ... Web/P image` data saved with a `.png` extension (likely
   exported that way from a browser or screenshot tool at some point).
   Browsers and bookdown's gitbook HTML render these fine (browsers sniff
   real content type, ignore the extension), so this was invisible until
   PDF compilation — LuaLaTeX's PNG reader has no such leniency and fails
   deep in the LaTeX pass with a bare `libpng error: Not a PNG file` /
   `(readpng): internal error`, identifying the offending file only in the
   full `.log`, not in Quarto's own error output. Fix: re-save as real PNG
   (Python + Pillow handled it here — `Image.open(path); im.save(path,
   format="PNG")` — modern Pillow reads WebP out of the box). Check every
   image in the repo, not just ones already suspected, since the extension
   lies: `for f in images/*; do file "$f"; done | grep -v 'PNG image\|JPEG
   image\|SVG'`.

9. **Animated GIFs via `knitr::include_graphics()`.** Fine in HTML gitbook
   (animates in-browser); LaTeX's `graphicx` package has no GIF driver at
   all, so PDF fails outright with *"LaTeX Error: Unknown graphics
   extension: .gif."* — 5 occurrences in this book (4 in `02-02-Gears.Rmd`,
   1 in `02-10-Automotive-Drivetrains.Rmd`). Fix: same
   `knitr::is_html_output()` branch pattern — keep the animated `.gif` for
   HTML, extract a static first frame to `.png` for PDF/EPUB (Pillow:
   `Image.open(path); im.seek(0); im.convert("RGB").save(png_path)`).

10. **`\( ... \)` / `\[ ... \]` LaTeX-style math delimiters instead of
    `$ ... $` / `$$ ... $$`.** bookdown/rmarkdown's pandoc invocation
    apparently enables the `tex_math_single_backslash` extension (or is
    otherwise lenient); Quarto's default markdown parsing is not, so a
    lone `\[` gets read as an *escaped literal bracket character* instead of
    opening display math. Symptom is a LaTeX-stage (not knitr-stage)
    failure — `! Missing $ inserted.` pointing at `{[} N = ...` in the
    compiled `.tex`, i.e. the equation content is present but wrapped in
    literal-bracket escapes instead of math mode. Confirmed isolated to a
    single chapter here (`03-05-Machining.Rmd`, 7 occurrences) — the other
    18+ chapters in this book already use `$`/`$$` throughout, so the fix
    was just converting that one file's delimiters to match, rather than a
    global `_quarto.yml` extension change. Worth a repo-wide check either
    way (`grep -rl '\\\[' *.qmd` / `*.Rmd`) since a book that used
    backslash-delimiters *consistently* would be better served by adding
    `from: markdown+tex_math_single_backslash` under each `format:` entry in
    `_quarto.yml` instead of touching every equation.

11. **Unescaped `%` inside `\text{...}` in raw `$$...$$` math.** `\text{% TD}`
    (2 occurrences, `03-07-Sintering.Rmd`) — the bare `%` opens a LaTeX
    comment mid-expression, silently truncating everything after it on that
    line, including the closing `}` and `$$`. Symptom shows up *later*, not
    at the offending line: `Runaway argument? {\item ... \text {Porosity...`
    / `Paragraph ended before \text@ was complete`, pointing at the *next*
    `\text{}` use, because the corruption cascades forward until LaTeX
    resyncs. Fix: escape it, `\text{\% TD}`.
12. **`column_spec(N, width = "N%")` really is present in this book** —
    correcting an earlier false negative in this same list: an initial
    proactive grep for this pattern (gotcha #3 above) used a shell `grep`
    call with a `\s`-based regex that silently matched nothing due to
    shell/regex-engine quoting, and was wrongly read as "clean." A
    **second** pass using a proper tool-mediated regex search (not a shell
    pipe) found 4 real occurrences in `05-01-FEA-SolidWorks.Rmd`
    (`width = "8%"`, `"46%"` ×2, `"22%"`), which broke PDF compilation
    exactly as gotcha #3 predicted: `Runaway argument?
    {>{\raggedright\arraybackslash}p{8\caption{\label{tab:tab-schedul...`
    — the `%` in `p{8%}` was interpreted as a LaTeX comment character,
    same failure family as #11, just via a different source (kableExtra's
    own LaTeX generation this time, not hand-written `\text{}`). **Lesson:**
    don't trust a single grep pass as proof-of-absence for these gotchas,
    especially when run through a shell pipe with escaped regex — rerun
    with a different tool/method before concluding a pattern doesn't occur.

General diagnostic tip: when `quarto render --to pdf` fails, the error's
reported line number is in the *compiled* `index.tex`, not your source
`.qmd` — search the `.tex` file for the `\label{tab:...}` / caption text
near the failure to identify which chunk/table it came from, then find that
chunk by its label or caption text in the source.

## Context

This folder (`DesignForManufacturing`) is the **live** working directory for
the "Design for Manufacturing" bookdown textbook — it's currently tied to
`origin` = `https://github.com/Prof-MV/DesignNotes.git` on `master`, and
that repo's GitHub Pages (or a manually-configured Pages source pointing at
`docs/`) is presumably what students see today. This is different from the
sister ENGR-3027 migration, where the working folder was a throwaway copy of
a separate source-of-truth repo — here there is no separate source of truth.
Per the user's explicit choice, this migration converts **this folder's own
`.git` in place** (old `.git`/history discarded locally; the `DesignNotes`
repo on GitHub is untouched since nothing is force-pushed there).

The goal is to:

1. Convert the bookdown project (30 `.Rmd` chapters + `index.Rmd`) to a
   Quarto book project.
2. Push the converted project to a **new, private** GitHub repo named
   **`Design-for-Manufacturing`** — this matches what `index.Rmd`'s
   `url:`/`github-repo:` fields and `_output.yml`'s edit link *already*
   declare (both say `Prof-MV/Design-for-Manufacturing`, even though the
   actual remote today is `DesignNotes` — apparently a stale leftover from
   an earlier rename).
3. Host the rendered book on **GitHub Pages**, same pattern as today
   (render → `docs/` → push to `gh-pages` branch via Actions).
4. EC2 hosting was considered and **not** selected — GitHub Pages covers the
   "gitbook equivalent" need with zero server maintenance.

Decisions already made with the user:
- New repo: **`Design-for-Manufacturing`**, private, fresh git history,
  created by converting this folder's own `.git` in place (not a separate
  sibling folder).
- Keep all three output formats: HTML (Quarto book, replaces gitbook), PDF, EPUB.
- Keep the current `NN-MM-Name` chapter numbering/file scheme (e.g.
  `01-00-Design.Rmd`, `02-07-Belt-Pulley.Rmd`).
- **Drop from the new repo** (confirmed junk / orphaned material, not source
  content) — see "Known cleanup items" below.
- Native Quarto `part:` grouping is used for the three parts that already
  had a bookdown `# (PART) ... {-}` marker (`01-00-Design.Rmd`,
  `02-00-Machine-Elements.Rmd`, `03-00-Design-for-Manufacturing.Rmd` each
  combine a part marker *and* a real "Introduction to ..." chapter with
  substantial content in one file) — this is the faithful equivalent of
  what bookdown was already doing, not a novel structural change. Those
  three files stay as the **first regular chapter** inside their part's
  `chapters:` list (not repurposed as special part-landing files), so their
  content renders unchanged. The leftover literal `# (PART) ... {-}` heading
  text in each file is cosmetic-only for now (renders as a plain heading
  since Quarto doesn't parse bookdown's `(PART)` marker specially) —
  stripping that line is deferred to Phase 3 chapter conversion.
- Rewrite `README.md` — the original was the generic, never-customized
  bookdown template placeholder.
- `gh` CLI and Quarto CLI were **not** pre-installed in this environment
  (unlike the sister project) — both installed via `winget` in Phase 1
  (`gh` turned out to already be present but off `PATH`; `quarto` needed
  installing — correct winget id is `Posit.Quarto`, not
  `Posit-Software.Quarto`). `gh` was already authenticated as `Prof-MV`.

**Open items — flagged, not yet resolved:**
1. GitHub Pages sites built from a *private* repo are still publicly
   reachable at the Pages URL by default (only the source code stays
   private) unless the org is on GitHub Enterprise. Flag before Phase 5
   (CI/Pages setup) if that's not the intended visibility model.
2. The current `DesignNotes` repo's workflow pushes to a `gh-pages` branch
   via `peaceiris/actions-gh-pages`, but `git ls-remote` showed **no
   `gh-pages` branch** on that remote — only `master`, with `docs/`
   committed directly there. Either the workflow never successfully ran, or
   Pages is actually configured to serve `docs/` from `master`. This plan
   defaults to the same `gh-pages`-branch deploy pattern as the sister
   migration for the new repo; revisit in Phase 5 if the old Pages source
   turns out to be configured differently.
3. `SuggestedChapters.md` (chapter-roadmap note, mostly already implemented)
   was dropped per the plan's stated default — say so if you wanted it kept.

## Known cleanup items (confirmed junk, not source content) — done in Phase 1

- `Design for 3D Print.md` (3.2 MB) — pandoc-style scratch doc superseded by
  `03-06-Design-for-3D-printing.Rmd`.
- `test.html`, `sec` (0-byte stray file), `gitbook/` (empty dir).
- `.RData`, `.Rhistory`, `.Rproj.user/` — local R state, gitignored.
- `cam1/`, `cam2/`, `drTrain/`, `lec1/`–`lec4/`, `thermo/`,
  `MachineLearning/` — 449 tracked files, ~124 MB, confirmed via grep as
  **unreferenced by any `.Rmd` chapter** (unlike `images/`, used by 13
  chapters and kept). Orphaned pre-chapter source material.
- `docs/` (69 MB rendered output), `_bookdown_files/`, `_main_files/` —
  regeneratable build output; not committed, CI regenerates on push.
- `SuggestedChapters.md` — chapter-roadmap note, dropped (Open Item 3 above).
- Chapter cross-references: **126 `\@ref()` calls across 13 chapter files**
  (`01-03`, `01-04`, `01-05`, `02-01`, `02-03`, `02-04`, `02-06`, `02-10`,
  `02-11`, `03-02`, `03-04`, `04-01`, `04-02`, `05-01`) still need converting
  to Quarto's native crossref syntax in Phase 3 — far more volume than the
  sister project's two references; budget more chats, and do the heaviest
  files (`05-01-FEA-SolidWorks.Rmd`: 26, `03-04-Welding.Rmd`: 21,
  `02-04-Planar-Linkages.Rmd`: 18) as their own focused batches.
- `index.Rmd`'s `link-citations: yes` had to become `link-citations: true`
  just to get *any* render working — Quarto's YAML 1.2 parser rejects
  bookdown/YAML-1.1-style `yes`/`no` booleans outright. Watch for the same
  issue in other chapters' YAML if any carry per-chapter front matter.

## Status

- **Phase 1: in progress.** Junk/orphaned directories deleted (see above).
  `_quarto.yml` scaffold created (`book:` metadata mirrored from
  `index.Rmd`/`_output.yml`; chapters still reference the existing `.Rmd`
  files directly — renaming to `.qmd` deferred to Phase 3, same as the
  sister project). Quarto-appropriate `.gitignore` written (`_freeze/` is
  **not** ignored — same reasoning as the sister project: kableExtra/
  ggplot2-heavy chapters make committing the freeze cache worth it for CI
  speed). `README.md` rewritten with real content. `quarto`/`gh` CLI
  installed (see above). First full `quarto render` in progress to verify
  the scaffold before `git init`/repo creation — **not yet confirmed
  clean**; do not treat Phase 1 as done until that render finishes without
  errors.
- Not yet done: `git init` (this folder's existing `.git`/DesignNotes remote
  has not been touched yet), GitHub repo creation, push, renaming chapters
  to `.qmd`, converting `\@ref()` crossrefs, PDF/EPUB formats, CI workflow.
- `_bookdown.yml` / `_output.yml` intentionally **left in place** for now
  (not yet superseded — PDF/EPUB settings still need porting in Phase 4);
  remove them in Phase 6 once `_quarto.yml` fully covers their content.

## Phased execution (one phase ≈ one future chat)

**Phase 1 — Repo & scaffold**
- In this working copy: delete confirmed junk (done — see above).
- Create `_quarto.yml` (done — see above), `output-dir: docs`.
- Write a Quarto-appropriate `.gitignore` (done) and a real `README.md`
  (done).
- Confirm `quarto render` succeeds clean before going further.
- Install/authenticate `gh` CLI (done), `git init` in this folder (replacing
  its current DesignNotes-linked `.git`), initial commit, create the private
  `Design-for-Manufacturing` GitHub repo (`gh repo create`), push.

**Phase 2 — Front matter**
- Convert `index.Rmd` → `index.qmd`; move its YAML into `_quarto.yml`
  `book:`/`format:` blocks per Quarto book conventions.
- Migrate `R/helpers.R` and `R/required_packages.R` (used by all 30
  chapters' setup chunks); confirm they still work called from `.qmd`.
- Render just the front matter to confirm the scaffold works end-to-end.

**Phase 3 — Chapter conversion (likely 6+ chats, ~5 chapters each)**
- Rename `NN-MM-Name.Rmd` → `NN-MM-Name.qmd` (content mostly copies straight
  over — `fig.cap=`, `kableExtra`, `ggplot2` chunks all work unchanged under
  Quarto's knitr engine).
- Convert all 126 `\@ref()` bookdown cross-references (13 files, listed
  above) to Quarto's native `@fig-label`/`@eq-label`/`@tbl-label` crossref
  syntax, renaming referenced chunk labels to match as needed. Budget the
  bulk of this phase's time here; do the three heaviest files as their own
  batches (see above).
- Strip the leftover literal `# (PART) ... {-}` heading line from
  `01-00-Design.Rmd`, `02-00-Machine-Elements.Rmd`, and
  `03-00-Design-for-Manufacturing.Rmd` now that part grouping lives in
  `_quarto.yml`.
- Spot-render each converted chapter (`quarto render <file>.qmd`) before
  moving to the next batch.

**Phase 4 — PDF & EPUB formats**
- Port `_output.yml`'s `pdf_book`/`epub_book` settings into `_quarto.yml`
  `format: pdf:` / `format: epub:` (xelatex, natbib, `preamble.tex` include
  — currently just `\usepackage{booktabs}` — title-page/cover image).
- Confirm TinyTeX is available locally (`quarto install tinytex` if not),
  render full PDF + EPUB, compare against current output.
- **Check for the kableExtra/LaTeX gotchas listed at the top of this file**
  before assuming a clean HTML render means PDF will also be clean — this
  book has 26 chapters using `kable()`, 54+ `full_width` calls across 9
  files, and several `column_spec(..., width = "N%")` calls, all squarely in
  the danger zone the sister project hit (there it was 148 occurrences of
  hardcoded `format = "html"` across 10 chapters, 223 `full_width = TRUE`
  across 17 chapters, 121 CSS-percentage `column_spec` widths across 7
  chapters, 5 unescaped `&` in captions, and 1 non-standard color name).
  Grep for `format = "html"`, `full_width = TRUE`, `width = "..%"`, and
  non-hex color names inside `row_spec()`/`column_spec()`/`cell_spec()`
  calls proactively rather than waiting for the PDF render to fail.

**Phase 5 — CI/CD**
- New `.github/workflows/*.yml` using `quarto-dev/quarto-actions/setup` +
  `render`, then `peaceiris/actions-gh-pages` to deploy `docs/` → `gh-pages`
  branch (resolve Open Item 2 above first — confirm this is actually the
  intended Pages source before wiring it up).
- Push, verify the Actions run, confirm the Pages URL serves the new site.

**Phase 6 — QA pass**
- Full local render of all three formats; check every chapter's images,
  citations, and cross-references resolve; diff chapter list/structure
  against the original book; confirm nothing from the "drop" list leaked in.

## Verification approach (every phase)

- `quarto render` (whole project) or `quarto render <file>` (single chapter)
  locally after each change — no chat should end with an unrendered/broken
  book.
- `quarto preview` for a visual check of navigation, TOC, and figures.
- Final check: GitHub Actions run green + Pages URL loads the deployed site.
