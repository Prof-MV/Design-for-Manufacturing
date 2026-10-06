// Shared runtime for "calculator style" webR cards.
//
// A calculator card is plain HTML emitted by the `qwebr_calc_card()` R
// helper (see R/helpers.R): a `.qwebr-calc-card` div carrying
// `data-qwebr-label="<chunk label>"`, with labelled `<input data-var="...">`
// fields/sliders, a `.qwebr-calc-results` area, and a `.qwebr-calc-graph`
// area. The webR source that actually computes the numbers is the chunk's
// own `{webr-r}` cell (looked up by label) — it stays visible to students,
// collapsed inside a `<details class="qwebr-calc-source">` right below the
// card. This file auto-discovers every calculator card on the page, and for
// each one:
//   1. finds the matching `{webr-r}` cell's source via `qwebrCellDetails`
//      (quarto-webr's own per-cell registry)
//   2. on any input change, substitutes the current input values into that
//      SAME source (so the card and the visible "show the code" panel never
//      drift apart — there's exactly one copy of the formula) and re-runs it
//      headlessly through the page's existing webR engine
//   3. paints the printed output + any plot into the card
//
// Output convention (keeps the R code plain and readable, no markers/JSON):
//   - the FIRST non-blank line printed by cat()/print() becomes the big
//     "headline" result
//   - every other printed line that has a label and a value separated by two
//     or more spaces (e.g. "  Tooling      $1.00", "  Efficiency  87.3%") is
//     shown as a right-aligned breakdown row; any line without that shape is
//     shown as plain text
//   - wrap a failing verdict in !!...!! (e.g. "Required capacity: 12 kg -
//     !!Exceeded!!", or a breakdown row "  Risk level   !!High!!") to render
//     it red instead of the default headline green / breakdown navy — a
//     passing verdict, or a line with no verdict at all, needs no markers
//   - any graphics device output becomes a canvas image under the card

