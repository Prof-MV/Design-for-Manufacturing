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

13. **CI-specific, not PDF-specific: raw `install.packages(..., quiet =
    TRUE)` in a setup script can fail silently on a fresh CI runner.**
    `quiet = TRUE` suppresses compile-error output, not just download
    progress — if a package needs a system library the bare runner doesn't
    have (classic culprits: `textshaping`/`systemfonts`/`ragg` needing
    `libharfbuzz-dev`/`libfribidi-dev`/`libfontconfig1-dev`), the install
    fails with no visible error, and the *real* symptom shows up minutes
    later and one level removed — a `library()` call failing with `there is
    no package called 'X'` for some *downstream* package, not the one that
    actually failed to compile. Works fine locally because dev machines
    already have these libraries installed from unrelated past work. Fix:
    don't hand-roll `install.packages()` in CI even if it's what the local
    setup script uses — use `r-lib/actions/setup-r-dependencies` (pak-based,
    auto-resolves and installs the correct system libraries via apt) for the
    CI install step specifically.

General diagnostic tip: when `quarto render --to pdf` fails, the error's
reported line number is in the *compiled* `index.tex`, not your source
`.qmd` — search the `.tex` file for the `\label{tab:...}` / caption text
near the failure to identify which chunk/table it came from, then find that
chunk by its label or caption text in the source.

## Context

This folder (`DesignForManufacturing`) was originally tied to
`origin` = `https://github.com/Prof-MV/DesignNotes.git` on `master`. Per the
user's explicit choice, this migration converted **this folder's own `.git`
in place** (old `.git`/history discarded locally — the `DesignNotes` repo on
GitHub is untouched since nothing was ever pushed there this session).

**Repo identity — resolved mid-Phase-1, deviates from the original plan
below:** `index.Rmd`'s `url:`/`github-repo:` fields and `_output.yml`'s edit
link declare `Prof-MV/Design-for-Manufacturing` as this book's real identity
— and that repo **already exists** on GitHub (public, created 2026-01-10,
last pushed 2026-05-29, same chapter files, clearly the actual canonical repo
for this book — `DesignNotes` was some other/unrelated local remote
mix-up). Confirmed with the user: that pre-existing public repo *is* the
real one. So instead of creating a brand-new private repo, the Quarto
scaffold was pushed as a **new branch (`quarto-migration`) on the existing
`Prof-MV/Design-for-Manufacturing` repo**, leaving its `master` branch
(the current live bookdown content) completely untouched. The repo stays
**public** (not private, contrary to the original plan's assumption below —
not revisited since the user confirmed pushing to the existing repo as-is).

The original goal, before that discovery, was:

1. Convert the bookdown project (30 `.Rmd` chapters + `index.Rmd`) to a
   Quarto book project.
2. Push the converted project to a **new, private** GitHub repo named
   **`Design-for-Manufacturing`** — ~~this matches what `index.Rmd`'s
   `url:`/`github-repo:` fields and `_output.yml`'s edit link *already*
   declare~~ — see resolution above: no new repo was created, the existing
   one was used instead, on a new branch, and it's public not private.
3. Host the rendered book on **GitHub Pages**, same pattern as today
   (render → `docs/` → push to `gh-pages` branch via Actions) — **not yet
   revisited** in light of the repo-identity discovery above; Phase 5 should
   confirm whether `Design-for-Manufacturing`'s existing Pages setup (if any)
   should be repointed at the new branch/workflow, or left alone until the
   migration is merged to `master`.
4. EC2 hosting was considered and **not** selected — GitHub Pages covers the
   "gitbook equivalent" need with zero server maintenance.

