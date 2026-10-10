# Interactive exercises: audit and plan

Scope: this book (Design for Manufacturing, 47 chapters in 6 parts).
Reusable prompt: `../ProcessEngineering/INTERACTIVE-EXERCISES-PROMPT.md`.
Reference proposal: `../ProcessEngineering/INTERACTIVE-EXERCISES-PLAN.md`.

Status: **All phases built on branch `interactive-exercises`: 115 checked
exercises, 17 calculator challenges and 2 simulations across 41 chapters
(section 7).**

---

## 1. Where the book stands today

### How it is built

- Quarto book, `knitr` engine, `_quarto.yml`: HTML (cosmo + `style.css`), PDF
  (xelatex, `keep-tex`) and EPUB. `execute: freeze: auto`; **`_freeze/` is
  committed**, `docs/` is gitignored.
- Deployed by `.github/workflows/quarto-publish.yaml` (renders all three
  formats on push to `master`/`quarto-migration`, uploads `docs/` to Pages).
  The workflow installs R packages explicitly, so any new R dependency of the
  library must be added there as well as to `R/required_packages.R`.
- Every chapter sources `R/helpers.R` in a `setup-*` chunk, so `R/tryit.R` can
  be sourced from there once and needs no per-chapter setup.
- `README.md` still says chapters are `.Rmd`; they are `.qmd`. Not mine to fix
  unless you want it.

### Interactive machinery that exists

| Piece | Where | Notes |
|---|---|---|
| quarto-webr extension | `_extensions/coatless/webr` | Enabled per chapter by front matter (`filters: - webr`) |
| `qwebr_calc_card()` / `qwebr_calc_input()` | `R/helpers.R`, `js/qwebr-calculator.js`, `.qwebr-calc-*` in `style.css` | **Older version: no `goal`/`goal_test`, no `rerun`** |
| `tryit` library | **absent** | Must be copied from `../ProcessEngineering` (`R/tryit.R` 667 lines, `js/tryit.js` 771 lines, `.tryit-*` CSS) |
| Callout classes | `callout-think/check/industry/discussion/activity` | Quarto custom callouts |
| `.question` / `.answer` boxes | `style.css` | Used in Parts 2 and 3 |
| `<details>` reveals | Part 2 (some), Parts 3 and 6 | Part 6 uses them for every practice problem |

### Counts per chapter

| Chapter | webR cells | Calc cards | `<details>` | `.question` | Checked exercises |
|---|---|---|---|---|---|
| 01-00 to 01-05 (6 chapters) | 0 | 0 | 0 | 0 | 0 |
| 02-00 Machine Elements | 0 | 0 | 0 | 0 | 0 |
| 02-01 Bolt joints | 4 | 4 | 4 | 8 | 0 |
| 02-02 Gears | 0 | 0 | 8 | 0 | 0 |
| 02-03 Bearings | 0 | 0 | 0 | 8 | 0 |
| 02-04 Planar linkages | 0 | 0 | 0 | 10 | 0 |
| 02-05 Four-bar | 2 | 2 | 2 | 2 | 0 |
| 02-06 Cam-follower | 0 | 0 | 0 | 1 | 0 |
| 02-07 Belts | 0 | 0 | 4 | 0 | 0 |
| 02-08 Chains | 0 | 0 | 5 | 0 | 0 |
| 02-09 Couplings and clutches | 0 | 0 | 5 | 0 | 0 |
| 02-10 Drivetrains, 02-11 Brakes, 02-12 Thermo | 0 | 0 | 0 | 0 | 0 |
| 03-00 Intro | 0 | 0 | 0 | 0 | 0 |
| 03-01 Casting | 0 | 0 | 1 | 3 | 0 |
| 03-02 Joining | 0 | 0 | 0 | 3 | 0 |
| 03-03 Stamping | 0 | 0 | 11 | 0 | 0 |
| 03-04 Welding | 0 | 0 | 15 | 0 | 0 |
| 03-05 Machining | 0 | 0 | 0 | 6 | 0 |
| 03-06 3D printing | 0 | 0 | 0 | 0 | 0 |
| 03-07 Sintering | 0 | 0 | 0 | 3 | 0 |
| 04-01 ML, 04-02 ML lab | 0 | 0 | 0 | 2 / 0 | 0 |
| 05-01 FEA | 0 | 0 | 0 | 1 | 0 |
| 06-01 to 06-15 (15 chapters) | 4 to 8 each (85 total) | 2 to 8 each (69 total) | 15 to 26 each | 0 | 0 |

