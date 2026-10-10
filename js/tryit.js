// Shared runtime for "try it yourself" exercises.
//
// A tryit exercise is emitted by one of the `tryit_*()` R helpers (see
// R/tryit.R): a `.tryit` div carrying `data-tryit="<type>"` and a single
// <script type="application/json"> child holding the exercise, answer key
// included. This file auto-discovers every such div on the page and builds
// the widget inside it. Types:
//   number  one or more numeric answer fields, each marked against a tolerance
//   grid    a table whose blank cells the student fills in, marked per cell
//   sort    cards the student assigns to categories (click, not drag, so it
//           works by keyboard and on a touch screen)
//   order   steps the student moves up and down into the right sequence
//   diagram boxes joined by lines, with blank values to fill in
//   balance tasks on a precedence diagram, each assigned to a station; marked
//           against the rules (precedence, cycle time), not a single key
//   layout  departments placed on a grid, scored by load x distance
//
// Every widget has Check and Reset buttons, allows unlimited attempts, marks
// each item with a tick or cross as well as a colour, and shows a hint under
// a wrong item when the exercise supplies one.
//
// A `<details class="tryit-solution">` placed directly after an exercise is
// its worked solution: it stays locked until the student has checked at
// least one answer.
//
// No dependencies and no webR, so this works in any chapter.