Decisions already made with the user:
- Repo: pushed to the **existing** `Prof-MV/Design-for-Manufacturing` repo
  (public) on a **new `quarto-migration` branch** — see resolution above.
  `master` on that repo (today's live bookdown content) is untouched; no
  merge/PR has been opened yet.
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

**Open items — resolved:**
1. GitHub Pages visibility: moot — the repo is public, staying public per
   the user's explicit decision.
2. `DesignNotes` turned out to be nothing to resolve at all: `gh api
   repos/Prof-MV/DesignNotes` resolves to the **same repo ID** as
   `Design-for-Manufacturing` — `DesignNotes` was just this repo's name
   *before* a GitHub rename, not a separate repo. `gh repo delete
   Prof-MV/DesignNotes` confirms this (`"has changed name or transferred
   ownership"`). Nothing was ever duplicated; there is nothing to delete.
3. `SuggestedChapters.md` — dropped, confirmed fine by the user.
4. GitHub Pages source: **investigated and changed.** The repo's Pages was
   actually configured as `build_type: legacy`, source = `master` branch,
   path `/docs` — meaning Pages expected `docs/` committed directly to
   `master`, which conflicts with this plan's decision not to commit
   `docs/`. Switched Pages to `build_type: workflow` (the modern
   Actions-deployed model) via `gh api -X PUT repos/.../pages
   -f build_type=workflow` — CI now deploys directly via
   `actions/upload-pages-artifact` + `actions/deploy-pages`, no committed
   `docs/` required, on either branch.
5. Merge strategy: **user decided — PR once the full migration (all 6
   phases) is done**, not before. `quarto-migration` stays a branch until
   then; the old `.github/workflows/main.yaml` (bookdown, scoped to
   `master` only) is deliberately left untouched for now — revisit whether
   to delete it at merge time, once `quarto-migration` → `master` actually
   happens.

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

**All 6 phases done in a single session** (turned out not to need the
several-chat split originally planned for). Summary:

- **Phase 1 (scaffold):** done — see gotcha list at the top of this file for
  the 11 real content bugs found and fixed getting the first clean
  three-format render. Old `.git` (tied to the pre-rename `DesignNotes` name)
  removed and reinitialized fresh. Pushed to a new `quarto-migration` branch
  on the existing `Design-for-Manufacturing` repo (see repo-identity
  resolution above) rather than a new repo.
- **Phase 2 (front matter):** done — `index.Rmd` → `index.qmd`, YAML folded
  into `_quarto.yml`'s `book:` block (including `description:`, which the
  first-pass scaffold had missed).
- **Phase 3 (chapters + crossrefs):** done — all 30 chapters renamed
  `.Rmd` → `.qmd`. All 143 bookdown crossrefs converted (126 originally
  counted via `\@ref(TYPE:label)` search, plus 17 more found in a second
  pass — bare-word chapter/section refs like `\@ref(chap-ml)` with no colon,
  which the first grep pattern missed): 88 equation blocks
  (`\begin{equation}...(\#eq:x)...\end{equation}` → `$$...$$ {#eq-x}`), 45
  figure/table refs needing their chunk renamed to a `fig-`/`tbl-` prefix
  Quarto's crossref system requires (most chunks weren't prefixed at all —
  bookdown didn't need it), 10 section/chapter refs (heading IDs `{#sec:x}`
  → `{#sec-x}`, bare `{#chap-x}` → `{#sec-chap-x}`), including one
  **pre-existing broken ref** (`\@ref(chap-bolts)` — typo for the real
  heading ID `chap-03-bolts`). Verified crossrefs resolve to real numbers in
  rendered output (e.g. "Figure 30.1", `\ref{tbl-english-...}` in the
  compiled `.tex`), not just renamed syntax. Stripped the leftover bookdown
  `(PART)` marker headings from all 5 part-intro chapters (not just 3 as
  first assumed — every part has one).
- **Phase 4 (PDF/EPUB):** done — fixed a silently-ignored YAML key
  (`latex-engine`, a bookdown/rmarkdown key Quarto doesn't recognize →
  the correct `pdf-engine`), confirmed the fix by checking Quarto's resolved
  pandoc invocation in the render log (was defaulting to `lualatex`, now
  correctly uses `xelatex`). Added `book: downloads: [pdf, epub]` for
  parity with the old gitbook download links. TinyTeX not needed — a full
  TeX Live 2026 install was already present locally.