(`.question` counts include the matching `.answer` block.)

Four things stand out:

1. **Only 17 of 47 chapters load webR** (02-01, 02-05, 06-01 to 06-15). Parts
   1, 3, 4, 5 and most of Part 2 have no interactivity of any kind, so
   everything proposed for them must be plain JavaScript.
2. **Every interactive element is "change an input, watch the output".** There
   are no fill-in-and-check exercises anywhere.
3. **Practice problems are reveal-only.** Part 6 has 15 to 26 `<details>` per
   chapter, many of them plug-in problems with one right number. The
   cheapest path for a student is to open the reveal and nod.
4. **Part 6 follows a rigid template** (Scenario, Guidelines, Governing
   Calculation, Worked Example with a calculator card, then Practice Problems).
   That makes it the cheapest place to roll out at scale.

---

## 2. Widget types

Seven of your nine types cover this book. Existing `tryit` helpers are
reused as they are, so the interface stays identical across your books.

| Type | `tryit` helper | Used for here |
|---|---|---|
| check-number | `tryit_number()` | Single-answer and chained calculations, with fresh numbers |
| fill-grid | `tryit_grid()` | Limits tables, force/speed tables, power budgets, RMS torque, mesh convergence |
| sort-bins | `tryit_sort()` | Classification: defects, fits, processes, sensors, coupling types |
| order-steps | `tryit_order()` | Process sequences, analysis workflows |
| fill-diagram | `tryit_diagram()` | Gear-train speeds, thermal-resistance chain, power chain |
| challenge | `goal` / `goal_test` on `qwebr_calc_card()` | Drive an existing card to a stated goal |
| sandbox | `rerun` on `qwebr_calc_card()` | Tolerance stack-up Monte Carlo, bearing-life scatter |

Dropped for this book:

- **scorer.** Lookup methods here (service factor, derating, PLr) are one or
  two table lookups, so `tryit_number()` with one answer per step is enough,
  as in the Process Engineering book.
- **label-figure.** This book's figures are ggplot PNGs and photographs where
  mapping markers is fragile. If you want it for weld symbols or linkage
  schematics, it costs a new widget (see section 6).
- `tryit_balance()` and `tryit_layout()` come along in the copy but nothing in
  this book needs them.

### Design decisions that follow from this book

- **Where it is sourced.** `R/helpers.R` gets one `source("R/tryit.R")` at the
  bottom, guarded with `file.exists`. No chapter edits for setup.
- **Heading text.** "Try it yourself: ..." as in your other books. Heading
  level follows the chapter (Part 6 uses `##`, the rest `###`).
- **Part 6 `<details>` problems stay.** The checked exercise goes above the
  existing reveal; the reveal becomes the worked solution
  (`<details class="tryit-solution">` unlocks after the first check). Nothing
  existing is deleted.
- **Frozen output.** `_freeze/` is committed, so each chapter commit will also
  contain its `_freeze/<chapter>/` change. That is expected, not noise.

---

## 3. Ideas by chapter

Mode: **S** alone, **C** good on a projector. Effort: **S/M/L**.
Star marks the one I would build first. "Type" uses the section 2 names.

### Part 1: Design and Drafting (no webR; plain JS only)

| Chapter | Idea | Type | Mode | Effort |
|---|---|---|---|---|
| 01-00 Intro | None. Overview chapter with nothing to perform. | | | |
| 01-01 Drafting | ★ Scale and default-tolerance drill: given scale (2:1, 1:4, ...) and a measured drawing length, find the part length; given a 2- or 3-place dimension, state the default limits | number | S | S |
| | Title-block finder: 10 questions ("who approved it?", "which projection?") matched to fields | sort | S | S |
| 01-02 Dimensioning | ★ Rule violations: 10 dimensioning practices sorted into acceptable / violates a rule (each dimension once, not to hidden lines, ...) | sort | S, C | S |
| | Unit-conversion check (inch/mm) tied to the Mars Climate Orbiter example | number | S | S |
| 01-03 Tolerances | ★ Limits table: dimensions given as plus-minus, bilateral and unilateral; fill upper limit, lower limit and tolerance | grid | S | S |
| | Chain vs baseline dimensioning: accumulated tolerance on a feature at the end of a chain | number | S | S |
| 01-04 GD&T | ★ Bonus tolerance table: actual hole size to bonus to total positional tolerance, for 4 holes at MMC | grid | S, C | M |
| | Characteristic sorter: the 14 characteristics into form / orientation / location / runout, with "datum required?" | sort | S | S |
| | Stack-up sandbox: 5 parts drawn at random; worst-case vs statistical, share out of spec | sandbox | C | M |
| 01-05 Fits | ★ Fit calculator: hole and shaft limits to min/max clearance, then classify | grid + sort | S | M |
| | Fit sorter: 10 designations (H7/g6, H7/k6, H7/p6, ...) into clearance / transition / interference | sort | S, C | S |