(function (global) {
  "use strict";

  if (global.__tryitLoaded) return; // guard against duplicate <script src> tags
  global.__tryitLoaded = true;

  // Tiny element builder: el("div", {class: "x"}, [child, "text"])
  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([key, value]) => {
      if (value !== null && value !== undefined) node.setAttribute(key, value);
    });
    (children || []).forEach((child) => {
      if (child === null || child === undefined) return;
      node.appendChild(typeof child === "string" ? document.createTextNode(child) : child);
    });
    return node;
  }

  // Read what a student typed as a number. Accepts "12.5", "12,5", "1,250.5",
  // "$ 12.50" and "45 %"; returns null for a blank field and NaN for anything
  // that is not a number.
  function parseNumber(raw) {
    let text = String(raw).replace(/[\s$%]/g, "");
    if (text === "") return null;
    if (text.includes(",") && text.includes(".")) {
      text = text.replace(/,/g, "");
    } else {
      text = text.replace(",", ".");
    }
    return Number(text);
  }

  function isCorrect(value, spec) {
    if (value === null || isNaN(value)) return false;
    const error = Math.abs(value - spec.answer);
    if (error <= (spec.tol || 0) + 1e-9) return true;
    return spec.tolPct ? error <= Math.abs(spec.answer) * spec.tolPct / 100 + 1e-9 : false;
  }

  // One checkable numeric field. `wrap` is the element that carries the
  // right/wrong state (a table cell or an answer row).
  function numericField(spec, ariaLabel, wrap) {
    const input = el("input", { type: "text", inputmode: "decimal", autocomplete: "off", "aria-label": ariaLabel });
    const mark = el("span", { class: "tryit-mark", "aria-hidden": "true" });

    function clear() {
      wrap.classList.remove("tryit-ok", "tryit-no");
      mark.textContent = "";
      input.removeAttribute("aria-invalid");
    }

    input.addEventListener("input", clear); // an edited answer is unmarked until re-checked

    return {
      input,
      mark,
      // "blank" | "ok" | "no"
      check() {
        clear();
        const value = parseNumber(input.value);
        if (value === null) return "blank";
        const ok = isCorrect(value, spec);
        wrap.classList.add(ok ? "tryit-ok" : "tryit-no");
        mark.textContent = ok ? "✓" : "✗";
        if (!ok) input.setAttribute("aria-invalid", "true");
        return ok ? "ok" : "no";
      },
      reset() {
        input.value = "";
        clear();
      },
    };
  }

  // A labelled list of numeric answers (the whole of a "number" exercise,
  // and the part of a "grid" exercise that sits under the table).
  function answerList(answers) {
    const list = el("div", { class: "tryit-answers" });
    const fields = answers.map((spec) => {
      const row = el("div", { class: "tryit-answer" });
      const field = numericField(spec, spec.label, row);
      const hint = spec.hint ? el("div", { class: "tryit-hint", hidden: "" }, [spec.hint]) : null;
      row.appendChild(el("label", {}, [spec.label]));
      row.appendChild(el("div", { class: "tryit-field" }, [
        spec.prefix ? el("span", { class: "tryit-affix" }, [spec.prefix]) : null,
        field.input,
        spec.suffix ? el("span", { class: "tryit-affix" }, [spec.suffix]) : null,
        field.mark,
      ]));
      if (hint) row.appendChild(hint);
      list.appendChild(row);
      field.input.addEventListener("input", () => { if (hint) hint.hidden = true; });
      return {
        check() {
          const state = field.check();
          if (hint) hint.hidden = state !== "no";
          return state;
        },
        reset() {
          field.reset();
          if (hint) hint.hidden = true;
        },
      };
    });
    return { list, fields };
  }

  function summarise(states, noun) {
    const total = states.length;
    const right = states.filter((s) => s === "ok").length;
    const blank = states.filter((s) => s === "blank").length;
    const suffix = /right place$/.test(noun) ? "" : " correct";
    if (right === total) return `All ${total} ${noun}${suffix}.`;
    let text = `${right} of ${total} ${noun}${suffix}.`;
    if (blank > 0) text += ` ${blank} left blank.`;
    if (total - right - blank > 0) text += " Fix the ones marked ✗ and check again.";
    return text;
  }

  function buildNumber(spec, body) {
    const { list, fields } = answerList(spec.answers);
    body.appendChild(list);
    return {
      check() {
        const states = fields.map((f) => f.check());
        return { states, message: summarise(states, states.length === 1 ? "answer" : "answers") };
      },
      reset() { fields.forEach((f) => f.reset()); },
    };
  }

  function buildGrid(spec, body) {
    const cells = []; // { field, column }
    const head = el("tr", {}, spec.columns.map((col) => el("th", { scope: "col" }, [col.label])));
    const rows = spec.rows.map((row, r) => el("tr", {}, row.map((value, c) => {
      const col = spec.columns[c];
      if (!col.blank) return el("td", {}, [String(value)]);
      const td = el("td", { class: "tryit-cell" });
      const field = numericField({ answer: value, tol: col.tol }, `${col.label}, row ${r + 1}`, td);
      td.appendChild(field.input);
      td.appendChild(field.mark);
      cells.push({ field, column: c });
      return td;
    })));
    body.appendChild(el("div", { class: "tryit-scroll" }, [
      el("table", { class: "tryit-grid" }, [el("thead", {}, [head]), el("tbody", {}, rows)]),
    ]));

    // One hint line per blank column, shown once that column has a wrong cell.
    const hints = new Map();
    spec.columns.forEach((col, c) => {
      if (!col.hint) return;
      const hint = el("div", { class: "tryit-hint", hidden: "" }, [`${col.label}: ${col.hint}`]);
      hints.set(c, hint);
      body.appendChild(hint);
    });

    const below = answerList(spec.answers || []);
    if (below.fields.length > 0) body.appendChild(below.list);

    return {
      check() {
        const wrongColumns = new Set();
        const states = cells.map(({ field, column }) => {
          const state = field.check();
          if (state === "no") wrongColumns.add(column);
          return state;
        });
        hints.forEach((hint, column) => { hint.hidden = !wrongColumns.has(column); });
        below.fields.forEach((f) => states.push(f.check()));
        return { states, message: summarise(states, "entries") };
      },
      reset() {
        cells.forEach(({ field }) => field.reset());
        hints.forEach((hint) => { hint.hidden = true; });
        below.fields.forEach((f) => f.reset());
      },
    };
  }

  function shuffle(items) {
    const out = items.slice();
    for (let i = out.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
  }

  function buildSort(spec, body, id) {
    const list = el("ol", { class: "tryit-cards" });
    const cards = shuffle(spec.cards).map((card, i) => {
      const item = el("li", { class: "tryit-card" });
      const mark = el("span", { class: "tryit-mark", "aria-hidden": "true" });
      const why = card.why ? el("div", { class: "tryit-why", hidden: "" }, [card.why]) : null;
      const group = el("div", { class: "tryit-bins", role: "radiogroup", "aria-label": card.text });
      const radios = spec.bins.map((bin, b) => {
        const radio = el("input", { type: "radio", name: `${id}-card-${i}`, id: `${id}-card-${i}-bin-${b}`, value: String(b) });
        group.appendChild(radio);
        group.appendChild(el("label", { for: radio.id }, [bin]));
        return radio;
      });

      function clear() {
        item.classList.remove("tryit-ok", "tryit-no");
        mark.textContent = "";
        if (why) why.hidden = true;
      }
      radios.forEach((radio) => radio.addEventListener("change", clear));

      item.appendChild(el("div", { class: "tryit-card-text" }, [card.text, mark]));
      item.appendChild(group);
      if (why) item.appendChild(why);
      list.appendChild(item);

      return {
        check() {
          clear();
          const chosen = radios.find((radio) => radio.checked);
          if (!chosen) return "blank";
          const ok = Number(chosen.value) === card.bin;
          item.classList.add(ok ? "tryit-ok" : "tryit-no");
          mark.textContent = ok ? " ✓" : " ✗";
          // The explanation appears once the card is right, so it confirms
          // the reasoning without giving the answer away on a miss.
          if (why) why.hidden = !ok;
          return ok ? "ok" : "no";
        },
        reset() {
          radios.forEach((radio) => { radio.checked = false; });
          clear();
        },
      };
    });
    body.appendChild(list);

    return {
      check() {
        const states = cards.map((c) => c.check());
        return { states, message: summarise(states, "cards") };
      },
      reset() { cards.forEach((c) => c.reset()); },
    };
  }

  function buildOrder(spec, body) {
    const list = el("ol", { class: "tryit-steps" });
    const steps = spec.steps.map((text, position) => {
      const item = el("li", { class: "tryit-step" });
      const mark = el("span", { class: "tryit-mark", "aria-hidden": "true" });
      const up = el("button", { type: "button", class: "tryit-move", "aria-label": `Move up: ${text}` }, ["▲"]);
      const down = el("button", { type: "button", class: "tryit-move", "aria-label": `Move down: ${text}` }, ["▼"]);
      item.appendChild(el("span", { class: "tryit-step-moves" }, [up, down]));
      item.appendChild(el("span", { class: "tryit-step-text" }, [text]));
      item.appendChild(mark);
      return { item, mark, up, down, position };
    });

    function clear() {
      steps.forEach(({ item, mark }) => {
        item.classList.remove("tryit-ok", "tryit-no");
        mark.textContent = "";
      });
    }

    function move(step, direction, button) {
      const neighbour = direction < 0 ? step.item.previousElementSibling : step.item.nextElementSibling;
      if (!neighbour) return;
      if (direction < 0) list.insertBefore(step.item, neighbour);
      else list.insertBefore(neighbour, step.item);
      clear();
      button.focus(); // moving the node drops focus; keep it for repeated presses
    }

    steps.forEach((step) => {
      step.up.addEventListener("click", () => move(step, -1, step.up));
      step.down.addEventListener("click", () => move(step, 1, step.down));
    });

    // Start from a shuffle that is not already the right answer.
    function scramble() {
      let mixed;
      do {
        mixed = shuffle(steps);
      } while (mixed.every((step, i) => step.position === i));
      mixed.forEach((step) => list.appendChild(step.item));
      clear();
    }
    scramble();
    body.appendChild(list);

    return {
      check() {
        const shown = Array.from(list.children);
        const states = steps.map((step) => {
          const ok = shown.indexOf(step.item) === step.position;
          step.item.classList.add(ok ? "tryit-ok" : "tryit-no");
          step.mark.textContent = ok ? "✓" : "✗";
          return ok ? "ok" : "no";
        });
        return { states, message: summarise(states, "steps in the right place") };
      },
      reset: scramble,
    };
  }

  // Shared drawing for the diagram-style exercises. `nodes` are
  // { id, layer, box } with `box` an element; `edges` are [fromId, toId].
  // Boxes are laid out in layers (columns when direction is "right", rows
  // when it is "down") and the joining lines are drawn on an SVG underneath,
  // re-measured whenever the layout can have changed.
  function drawDiagram(nodes, edges, direction, arrows) {
    const SVG = "http://www.w3.org/2000/svg";
    const scroll = el("div", { class: "tryit-scroll" });
    const canvas = el("div", { class: `tryit-diagram tryit-diagram-${direction}` });
    const svg = document.createElementNS(SVG, "svg");
    svg.setAttribute("class", "tryit-diagram-lines");
    svg.setAttribute("aria-hidden", "true");
    canvas.appendChild(svg);

    const layers = new Map();
    nodes.forEach((node) => {
      if (!layers.has(node.layer)) layers.set(node.layer, el("div", { class: "tryit-diagram-layer" }));
      layers.get(node.layer).appendChild(node.box);
    });
    Array.from(layers.keys()).sort((a, b) => a - b).forEach((key) => canvas.appendChild(layers.get(key)));
    scroll.appendChild(canvas);
    const scrollNote = el("p", { class: "tryit-scroll-note", hidden: "" }, ["Scroll sideways to see the whole diagram."]);
    const wrapper = el("div", {}, [scroll, scrollNote]);

    const byId = new Map(nodes.map((node) => [node.id, node.box]));

    function redraw() {
      scrollNote.hidden = scroll.scrollWidth <= scroll.clientWidth + 1;
      const frame = canvas.getBoundingClientRect();
      svg.setAttribute("width", canvas.scrollWidth);
      svg.setAttribute("height", canvas.scrollHeight);
      while (svg.firstChild) svg.removeChild(svg.firstChild);
      edges.forEach(([fromId, toId]) => {
        const a = byId.get(fromId).getBoundingClientRect();
        const b = byId.get(toId).getBoundingClientRect();
        const line = document.createElementNS(SVG, "line");
        let x1, y1, x2, y2;
        if (direction === "right") {
          x1 = a.right; y1 = a.top + a.height / 2; x2 = b.left; y2 = b.top + b.height / 2;
        } else {
          x1 = a.left + a.width / 2; y1 = a.bottom; x2 = b.left + b.width / 2; y2 = b.top;
        }
        line.setAttribute("x1", x1 - frame.left);
        line.setAttribute("y1", y1 - frame.top);
        line.setAttribute("x2", x2 - frame.left);
        line.setAttribute("y2", y2 - frame.top);
        svg.appendChild(line);
        if (!arrows) return;
        // Arrowhead drawn by hand: SVG markers need document-unique ids.
        const angle = Math.atan2(y2 - y1, x2 - x1);
        const tip = [x2 - frame.left, y2 - frame.top];
        const head = document.createElementNS(SVG, "polygon");
        head.setAttribute("points", [0, 2.6, -2.6].map((spread, i) => {
          if (i === 0) return tip.join(",");
          const back = angle + Math.PI - spread / 6;
          return [tip[0] + 9 * Math.cos(back), tip[1] + 9 * Math.sin(back)].join(",");
        }).join(" "));
        svg.appendChild(head);
      });
    }

    global.addEventListener("resize", redraw);
    global.addEventListener("load", redraw);
    if (typeof global.ResizeObserver === "function") new global.ResizeObserver(redraw).observe(canvas);
    setTimeout(redraw, 0);

    return { element: wrapper, redraw };
  }

  function buildDiagram(spec, body) {
    const fields = [];
    const nodes = spec.nodes.map((node) => {
      const box = el("div", { class: "tryit-node" }, [
        el("div", { class: "tryit-node-title" }, [node.label]),
        node.sub ? el("div", { class: "tryit-node-sub" }, [node.sub]) : null,
      ]);
      node.given.forEach((given) => {
        box.appendChild(el("div", { class: "tryit-node-field" }, [
          el("span", { class: "tryit-node-label" }, [given.label]),
          el("span", { class: "tryit-node-value" }, [given.value]),
        ]));
      });
      node.blank.forEach((blank) => {
        const row = el("div", { class: "tryit-node-field" });
        const field = numericField(blank, `${blank.label} for ${node.label}`, row);
        row.appendChild(el("span", { class: "tryit-node-label" }, [blank.label]));
        row.appendChild(el("span", { class: "tryit-node-entry" }, [
          blank.prefix ? el("span", { class: "tryit-affix" }, [blank.prefix]) : null,
          field.input,
          blank.suffix ? el("span", { class: "tryit-affix" }, [blank.suffix]) : null,
          field.mark,
        ]));
        box.appendChild(row);
        const hint = blank.hint ? el("div", { class: "tryit-hint", hidden: "" }, [`${node.label}: ${blank.hint}`]) : null;
        fields.push({ field, hint });
      });
      return { id: node.id, layer: node.layer, box };
    });

    const diagram = drawDiagram(nodes, spec.edges, spec.direction, spec.arrows);
    body.appendChild(diagram.element);
    fields.forEach(({ hint }) => { if (hint) body.appendChild(hint); });

    const below = answerList(spec.answers || []);
    if (below.fields.length > 0) body.appendChild(below.list);

    return {
      check() {
        const states = fields.map(({ field, hint }) => {
          const state = field.check();
          if (hint) hint.hidden = state !== "no";
          return state;
        });
        below.fields.forEach((f) => states.push(f.check()));
        diagram.redraw(); // hints change the height of the card
        return { states, message: summarise(states, "entries") };
      },
      reset() {
        fields.forEach(({ field, hint }) => { field.reset(); if (hint) hint.hidden = true; });
        below.fields.forEach((f) => f.reset());
      },
    };
  }

  function buildBalance(spec, body, id) {
    const total = spec.tasks.reduce((sum, task) => sum + task.time, 0);
    const tasks = spec.tasks.map((task) => {
      const select = el("select", { "aria-label": `Station for task ${task.id}` }, [el("option", { value: "" }, ["Station…"])]);
      for (let s = 1; s <= spec.stations; s++) select.appendChild(el("option", { value: String(s) }, [`Station ${s}`]));
      const mark = el("span", { class: "tryit-mark", "aria-hidden": "true" });
      const box = el("div", { class: "tryit-node" }, [
        el("div", { class: "tryit-node-title" }, [`${task.id} · ${task.time} ${spec.unit}`, mark]),
        el("div", { class: "tryit-node-sub" }, [task.label]),
        select,
      ]);
      return Object.assign({ select, mark, box }, task);
    });
    const byId = new Map(tasks.map((task) => [task.id, task]));
    const edges = [];
    tasks.forEach((task) => task.pred.forEach((pred) => edges.push([pred, task.id])));

    body.appendChild(el("p", { class: "tryit-intro" }, [
      `Cycle time: ${spec.cycle} ${spec.unit}. Total work content: ${total} ${spec.unit}.`,
    ]));
    const diagram = drawDiagram(tasks, edges, "right", true);
    body.appendChild(diagram.element);

    const tbody = el("tbody");
    const summary = el("p", { class: "tryit-live" });
    body.appendChild(el("div", { class: "tryit-scroll" }, [
      el("table", { class: "tryit-grid tryit-stations" }, [
        el("thead", {}, [el("tr", {}, ["Station", "Tasks", "Time", "Idle"].map((h) => el("th", { scope: "col" }, [h])))]),
        tbody,
      ]),
    ]));
    body.appendChild(summary);

    const stationOf = (task) => (task.select.value === "" ? null : Number(task.select.value));

    function loads() {
      const byStation = new Map();
      tasks.forEach((task) => {
        const s = stationOf(task);
        if (s === null) return;
        if (!byStation.has(s)) byStation.set(s, []);
        byStation.get(s).push(task);
      });
      return Array.from(byStation.entries()).sort((a, b) => a[0] - b[0]).map(([station, members]) => ({
        station, members, time: members.reduce((sum, task) => sum + task.time, 0),
      }));
    }

    function clearMarks() {
      tasks.forEach((task) => {
        task.box.classList.remove("tryit-ok", "tryit-no");
        task.mark.textContent = "";
      });
    }

    // The station table and efficiency update as the student assigns tasks,
    // so overloading a station is visible before they press Check.
    function refresh() {
      const current = loads();
      tbody.innerHTML = "";
      current.forEach(({ station, members, time }) => {
        const over = time > spec.cycle;
        tbody.appendChild(el("tr", { class: over ? "tryit-over" : null }, [
          el("td", {}, [String(station)]),
          el("td", {}, [members.map((task) => task.id).join(", ")]),
          el("td", {}, [`${time} ${spec.unit}`]),
          el("td", {}, [over ? `over by ${time - spec.cycle} ${spec.unit}` : `${spec.cycle - time} ${spec.unit}`]),
        ]));
      });
      if (current.length === 0) {
        tbody.appendChild(el("tr", {}, [el("td", { colspan: "4" }, ["No tasks assigned yet."])]));
        summary.textContent = "";
        return;
      }
      const efficiency = total / (current.length * spec.cycle) * 100;
      const unassigned = tasks.filter((task) => stationOf(task) === null).length;
      summary.textContent = unassigned > 0
        ? `${unassigned} task${unassigned === 1 ? "" : "s"} still to assign.`
        : `Stations used: ${current.length}. Line efficiency: ${efficiency.toFixed(1)}%. Balance delay: ${(100 - efficiency).toFixed(1)}%.`;
    }

    tasks.forEach((task) => task.select.addEventListener("change", () => { clearMarks(); refresh(); }));
    refresh();

    return {
      check() {
        clearMarks();
        const problems = [];
        const bad = new Set();
        const unassigned = tasks.filter((task) => stationOf(task) === null);
        if (unassigned.length === tasks.length) return { states: tasks.map(() => "blank"), message: "" };

        tasks.forEach((task) => task.pred.forEach((predId) => {
          const pred = byId.get(predId);
          if (stationOf(task) === null || stationOf(pred) === null) return;
          if (stationOf(pred) > stationOf(task)) {
            problems.push(`Task ${task.id} is at an earlier station than its predecessor ${pred.id}.`);
            bad.add(task.id);
          }
        }));
        const current = loads();
        current.filter(({ time }) => time > spec.cycle).forEach(({ station, members, time }) => {
          problems.push(`Station ${station} holds ${time} ${spec.unit}, more than the cycle time.`);
          members.forEach((task) => bad.add(task.id));
        });
        // Station numbers must be used in order, with no gaps.
        if (current.some(({ station }, i) => station !== i + 1)) {
          problems.push("Number the stations 1, 2, 3… with no gaps.");
        }

        const states = tasks.map((task) => {
          if (stationOf(task) === null) return "blank";
          const ok = !bad.has(task.id);
          task.box.classList.add(ok ? "tryit-ok" : "tryit-no");
          task.mark.textContent = ok ? " ✓" : " ✗";
          return ok ? "ok" : "no";
        });

        let message;
        if (unassigned.length > 0) {
          message = `${unassigned.length} task${unassigned.length === 1 ? "" : "s"} still to assign. ${problems.join(" ")}`;
        } else if (problems.length > 0) {
          message = problems.join(" ");
          if (!states.includes("no")) states[0] = "no"; // a gap in numbering is still not a finished answer
        } else if (current.length === spec.best) {
          message = `A valid balance with ${current.length} stations, the fewest possible.`;
        } else {
          message = `A valid balance with ${current.length} stations. It can be done with ${spec.best}: look for stations with idle time you could fill.`;
          states.push("no"); // valid, but not yet the best: do not show it as finished
        }
        return { states, message };
      },
      reset() {
        tasks.forEach((task) => { task.select.value = ""; });
        clearMarks();
        refresh();
      },
    };
  }

  function buildLayout(spec, body) {
    const n = spec.departments.length;
    const cells = [];
    const grid = el("div", { class: "tryit-plan", style: `grid-template-columns: repeat(${spec.cols}, minmax(7.5em, 1fr));` });
    for (let i = 0; i < n; i++) {
      const select = el("select", { "aria-label": `Department in row ${Math.floor(i / spec.cols) + 1}, column ${(i % spec.cols) + 1}` },
        [el("option", { value: "" }, ["Choose…"])]);
      spec.departments.forEach((name, d) => select.appendChild(el("option", { value: String(d) }, [name])));
      cells.push(select);
      grid.appendChild(el("div", { class: "tryit-plan-cell" }, [select]));
    }
    body.appendChild(el("div", { class: "tryit-scroll" }, [grid]));

    const flowRows = spec.flows.map((flow) => {
      const distance = el("td");
      const product = el("td");
      const row = el("tr", {}, [
        el("td", {}, [spec.departments[flow.from]]),
        el("td", {}, [spec.departments[flow.to]]),
        el("td", {}, [String(flow.load)]),
        distance,
        product,
      ]);
      return { flow, distance, product, row };
    });
    const total = el("td", { class: "tryit-plan-total" });
    body.appendChild(el("div", { class: "tryit-scroll" }, [
      el("table", { class: "tryit-grid" }, [
        el("thead", {}, [el("tr", {}, ["From", "To", "Loads/day", "Distance", "Load × dist."].map((h) => el("th", { scope: "col" }, [h])))]),
        el("tbody", {}, flowRows.map((f) => f.row)),
        el("tfoot", {}, [el("tr", {}, [el("th", { colspan: "4", scope: "row" }, ["Total score"]), total])]),
      ]),
    ]));

    // cellOf[d] = index of the cell holding department d, or undefined
    function placement() {
      const cellOf = [];
      cells.forEach((select, i) => { if (select.value !== "") cellOf[Number(select.value)] = i; });
      return cellOf;
    }

    function refresh() {
      const cellOf = placement();
      let score = 0;
      let complete = true;
      flowRows.forEach(({ flow, distance, product }) => {
        const a = cellOf[flow.from];
        const b = cellOf[flow.to];
        if (a === undefined || b === undefined) {
          distance.textContent = "–";
          product.textContent = "–";
          complete = false;
          return;
        }
        const d = Math.abs(Math.floor(a / spec.cols) - Math.floor(b / spec.cols)) + Math.abs((a % spec.cols) - (b % spec.cols));
        distance.textContent = String(d);
        product.textContent = String(d * flow.load);
        score += d * flow.load;
      });
      complete = complete && cells.every((select) => select.value !== "");
      total.textContent = complete ? String(score) : "–";
      return complete ? score : null;
    }

    cells.forEach((select) => select.addEventListener("change", () => {
      // A department can only be in one place: choosing it here clears it elsewhere.
      cells.forEach((other) => { if (other !== select && other.value === select.value) other.value = ""; });
      refresh();
    }));
    refresh();

    return {
      check() {
        if (cells.every((select) => select.value === "")) return { states: ["blank"], message: "" };
        const score = refresh();
        if (score === null) return { states: ["no"], message: "Place every department before checking." };
        if (score === spec.best) return { states: ["ok"], message: `Score ${score}: the lowest possible. No arrangement beats this.` };
        const above = Math.round((score / spec.best - 1) * 100);
        return {
          states: ["no"],
          message: `Score ${score}. The lowest possible is ${spec.best}, so this is ${above}% above the best layout. Which heavy flow still travels more than one cell?`,
        };
      },
      reset() {
        cells.forEach((select) => { select.value = ""; });
        refresh();
      },
    };
  }

  const builders = {
    number: buildNumber, grid: buildGrid, sort: buildSort, order: buildOrder,
    diagram: buildDiagram, balance: buildBalance, layout: buildLayout,
  };

  // The worked solution, if the chapter put one directly after the exercise.
  function findSolution(root) {
    // A wide exercise sits inside a Quarto column wrapper; look past it.
    const outer = root.parentElement && root.parentElement.matches('[class*="column-"]') ? root.parentElement : root;
    let next = outer.nextElementSibling;
    while (next && next.tagName === "SCRIPT") next = next.nextElementSibling;
    return next && next.matches("details.tryit-solution") ? next : null;
  }

  function init(root) {
    if (root.dataset.tryitBound === "true") return;
    root.dataset.tryitBound = "true";

    const source = root.querySelector('script[type="application/json"]');
    const build = builders[root.dataset.tryit];
    if (!source || !build) {
      console.warn(`tryit: cannot build exercise "${root.id}" (type "${root.dataset.tryit}").`);
      return;
    }
    const spec = JSON.parse(source.textContent);

    root.appendChild(el("div", { class: "tryit-header" }, [
      el("span", { class: "tryit-badge" }, ["Try it"]),
      el("h4", {}, [spec.title]),
    ]));
    if (spec.intro) root.appendChild(el("p", { class: "tryit-intro" }, [spec.intro]));

    const body = el("div", { class: "tryit-body" });
    root.appendChild(body);
    const widget = build(spec, body, root.id);

    const feedback = el("div", { class: "tryit-feedback", role: "status", "aria-live": "polite" });
    const checkButton = el("button", { type: "button", class: "tryit-btn" }, ["Check my answers"]);
    const resetButton = el("button", { type: "button", class: "tryit-btn tryit-btn-secondary" }, ["Reset"]);
    root.appendChild(el("div", { class: "tryit-controls" }, [checkButton, resetButton]));
    root.appendChild(feedback);

    const solution = findSolution(root);
    if (solution) {
      solution.classList.add("tryit-locked");
      solution.querySelector("summary").addEventListener("click", (event) => {
        if (!solution.classList.contains("tryit-locked")) return;
        event.preventDefault();
        feedback.textContent = "Check at least one answer first — then the worked solution unlocks.";
      });
    }

    checkButton.addEventListener("click", () => {
      const { states, message } = widget.check();
      const attempted = states.some((s) => s !== "blank");
      feedback.textContent = attempted ? message : "Nothing entered yet.";
      feedback.classList.toggle("tryit-all-ok", states.every((s) => s === "ok"));
      if (attempted && solution) solution.classList.remove("tryit-locked");
    });

    resetButton.addEventListener("click", () => {
      widget.reset();
      feedback.textContent = "";
      feedback.classList.remove("tryit-all-ok");
    });
  }

  function autoInit() {
    document.querySelectorAll(".tryit[data-tryit]").forEach(init);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", autoInit);
  } else {
    autoInit();
  }

  global.tryit = {
    init: init, // exposed in case an exercise is injected after DOMContentLoaded
    parseNumber: parseNumber,
    isCorrect: isCorrect,
  };
})(window);