(function (global) {
  "use strict";

  if (global.__qwebrCalcLoaded) return; // guard against duplicate <script src> tags
  global.__qwebrCalcLoaded = true;

  function escapeHtml(unsafe) {
    // Reuse the quarto-webr helper if present, else fall back locally.
    if (typeof global.qwebrEscapeHTMLCharacters === "function") {
      return global.qwebrEscapeHTMLCharacters(unsafe);
    }
    return String(unsafe)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function escapeRegExp(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Strips a !!...!! verdict marker out of a string, reporting whether one
  // was present. Only the marker characters are removed; the text inside
  // them is kept (unmarked) so it still reads normally once rendered red.
  function extractVerdict(str) {
    const match = str.match(/!!(.*?)!!/);
    if (!match) return { text: str, bad: false };
    return { text: str.replace(/!!(.*?)!!/g, "$1"), bad: true };
  }

  function renderText(container, text) {
    if (!container) return;

    const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);

    if (lines.length === 0) {
      container.innerHTML = "";
      return;
    }

    const [headlineRaw, ...rest] = lines;
    const headline = extractVerdict(headlineRaw);
    const headlineClass = "qwebr-calc-headline" + (headline.bad ? " qwebr-calc-bad" : "");
    let html = `<div class="${headlineClass}">${escapeHtml(headline.text)}</div>`;

    if (rest.length > 0) {
      html += '<ul class="qwebr-calc-breakdown">';
      rest.forEach((line) => {
        const match = line.match(/^(\S.*?)\s{2,}(\S.*)$/);
        if (match) {
          const value = extractVerdict(match[2]);
          const valueClass = "qwebr-calc-value" + (value.bad ? " qwebr-calc-bad" : "");
          html += `<li><span class="qwebr-calc-label">${escapeHtml(match[1].trim())}</span><span class="${valueClass}">${escapeHtml(value.text)}</span></li>`;
        } else {
          const plain = extractVerdict(line);
          html += plain.bad
            ? `<li class="qwebr-calc-bad">${escapeHtml(plain.text)}</li>`
            : `<li>${escapeHtml(plain.text)}</li>`;
        }
      });
      html += "</ul>";
    }

    container.innerHTML = html;
  }

  function renderImages(container, images) {
    if (!container) return;

    container.innerHTML = "";

    images.forEach((img) => {
      const canvas = document.createElement("canvas");
      canvas.width = img.width;
      canvas.height = img.height;

      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, 0, 0, img.width, img.height);

      container.appendChild(canvas);
    });
  }

  // Debounce helper: collapses rapid-fire slider "input" events into a
  // single webR evaluation after `wait` ms of quiet.
  function debounce(fn, wait) {
    let timer = null;
    return function (...args) {
      clearTimeout(timer);
      timer = setTimeout(() => fn.apply(this, args), wait);
    };
  }

  // webR evaluates one expression at a time on a single shared worker, so if
  // a card is still mid-run when the next slider tick fires, queue only the
  // *latest* pending request per card instead of letting two captureR()
  // calls race on the same session. Keyed by the card's own output element.
  const pendingByCard = new Map();
  const busyCards = new Set();

  async function runCalc(opts) {
    // opts: { outputEl, graphEl, code, figWidth=1200, figHeight=700 }
    if (!global.qwebrInstance) {
      console.warn("qwebr-calculator: quarto-webr is not present on this page.");
      return;
    }

    const key = opts.outputEl;
    if (busyCards.has(key)) {
      pendingByCard.set(key, opts);
      return;
    }

    busyCards.add(key);
    try {
      await executeCalc(opts);
    } finally {
      busyCards.delete(key);
    }

    const next = pendingByCard.get(key);
    if (next) {
      pendingByCard.delete(key);
      runCalc(next);
    }
  }

  // Run a chunk of R code headlessly through the already-initialized webR
  // engine that quarto-webr sets up for the page, and paint the results into
  // the given output/graph elements.
  async function executeCalc(opts) {
    await global.qwebrInstance; // wait for the shared webR engine to finish booting

    const figWidth = opts.figWidth || 1200;
    const figHeight = opts.figHeight || 700;

    const captureOptions = {
      withAutoprint: true,
      captureStreams: true,
      captureConditions: false,
    };

    if (typeof global.qwebrOffScreenCanvasSupport === "function" && global.qwebrOffScreenCanvasSupport()) {
      captureOptions.captureGraphics = {
        width: figWidth,
        height: figHeight,
        bg: "white",
        pointsize: 26,
        capture: true,
      };
    } else {
      captureOptions.captureGraphics = false;
    }

    const result = await global.mainWebRCodeShelter.captureR(opts.code, captureOptions);

    try {
      const text = result.output
        .filter((evt) => evt.type === "stdout")
        .map((evt) => evt.data)
        .join("\n");

      renderText(opts.outputEl, text);

      if (result.images && result.images.length > 0) {
        renderImages(opts.graphEl, result.images);
      }
    } finally {
      global.mainWebRCodeShelter.purge();
    }
  }

  // quarto-webr sets `window.qwebrInstance` from a <script type="module">
  // that the Lua filter appends at the end of <body> — which runs *after*
  // any calculator card embedded earlier in the chapter. Poll briefly
  // instead of checking it once synchronously.
  function whenReady(callback, attemptsLeft) {
    if (attemptsLeft === undefined) attemptsLeft = 100; // ~10s at 100ms
    if (global.qwebrInstance) {
      global.qwebrInstance.then(callback);
      return;
    }
    if (attemptsLeft <= 0) {
      console.warn("qwebr-calculator: window.qwebrInstance never appeared on this page.");
      return;
    }
    setTimeout(() => whenReady(callback, attemptsLeft - 1), 100);
  }

  // Substitute the current input values into the chunk's own source: replace
  // each input's R variable's assignment line (wherever it's first declared)
  // with the input's current value, leaving everything else — including
  // comments and the rest of the logic — untouched. Returns null (and warns)
  // if a variable can't be found, so a typo in `data-var` fails loudly
  // instead of silently running the unmodified default.
  function buildOverrideCode(baseCode, overrides) {
    let code = baseCode;
    let ok = true;

    overrides.forEach(({ varName, value }) => {
      const escaped = escapeRegExp(varName);
      const re = new RegExp("(^|\\n)(\\s*" + escaped + "\\s*(?:<-|=)\\s*)[^\\n]*");
      if (re.test(code)) {
        code = code.replace(re, `$1$2${value}`);
      } else {
        console.warn(`qwebr-calculator: variable "${varName}" not found as a top-level assignment in this cell — check the input's data-var attribute.`);
        ok = false;
      }
    });

    return ok ? code : null;
  }

  // Bind one calculator card: find its source cell, wire up its inputs, and
  // do an initial run once webR is ready.
  function bindCard(card) {
    if (card.dataset.qwebrBound === "true") return;
    card.dataset.qwebrBound = "true";

    const label = card.dataset.qwebrLabel;
    const cellDetails = global.qwebrCellDetails || [];
    const entry = cellDetails.find((e) => e.options && e.options.label === label);

    if (!entry) {
      console.warn(`qwebr-calculator: no {webr-r} cell found with label "${label}" for this card.`);
      return;
    }

    const outputEl = card.querySelector(".qwebr-calc-results");
    const graphEl = card.querySelector(".qwebr-calc-graph");
    const inputs = Array.from(card.querySelectorAll("[data-var]"));
    const figWidth = parseInt(card.dataset.figWidth, 10) || 1200;
    const figHeight = parseInt(card.dataset.figHeight, 10) || 700;

    function buildCode() {
      const overrides = [];
      for (const input of inputs) {
        const value = parseFloat(input.value);
        if (isNaN(value)) return null; // leave blank/invalid fields alone rather than guessing
        overrides.push({ varName: input.dataset.var, value });
      }
      return buildOverrideCode(entry.code, overrides);
    }

    const run = debounce(function () {
      const code = buildCode();
      if (!code) return;
      runCalc({ outputEl, graphEl, code, figWidth, figHeight });
    }, 200);

    inputs.forEach((input) => {
      input.addEventListener("input", function () {
        if (input.type === "range") {
          const readout = card.querySelector(`[data-readout-for="${input.id}"]`);
          if (readout) readout.textContent = Number(input.value).toLocaleString();
        }
        run();
      });
    });

    whenReady(run);
  }

  function autoInit() {
    document.querySelectorAll(".qwebr-calc-card[data-qwebr-label]").forEach(bindCard);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", autoInit);
  } else {
    autoInit();
  }

  global.qwebrCalc = {
    run: runCalc,
    debounce: debounce,
    whenReady: whenReady,
    bindCard: bindCard, // exposed in case a card is injected after DOMContentLoaded
  };
})(window);