### Part 2: Machine Elements

| Chapter | Idea | Type | Mode | Effort |
|---|---|---|---|---|
| 02-00 | None. Overview. | | | |
| 02-01 Bolts | ★ **Pilot.** Chain: torque to preload, to load share, to bolt force; one answer per step with fresh joint | number | S | S |
| | Safety-factor table: n_p, n_L, n_0 for four working loads | grid | S | S |
| | Challenge on `joint-working-load-interactive`: find the working load where the joint just separates | challenge | S, C | S |
| | Tightening methods: torque wrench / torque-angle / elongation / load-indicating washer matched to properties | sort | S | S |
| 02-02 Gears | ★ Compound train: speeds at each shaft of a 4-gear train and a planetary set | diagram | S, C | M |
| | Terminology: module and teeth to d, p, a, d_o (fresh values) | grid | S | S |
| | Planetary lookup: which member fixed gives which ratio | grid | S | S |
| | Gear-type sorter: application to spur / helical / bevel / worm / rack | sort | S | S |
| 02-03 Bearings | ★ L10 chain: C, P, n to L10 revolutions to hours | number | S | S |
| | Bushing PV table: P, V, PV vs limit, pass/fail, minimum length | grid | S | M |
| | Stribeck regimes: operating scenarios sorted into boundary / mixed / hydrodynamic | sort | S, C | S |
| | Fleet sandbox: 20 Weibull bearings; how many fail before L10 | sandbox | C | M |
| 02-04 Linkages | ★ Mobility table: counts of links and joints for 5 mechanisms to M (Gruebler), one with a compound joint | grid | S, C | S |
| | Joint sorter: lower / higher pair and DOF removed | sort | S | S |
| 02-05 Four-bar | ★ Challenge on `grashof-interactive`: change one link until a crank-rocker becomes a double-crank | challenge | S, C | S |
| | Grashof sorter: 8 link-length sets into crank-rocker / double-crank / rocker-crank / triple-rocker | sort | S | S |
| | Transmission angle at a given crank angle | number | S | S |
| 02-06 Cam | ★ Displacement table: rise h over beta; y at 5 cam angles for harmonic and cycloidal | grid | S | M |
| | Construction order: the six steps of the displacement diagram | order | S | S |
| | Motion-type sorter: which has an infinite-jerk spike, which is jerk-free | sort | S | S |
| 02-07 Belts | ★ Belt length and arc of contact table for 3 pulley pairs | grid | S | S |
| | Speed ratio, belt speed, power chain | number | S | S |
| | Belt-type sorter (V, timing, flat, poly-V) by application | sort | S | S |
| 02-08 Chains | ★ Chain length in pitches (round up to even) and chain speed | number | S | S |
| | Lubrication method vs chain speed: scenarios to manual / drip / bath / stream | sort | S | S |
| 02-09 Couplings | ★ Multi-plate clutch torque: number of friction surfaces (a common slip) | number | S | S |
| | Misalignment sorter: scenario to angular / parallel / axial and coupling type | sort | S, C | S |
| 02-10 Drivetrains | ★ Gear table: ratio x final drive x tire radius to wheel speed and engine rpm at 100 km/h | grid | S | M |
| | Layout sorter: statements to FWD / RWD / AWD | sort | S, C | S |
| 02-11 Brakes | ★ Shoe brake chain: F_N, torque, critical mu for self-locking (leading vs trailing) | number | S | M |
| | Stopping distance with a team seed (speed, mu, reaction time) | number | C | S |
| | ABS cycle: order the steps | order | S | S |
| 02-12 Thermo | ★ First-law table: Q, W, delta-U for four processes of one gas | grid | S | M |
| | Process sorter: descriptions to isothermal / isobaric / isochoric / adiabatic | sort | S, C | S |
| | Cycle efficiency: Otto and Carnot from compression ratio and temperatures | number | S | S |