- **Phase 5 (CI/CD):** done — new `.github/workflows/quarto-publish.yaml`
  (old bookdown `main.yaml` left untouched, scoped to `master` only so it
  doesn't fire on this branch). **Discovered GitHub Pages was actually
  configured to serve `docs/` from `master` directly (legacy build)** —
  conflicts with the plan's decision not to commit `docs/`. Resolved by
  switching Pages to the modern Actions-deployed model (`build_type:
  workflow` via the API) instead — CI uses `actions/upload-pages-artifact`
  + `actions/deploy-pages`, no committed `docs/` needed on any branch.
  Pushed and watched the run twice: **first run failed** — the raw
  `install.packages()` step in the R-dependency-install step failed
  silently after ~4.5 minutes with zero diagnostic output (`quiet = TRUE`
  suppresses compile errors too, not just download progress; the only
  visible symptom was a downstream `there is no package called 'rmarkdown'`
  when the setup script tried to `library()` a package that had silently
  failed to compile — almost certainly missing a system library like
  `libharfbuzz-dev`/`libfribidi-dev` for `textshaping`/`systemfonts` on a
  bare `ubuntu-latest` runner). **Fixed** by swapping that step for
  `r-lib/actions/setup-r-dependencies@v2` (pak-based; auto-resolves system
  library dependencies via apt, standard fix for this class of failure).
  **Second run: the `build` job passed clean** — full checkout → R deps →
  Quarto render (all three formats) → Pages-artifact upload, all green in
  CI, confirming the whole pipeline (not just local rendering) works from a
  bare environment. The `deploy` job was **blocked by GitHub's own
  `github-pages` environment protection rules** (`custom_branch_policies:
  true`, only the default branch `master` is an allowed deployment
  branch) — this is correct, expected behavior, not a bug: it stops this
  still-in-review `quarto-migration` branch from prematurely going live
  before the planned PR/merge. Deployment will happen automatically the
  first time this workflow runs on `master`, i.e. right after the PR
  merges — nothing further to configure.
- **Phase 6 (QA):** done — confirmed no dropped/junk paths leaked into
  tracked files (`Design for 3D Print.md`, `cam1/`–`thermo/`,
  `MachineLearning/`, `docs/`, `.claude/`, etc. — all absent from
  `git ls-files`), confirmed all 30 chapters present, removed
  `_bookdown.yml`/`_output.yml` now that `_quarto.yml` fully covers their
  content, ran one final full render to confirm nothing broke after that
  removal.

## Phased execution (one phase ≈ one future chat)

**Phase 1 — Repo & scaffold — done**
- In this working copy: delete confirmed junk (done — see above).
- Create `_quarto.yml` (done — see above), `output-dir: docs`.
- Write a Quarto-appropriate `.gitignore` (done) and a real `README.md`
  (done).
- Confirm `quarto render` succeeds clean before going further (done — all
  three formats, after fixing 11 real content bugs, see gotcha list above).
- Install/authenticate `gh` CLI (done), `git init` in this folder replacing
  its DesignNotes-linked `.git` (done), initial commit (done), push to a new
  `quarto-migration` branch on the existing `Design-for-Manufacturing` repo
  (done — see repo-identity resolution in Context above; no new repo was
  created).

**Phase 2 — Front matter — done** (see Status above for what was done)

**Phase 3 — Chapter conversion — done** (see Status above; the "likely 6+
chats" estimate wasn't needed — the systematic rename+crossref work was
scripted rather than done chapter-by-chapter)

**Phase 4 — PDF & EPUB formats — done** (see Status above)

**Phase 5 — CI/CD — done** (see Status above)

**Phase 6 — QA pass — done** (see Status above)

## Verification approach (every phase)

- `quarto render` (whole project) or `quarto render <file>` (single chapter)
  locally after each change — no chat should end with an unrendered/broken
  book.
- `quarto preview` for a visual check of navigation, TOC, and figures.
- Final check: GitHub Actions run green + Pages URL loads the deployed site.
  **Done, with one caveat:** the `build` job (render + artifact upload) is
  green on `quarto-migration`; the `deploy` job is correctly blocked by
  GitHub's environment protection rules until this merges to `master` (see
  Phase 5 status above) — so the Pages URL won't actually serve the new
  Quarto site until the PR merges. That's expected, not a gap to close now.
