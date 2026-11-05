# Card classification plan (demo vs. task)

105 calculator cards: **36 demo**, **69 task**.

Proposed from card structure (goal present, input types, title); each card's lead-in text was not read, so review the *Action* column before applying.

Rule used: goal -> task; no goal and numeric -> demo (inputs to sliders); select/logical inputs -> task with a new goal; table-only -> demo; decision matrices -> demo; only the first plain numeric calculator in a chapter is a demo, the rest become tasks with new goals.

| Ch | Card label | Title | Inputs | Mode | Action |
|---|---|---|---|---|---|
| 01-04 | stackup-sim-01-04 | Tolerance Stack-Up Simulator | 2 | task | Simulation: keep goal; check seeds 1:10 |
| 02-01 | bolt-load-response-interactive | Bolt Load Response Calculator | 3 | task | Keep goal; verify it is FALSE at defaults |
| 02-01 | joint-working-load-interactive | Joint Load-Sharing Calculator | 4 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 02-01 | bolt-safety-analysis-interactive | Bolted Joint Safety Factor Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 02-01 | example2-interactive | Example 2 Calculator (Questions 1-8) | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 02-02 | gear-geometry-calc | Gear Pair Geometry Calculator | 3 | demo | Worked-example card: convert to sliders, drop goal (the next gear cards keep theirs) |
| 02-02 | gear-pair-calc | Gear Pair: Speed and Torque | 5 | task | Keep goal; verify it is FALSE at defaults |
| 02-02 | compound-train-calc | Two-Stage Compound Gear Train | 5 | task | Keep goal; verify it is FALSE at defaults |
| 02-02 | planetary-calc | Planetary Gear Set | 3 | task | Keep goal; verify it is FALSE at defaults |
| 02-02 | vehicle-cruise-calc | Cruising Engine Speed | 4 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | cubic-load-life-demo | Load-Life Demo: Why the Cubic Matters | 3 | demo | Already all sliders, no goal: just set mode |
| 02-03 | bearing-life-calc | Ball Bearing Life Calculator | 8 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | bearing-C-calc | Dynamic Load Rating from Geometry | 6 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | bearing-select-calc | Bearing Selection from the Catalog | 3 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | bearing-worksheet-calc | Bearing Life Worksheet (Radial Load, Single-Row Ball Bearing) | 6 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | film-thickness-calc | Minimum Oil Film Thickness | 4 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | bushing-sizing-calc | Bushing Sizing Calculator | 5 | task | Keep goal; verify it is FALSE at defaults |
| 02-03 | bearing-fleet-02-03 | Bearing Fleet Simulator | 3 | task | Simulation: keep goal; check seeds 1:10 |
| 02-05 | grashof-interactive | Grashof Condition Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 02-05 | trans-angle-interactive | Transmission Angle Calculator | 4 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-01 | payload-check-06-01 | Payload vs. CG Offset Calculator | 5 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-01 | cycle-time-calc-06-01 | Robot Cycle Time Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-01 | separation-distance-06-01 | ISO 13855 Minimum Separation Distance Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-01 | guarding-selection-06-01 | Guarding Technology Selector | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-01 | collab-check-06-01 | Collaborative Application Check | 3 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-01 | psr-check-06-01 | Pre-Start Review (PSR) Applicability | 3 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-02 | plr-sil-06-02 | IEC 62061 Class Score / SIL Estimator | 3 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-02 | category-select-06-02 | Safety Category Selector | 2 | demo | Table-driven: convert the scalar input to a slider |
| 06-02 | relay-plc-06-02 | Safety Relay vs. Safety PLC Cost Calculator | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-02 | stop-category-06-02 | Stop Category Selector | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-02 | pl-verify-06-02 | PL Verification (Category + DCavg + MTTFd) | 4 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-02 | stopping-time-06-02 | Overall Stopping Time Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-02 | psr-doc-06-02 | PSR Documentation Package Check | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-03 | nema-ip-select-06-03 | NEMA / IP Enclosure Selector | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-03 | heat-load-06-03 | Enclosure Heat Load and Cooling Calculator | 7 | task | Keep goal; verify it is FALSE at defaults |
| 06-03 | branch-protection-06-03 | Motor Branch Circuit Protection Calculator | 5 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-03 | sccr-check-06-03 | Panel SCCR Weakest-Link Check | 2 | demo | Table-driven: convert the scalar input to a slider |
| 06-03 | cert-pathway-06-03 | Certification Pathway Check | 3 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-04 | derating-06-04 | Conductor Ampacity Derating Calculator | 3 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-04 | dc-voltage-drop-06-04 | 24 VDC Voltage Drop Calculator | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-04 | motor-feeder-vdrop-06-04 | Three-Phase Motor Feeder Voltage Drop Calculator | 6 | task | Keep goal; verify it is FALSE at defaults |
| 06-04 | cable-selection-06-04 | Cable Construction Selector | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-04 | fuse-breaker-06-04 | Fuse vs. Breaker SCCR Check | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-04 | selective-coordination-06-04 | Selective Coordination Check | 1 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-05 | ground-loop-current-06-05 | Ground Loop Current Calculator | 3 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-05 | pigtail-reactance-06-05 | Shield Termination Reactance Calculator | 3 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-05 | bearing-voltage-06-05 | VFD Bearing Voltage Estimator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-05 | star-mesh-decision-06-05 | Star vs. Mesh Grounding Decision Matrix | 4 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-05 | touch-voltage-06-05 | Touch Voltage: Bonded vs. Ground Rod Only | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-06 | reflected-inertia-06-06 | Reflected Inertia Ratio Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-06 | rms-torque-06-06 | RMS Torque Calculator | 6 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-06 | gearbox-service-factor-06-06 | Gearbox Service Factor Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-06 | servo-vs-vfd-decision-06-06 | Servo vs. Induction + VFD Decision Matrix | 4 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-06 | conveyor-vfd-sizing-06-06 | Decline Conveyor Force Balance and VFD Sizing | 7 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-06 | braking-resistor-06-06 | Braking Resistor Sizing Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-06 | efficiency-payback-06-06 | Motor Efficiency Payback Calculator | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-07 | theoretical-actual-force-06-07 | Theoretical vs. Actual Cylinder Force | 7 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-07 | air-consumption-06-07 | Cylinder Air Consumption Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-07 | valve-cv-sizing-06-07 | Valve Cv Sizing Calculator | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-07 | frl-sizing-06-07 | FRL Sizing Calculator | 3 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-07 | cylinder-oversize-cost-06-07 | Cost of Oversizing a Cylinder | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-07 | leak-cost-06-07 | Compressed Air Leak Cost Calculator | 2 | task | Keep goal; verify it is FALSE at defaults |
| 06-07 | electric-vs-pneumatic-decision-06-07 | Electric vs. Pneumatic Actuator Decision Matrix | 6 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-08 | buckling-06-08 | Ball Screw Buckling Safety Factor | 6 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-08 | ballscrew-life-06-08 | Ball Screw L10 Life Calculator | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-08 | guide-life-06-08 | Linear Guide Life Calculator | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-08 | selflock-06-08 | Lead Screw Self-Locking Check | 3 | task | Keep goal; verify it is FALSE at defaults |
| 06-09 | keyway-upsize-06-09 | Keyway Stress Concentration Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-09 | coupling-decision-06-09 | Coupling Selection Decision Matrix | 4 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-09 | belt-sizing-06-09 | V-Belt Drive Sizing Calculator | 7 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-09 | chain-belt-decision-06-09 | Chain vs. Belt Weighted Decision | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-10 | drive-power-torque-06-10 | Conveyor Drive Power and Torque Calculator | 5 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-10 | speed-throughput-06-10 | Belt Speed from Throughput Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-10 | conveyor-selection-matrix-06-10 | Conveyor Type Decision Matrix | 5 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-10 | sanitary-zone-checklist-06-10 | Sanitary Zone Classifier | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-11 | deflection-budget-06-11 | Frame Deflection Budget Calculator | 6 | task | Keep goal; verify it is FALSE at defaults |
| 06-11 | material-decision-06-11 | Frame Material Weighted Decision | 1 | demo | Table-driven: keep as is (instructor edits the data) |
| 06-11 | bolted-joint-clamp-06-11 | Slip-Critical Joint Clamp Force Calculator | 5 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-11 | stability-anchor-06-11 | Overturning Stability and Anchor Force Calculator | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-11 | natural-freq-baseline-06-11 | Beam Natural Frequency Check (Baseline) | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-11 | natural-freq-stiffened-06-11 | Beam Natural Frequency Check (Stiffened) | 2 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-12 | heatsink-selection-06-12 | Heatsink Selection Calculator | 6 | task | Keep goal; verify it is FALSE at defaults |
| 06-12 | fan-sizing-06-12 | Panel Fan Sizing Calculator | 4 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-12 | convection-decision-06-12 | Natural Convection Capacity Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-12 | derating-check-06-12 | Drive Ambient Derating Check | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-13 | supply-sizing-06-13 | 24 VDC Power Supply Sizing Calculator | 3 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-13 | inrush-check-06-13 | Inrush / Surge Current Check | 7 | task | Keep goal; verify it is FALSE at defaults |
| 06-13 | battery-sizing-06-13 | Backup Battery Sizing Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-13 | redundancy-cost-06-13 | Power Supply Redundancy Payback Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-13 | branch-fusing-06-13 | Branch Fuse Coordination Check | 1 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-14 | sensing-derate-06-14 | Inductive Sensor Derating Calculator | 5 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-14 | pnp-npn-fault-06-14 | PNP vs. NPN Chafed-Wire Fault | 1 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-14 | io-architecture-decision-06-14 | I/O Architecture Decision Matrix | 4 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-14 | signal-error-06-14 | 0-10 V Signal Error Calculator | 3 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-14 | washdown-checklist-06-14 | Washdown Sensor Checklist | 7 | task | Select/logical inputs cannot be sliders: add a goal (e.g. find the combination that passes) |
| 06-14 | io-count-spare-06-14 | I/O Count and Spare Capacity Calculator | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-14 | loop-budget-06-14 | 4-20 mA Loop Voltage Budget Calculator | 4 | task | Keep goal; verify it is FALSE at defaults |
| 06-15 | valve-cv-06-15 | Gripper Valve Cv Sizing Calculator | 4 | demo | First calculator of the chapter: all inputs to sliders with min/max, fix chart axes |
| 06-15 | conveyor-drive-06-15 | Infeed Conveyor Drive Sizing Calculator | 7 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-15 | servo-vfd-decision-06-15 | Servo vs. Induction + VFD Decision Matrix (Conveyor) | 4 | demo | Weights to sliders (0-10); instructor re-weights live |
| 06-15 | branch-protection-sccr-06-15 | Panel Branch Protection and SCCR Check | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-15 | voltage-drop-06-15 | Gripper Solenoid Voltage Drop Calculator | 4 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-15 | bonding-grounding-06-15 | Cell Bonding and Grounding Calculator | 6 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
| 06-15 | stopping-distance-06-15 | Cell Stopping Time and Separation Distance | 6 | task | Keep goal; verify it is FALSE at defaults |
| 06-15 | beam-deflection-06-15 | Robot Pedestal Beam Deflection Check | 5 | task | Add goal/goal_test (FALSE at defaults, reachable, trivial exits closed) |