### Part 3: Design for Manufacturing

| Chapter | Idea | Type | Mode | Effort |
|---|---|---|---|---|
| 03-00 Intro | ★ Process picker: 8 part descriptions to casting / stamping / machining / joining / additive / sintering | sort | S, C | S |
| 03-01 Casting | ★ Defect sorter: 10 defect descriptions to gas / shrinkage / mold / metallurgical | sort | S, C | S |
| | Draft allowance with fresh depth and rule | number | S | S |
| | Process choice: scenarios to sand / investment / lost-foam | sort | S | S |
| 03-02 Joining | ★ Method picker: scenarios to welding / brazing / soldering / adhesive / mechanical | sort | S, C | S |
| | Crossover: joining cost at volume with tooling; find the break-even count | number | S | S |
| 03-03 Stamping | ★ Hole and bend rules table from thickness t: min hole, spacing, edge distance, bend radius | grid | S | S |
| | Operation sorter: feature to blanking / punching / bending / drawing / coining | sort | S | S |
| | Progressive-die station order | order | S | S |
| 03-04 Welding | ★ Carbon equivalent and preheat decision for a fresh steel | number | S | S |
| | Fillet throat and throat shear stress | number | S | S |
| | Weld-defect sorter: cause to porosity / undercut / lack of fusion / ... | sort | S | S |
| 03-05 Machining | ★ Spindle speed and cutting time with fresh material and diameter | number | S, C | S |
| | Tolerance-cost table: feature tolerance to cost multiplier to total, and saving | grid | S | S |
| | Corner radius: tool diameter to minimum internal radius; feasible or not | sort | S | S |
| 03-06 3D printing | ★ Rule checker: 10 feature specs (wall, overhang, hole) to prints / needs support / will fail | sort | S, C | S |
| | Process matcher: FDM / SLA / SLS from requirements | sort | S | S |
| 03-07 Sintering | ★ Density table: %TD, porosity and oil content for 4 bushings | grid | S | S |
| | PM process order: blend, compact, sinter, size, impregnate | order | S | S |
| | Bearing sorter: oil-impregnated vs graphite by condition | sort | S | S |

### Parts 4 and 5

| Chapter | Idea | Type | Mode | Effort |
|---|---|---|---|---|
| 04-01 ML | ★ Leakage spotter: 8 train/test scenarios to leaks / sound | sort | S, C | S |
| | Confusion matrix: counts to precision, recall, F1 | grid | S | S |
| | X-bar/R limits from subgroup data | grid | S | M |
| 04-02 ML lab | None. It is a hands-on lab in R and Posit; a page widget adds nothing. | | | |
| 05-01 FEA | ★ Five-step workflow order | order | S | S |
| | Mesh convergence table: elements, stress, % change, converged? | grid | S, C | S |
| | Hand-calc check: sigma = Mc/I vs a FEA value; % error | number | S | S |
| | Singularity sorter: results to trust / do not trust | sort | S | S |

### Part 6: Electromechanical Design Challenges (webR, one template)

The same four kinds of exercise fit every chapter, so the table gives the
chapter-specific content only. Each practice problem keeps its reveal below.

| Chapter | Idea | Type | Mode | Effort |
|---|---|---|---|---|
| 06-00 | None. Overview. | | | |
| 06-01 Robot cell | ★ Challenge on `separation-distance-06-01`: stopping time at which a 600 mm guard distance still works | challenge | S, C | S |
| | Guard picker: fixed / interlocked / light curtain / scanner by scenario | sort | S | S |
| | Collaborative modes (ISO/TS 15066) by scenario | sort | S | S |
| 06-02 Safety circuits | ★ Required PL: scenarios (S, F, P) into PLa..PLe | sort | S, C | M |
| | Stop category 0 / 1 / 2 by scenario | sort | S | S |
| | Challenge on `stopping-time-06-02` | challenge | S | S |
| 06-03 Panel | ★ Challenge on `heat-load-06-03`: keep the panel under a limit with a given fan | challenge | S | S |
| | NEMA / IP picker: environment to enclosure type | sort | S | S |
| | Branch protection and SCCR: weakest-link lookup | number | S | S |
| 06-04 Wire | ★ Derating chain: base ampacity x temperature x bundling to allowed current | number | S | S |
| | Voltage drop pass/fail table for 4 runs | grid | S | S |
| | Fuse vs breaker sorter | sort | S | S |
| 06-05 Bonding | ★ "Four jobs" sorter: wiring practices to safety bonding / functional earth / shield / ... | sort | S, C | S |
| | Shield rule: one end vs both ends by scenario | sort | S | S |
| | Touch voltage: fault current x resistance | number | S | S |
| 06-06 Motor sizing | ★ RMS torque table: segments T, t to T^2 t to sum to T_rms | grid | S | S |
| | Reflected torque/speed chain through a gearbox | number | S | S |
| | Challenge on `reflected-inertia-06-06`: choose N so the ratio is 10:1 or under | challenge | S, C | S |
| | Servo vs VFD sorter | sort | S | S |
| 06-07 Pneumatic | ★ Bore sizing: force to area to bore to next standard size | number | S | S |
| | Air-consumption table for 4 cylinders | grid | S | S |
| | Challenge on `leak-cost-06-07` | challenge | S | S |
| 06-08 Linear motion | ★ Challenge on `selflock-06-08`: lead at which the screw self-locks | challenge | S, C | S |
| | Ball-screw critical speed and buckling: end-fixity factor lookup | number | S | S |
| | Selection sorter: lead screw / ball screw / belt / rack | sort | S | S |
| 06-09 Shaft | ★ Shaft diameter from torsional shear, rounded to a standard size | number | S | S |
| | Coupling picker: jaw / beam / disc / grid | sort | S | S |
| 06-10 Conveyor | ★ Belt pull chain: friction + incline + load | number | S | S |
| | Throughput table: speed, width, loading to t/h | grid | S | S |
| | Selection and food-industry construction sorters | sort | S | S |
| 06-11 Frame | ★ Challenge on `deflection-budget-06-11`: reach delta <= L/1000 by changing the section | challenge | S, C | S |
| | Natural-frequency separation check | number | S | S |
| | Extrusion vs welded steel sorter | sort | S | S |
| 06-12 Thermal | ★ Thermal-resistance chain: node temperatures (T_j, T_case, T_sink, T_amb) | diagram | S, C | M |
| | Required heatsink thermal resistance | number | S | S |
| | Fan airflow from power and temperature rise | number | S | S |
| 06-13 Power supply | ★ DC power budget table: load, duty, average W, total, supply size at 75% loading | grid | S | S |
| | Battery sizing chain (derating factors) | number | S | S |
| | Challenge on `battery-sizing-06-13` | challenge | S | S |
| 06-14 Sensors | ★ Sensing-distance derating table by target material | grid | S | S |
| | Sensor technology picker: inductive / capacitive / photoelectric / ultrasonic | sort | S, C | S |
| | 4-20 mA scaling and loop voltage budget | number | S | S |
| | PNP vs NPN picker | sort | S | S |
| 06-15 Capstone | ★ Which chapter owns it: 12 requirements sorted to subsystem | sort | S, C | S |
| | Challenge on `stopping-distance-06-15` | challenge | S | S |

Count: about 140 ideas; the build keeps three or four per chapter, so roughly
110 exercises across the 44 chapters that have one.

---

## 4. Build order

Each phase ends with something visible in a rendered chapter, and with a PDF
render once.

| Phase | Scope | Library work | You will see |
|---|---|---|---|
| **A: Pilot** | **02-01 Bolt joints** | Copy `R/tryit.R`, `js/tryit.js`, `.tryit-*` CSS from `../ProcessEngineering`. Port `goal`/`goal_test`/`rerun` to `qwebr_calc_card()` and `js/qwebr-calculator.js`. Add `quizzes/` export. Build number, grid, sort, challenge. | One chapter with 4 exercises, twins in `quizzes/tryit_02-01.csv` |
| B | Part 6, first half (06-01 to 06-08) | None expected (template is regular) | 8 chapters |
| C | Part 6, second half (06-09 to 06-15) | None | 7 chapters |
| D | Part 2 (02-02 to 02-12) | order, diagram (gear trains) | Machine elements |
| E | Parts 1 and 3 (no webR) | None; sorters and grids only | Drafting through sintering |
| F | Sandboxes (01-04, 02-03) and Parts 4, 5 | `rerun`, add `webr` filter to those two chapters | Simulations |

Why 02-01 for the pilot: it is the one chapter that already has calculator
cards, `.question` blocks and a reference worked example, so a single chapter
exercises number, grid, sort and challenge. Part 1 chapters would only test
the plain-JS path.

### Checks run on every chapter (automated once, in Phase A)

1. Headless DOM: feed each exercise its key (exact and rounded), require
   all-correct; one wrong answer must be flagged.
2. Each challenge: plain R with defaults must leave the goal unmet; one worked
   solution must meet it. Simulations: ten seeds.
3. One card of each new kind in a real browser.
4. Every answer in a checked review question recomputed from its givens and
   compared with the book's printed solution; differences are reported, not
   fixed.

---

## 5. Existing content that looks wrong

Left as it is. Found while reading for exercise material; each needs your
call.

| Where | Printed | What I get |
|---|---|---|
| 03-07 Sintering, Problem 3 | 150 g in the 25 mm x 15 mm compact gives 6.52 g/cm^3 (82.8% TD) | V = 7.36 cm^3, so 150 g gives **20.4 g/cm^3**, above theoretical density (7.87). 6.52 g/cm^3 would be about 48 g. |
| 03-05 Machining, Problem 3 | Relaxing feature C to +/-0.1 mm drops the total to $45 (57% saving) | Using the chapter's own multipliers: 10 + 25 + 25 = **$60** (43% saving). $45 needs feature C at 1x. |
| 03-03 Stamping, Problem 2 | Single-draw limit 40 mm from "drawing ratio of 2.0" and "50% of blank diameter" | Arithmetic is consistent, but the 40-50% rule is stated for depth vs blank diameter and the cup diameter is used as the starting point; worth checking the rule's source. |
| 01-04 GD&T, Exercise 1 | Position control drawn with the symbol ⊙ | In ASME Y14.5 the position symbol is ⌖; ⊙ is concentricity. Check the figure and the text agree. |
| 01-04 GD&T, Exercise 2 | "Four bolt holes arranged in a square (0° spacing)" | "0° spacing" does not describe a square pattern. |
| 02-11 Brakes, Problems 1 to 6 | No printed solutions | I will compute them when those exercises are built and report any disagreement with your own key. |

Everything else I recomputed while reading (gear train, planetary ratio, belt
length, welding throat, carbon equivalent, spindle speed, casting draft
arithmetic) agrees with the book. I did not recompute Part 6.

---

## 6. Decisions that are yours

1. **Pilot chapter.** 02-01 Bolt joints (recommended), or a no-webR chapter
   such as 03-05 Machining or 01-03 Tolerances to prove the plain-JS path
   first. 02-01 is the better test; the others are lower risk.
2. **Course code** for Brightspace question IDs. The folder path suggests
   `ENGR-1025`; Process Engineering uses its own. I will set
   `options(tryit.course = ...)` to whatever you give me.
3. **`quizzes/`.** It does not exist here and is not in `.gitignore`. In
   Process Engineering it is ignored. Recommend ignoring it here too (answer
   files are staged on FOL, not committed). Say if you want it committed.
4. **Existing quiz per chapter.** I could not find one in this repository, so
   twins will be a new `quizzes/tryit_<chapter>.csv` per chapter with no
   overlap check against the quiz you hold elsewhere.
5. **Scope.** Skip 04-02 (lab), 02-00 / 01-00 / 06-00 (overviews)? The plan
   assumes yes.
6. **Label-figure.** Worth a new widget for weld symbols (03-04) and linkage
   schematics (02-04)? It is the one type I dropped; my estimate is L effort
   for the widget, then S per use. Without it those two are sorters on text
   descriptions.
7. **Sandboxes in chapters without webR** (01-04, 02-03) need the `webr`
   front-matter filter, which adds the webR download to the page. Accept that,
   or keep those two as plain-JS number checks instead?
8. **Graded twins with different numbers.** Default is a second hidden copy
   (`show = FALSE`) with different numbers for every exercise a twin should
   count for marks. Confirm, or say which exercises are for practice only.
9. **Fixing the five items in section 5.** Do you want those corrected in the
   book, or left for you?

---

## 7. Decisions recorded and progress

Decisions (from you): pilot 02-01; course code `ENGR-1025`; `quizzes/`
gitignored; overlap with existing quizzes is fine; scope as proposed; no
label-figure widget; sandboxes in 01-04 and 02-03 may load webR; no
different-numbers hidden twins (the twin carries the full problem statement,
which you turn into a Brightspace Arithmetic question by hand); fix the
printed errors; commit and push to master when finished.

Library port: `R/tryit.R`, `js/tryit.js`, the `.tryit-*` section of
`style.css` and `js/qwebr-calculator.js` were copied unchanged from
`../ProcessEngineering`; `qwebr_calc_card()` in `R/helpers.R` is that book's
version (adds `goal`, `goal_test`, `rerun`); `R/helpers.R` sources
`R/tryit.R` and sets `options(tryit.course = "ENGR-1025")`. No widget type
was added and no library bug was found, so there is nothing to carry back.

### Built

| Phase | Chapters | Done |
|---|---|---|
| A pilot | 02-01 | yes |
| B | 06-01 to 06-08 | yes |
| C | 06-09 to 06-15 | yes |
| D | 02-02 to 02-12 | yes |
| E | 01-01 to 01-05, 03-00 to 03-07 | yes |
| F | 01-04 and 02-03 simulators, 04-01, 05-01 | yes |

Counts (from the sources): 115 `tryit_*` exercises, 19 `goal` challenges (17 on
existing calculators, 2 simulations with a run number and "Run again"),
267 graded-twin questions in `quizzes/tryit_<chapter>.csv` (gitignored).
Widget use: number 37, grid 28, sort 44, order 4, diagram 2.

### Not built, and why

- **Overview chapters** 01-00, 02-00, 06-00 and **04-02** (lab): nothing to
  perform, as agreed.
- **Simulations beyond the two built:** the ideas in sections 3 for
  tampering, push-vs-pull and similar belong to the Process Engineering book.
- **Scorer type:** folded into `tryit_number()` as planned.
- **Label-figure:** declined.
- **Brightspace twins for the two simulators:** a random run has no single
  right answer, so they have no twin.
- **Third and fourth ideas from section 3** that were not built to keep
  chapters at three or four exercises, for example the 06-01
  collaborative-mode sorter, the 06-02 stop-category sorter, the 06-03
  NEMA/IP picker and the 06-05 shield-rule sorter.

### Printed content issues

| Where | What | Action |
|---|---|---|
| 03-07 Sintering, Problem 3 | 150 g in the compact gives 20.4 g/cm^3 | **Fixed**: 48 g, so the stated 6.52 g/cm^3 and 82.8% hold |
| 03-05 Machining, Problem 3 | $45 / 57% saving | **Fixed**: $60 / 43% |
| 01-04 GD&T, Exercise 2 | "(0 degrees spacing)" | **Fixed**: removed |
| 03-03 Stamping, Problem 2 | Single-draw depth by the chapter's own 40 to 50% rule gives 40 mm; equal blank and cup area at a draw ratio of 2.0 gives about 30 mm | **Left**: consistent with the chapter's stated rule of thumb; the conclusion (not possible in one draw) is the same |
| 01-04 GD&T symbols | The book's tables use the same glyph for flatness and total runout, use the concentricity glyph for position, and show cylindricity as a circle | **Left**: changing them touches the figures and needs a PDF font check; recommend a separate pass |
| 02-09 Couplings, multi-plate clutch | "n = number of discs x 2" and then "a 5-disc pack has n = 8 (4 friction discs x 2)" | **Left**: the exercise states the count explicitly |
| 02-11 Brakes, Problems 1 to 6 | No printed solutions, so nothing to compare | None |
| Part 6 (all) | Not recomputed beyond the cells used by the exercises | None |

### Verification

Per chapter, in headless Chrome (puppeteer-core): every exercise accepts its
key (exact and rounded), flags one wrong answer and resets cleanly; every
challenge is unmet at the defaults and met after one worked solution, in
plain R (`challenge_check.R`) and in a real browser with webR; the simulators
were also checked over seeds 1 to 10, and the bearing fleet reaches its goal
from each starting seed within a few "Run again" presses. The print format
(PDF) was rendered at the end of phases A, B, C and F with no raw HTML.
The visual check in a browser is still yours.
