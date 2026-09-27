# What Optical Bench taught us about working together

Retrospective, 27 September 2026. Based on the user's annotated reviews, the conversation, and a read-only review of the current source. This document records lessons, not a new certification of the application.

## The most valuable part of the collaboration

The user supplied scientific judgment and direct experience of the interface: which controls felt awkward, what mattered in an image, and when compactness became crowding. The assistant could turn those observations into code, numerical checks and working versions. Annotated screenshots gave us a shared reference much more precise than a long abstract design brief.

That loop produced a useful application. It also exposed where the assistant should have converted feedback into clearer criteria earlier, instead of requiring the user to catch another version of the same problem.

## Lessons that should change future behavior

| What happened | What to learn | Next time |
|---|---|---|
| Alignment was requested repeatedly, including after shorter labels were introduced. | Correct words and component order do not establish matching edges, heights or row alignment. A screenshot shows the symptom; it does not establish the source-code cause. | Name the requested visual relationship, inspect the actual container and rendered bounds, then verify both the small region and the whole page. |
| The user first requested a single-screen desktop view, then restored larger Key positions images and accepted scrolling. | Seeing a working version changes design judgment. A revised preference is useful information, not a failure to provide a perfect initial specification. | Keep one current decision record. Explicitly retire the earlier density constraint; do not keep optimizing for both. |
| Additional Wave options became too long and most were moved to Settings. | More controls can make the main task harder. Adding one useful option does not justify a new panel of explanations. | Keep frequent actions visible and secondary options discoverable. Reduce redundant rows and copy before shrinking images, text or touch targets. |
| Dragging should move Standard/Expert markers without forcing Edit open. Mac dragging behaved differently between sliders. | Selection, movement, disclosure and calculation are separate states. The control can look unchanged while a rerender disrupts its active gesture. | Preserve control identity during input, inspect structural updates, and test the actual interaction state. Label mouse/emulation checks separately from a physical accessibility gesture. |
| The application combined optical computation, cached results and display smoothing. | A better-looking image can conceal numerical changes, clipping or stale data. | Classify a change as model, numerical method, cache or display; use the corresponding evidence. Keep raw data and physical coordinates distinct from appearance. |
| The web interface was packaged for iPhone with offline assets, saving and system sharing. | Preserving a proven implementation can reduce risk, but a browser preview does not prove native behavior. | Validate the highest-risk packaged features early: offline cold start, worker/data loading, a new calculation, persistence and export. |
| “American account” actually meant publishing in a storefront; the intended release expanded to two countries. | Product availability, legal account residence, signing and device restrictions are different questions. | Clarify the distinction once when necessary. Prepare independent release work without repeatedly asking the same unresolved question or changing an account prematurely. |
| Tests, screenshots, builds and draft store documents accumulated. | Each proves something different. A large passing-test count cannot demonstrate a particular UI alignment or public availability. | Record the artifact/revision, environment, what was exercised and what remains unverified. State the actual delivery stage. |

## Concrete engineering evidence

The web/iOS source was reviewed at `optical-bench` commit `0e39e0b`. Paths below are relative to that checkout unless stated otherwise.

- `dist/control-layout.js`: the current position update refreshes its readout; structural moves are handled through layout/view changes, with guards around relocation. This supports preserving active controls during continuous input. It does not independently prove that a particular Mac three-finger gesture was physically retested.
- `dist/index.html`: several layout styles/scripts contribute to the final page. Inspecting the final cascade is necessary before another override. Their existence alone is not evidence that every alignment failure had the same cause.
- `dist/observation-state.js`, `dist/serial-jobs.js`, `dist/preset-cache.js`: result identity, parameter/provenance validation and late-result rejection protect a calculation from being shown under the wrong current state.
- `scripts/prepare-ios.mjs`: authored `dist/` files are prepared into `ios-web/`, then synchronized into the native public bundle. Editing generated assets bypasses this source of truth. The versioned entry point is a packaging dependency worth checking when script URLs change.
- `scripts/native-bridge.js`: preferences store experiment state and the native bridge prepares image sharing. Source inspection establishes implementation presence, not successful saving or delivery on every device.
- `TEST_REPORT.md` and `APP_STORE_US_NL.md` record different stages and test counts. The README also contains an older hosting-access statement. These are reasons to check the current artifact/status before repeating historical claims, rather than treating all accumulated documentation as one current certificate.
- The parent repository's `docs/DEVELOPMENT.md` already separates startup defaults, frozen references and numerical benchmarks, and calls for independent calculations at common physical coordinates. Those distinctions belong in the persistent project instructions.

No application tests were rerun for this documentation-only retrospective. Previously recorded results remain historical evidence.

## The smaller, more reliable loop

1. Understand the current user task and preserve the still-active previous decisions. For a new app, start with a small working example that demonstrates the central task.
2. Translate feedback into observable behavior: which mode, device, control relationship and state should change. Keep minor decisions internal; show a concrete plan when the user requests one.
3. Implement at the authoritative source. Preserve unrelated behavior, numerical meaning and the current authorization boundary.
4. Check the changed behavior with suitable evidence: geometry plus screenshots for alignment; continuous interaction for dragging; independent numerical references for scientific changes.
5. Let the user review a useful working result. Apply corrections as updates to the current specification, not as another permanent layer of conflicting requirements.
6. For delivery, verify the actual destination or installed artifact. Summarize briefly, with limitations only where they matter.

The scale should follow the task. A spacing correction does not need an exhaustive plan, a full numerical suite or a new approval request. A physics change or native release does need deeper validation. Test counts, viewport combinations and documentation should grow only when they protect a real requirement.

## What is now saved

- A personal **`app-iteration` skill** at `~/.codex/skills/app-iteration/`. It contains the reusable feedback-to-verification workflow, with references for recurring UI failures and scientific/native work. Invoke it with `$app-iteration` in a future project.
- [Root project instructions](../AGENTS.md), plus `optical-bench/AGENTS.md` in the separate web/iOS checkout. They preserve the project's source map, scientific distinctions, interaction behavior and evidence boundaries close to the code.
- A small user-authorized memory update points future sessions to this skill and preserves the preference for concise explanations, plan-first boundaries and observable verification.

A plugin would be useful if we later need to distribute these skills together or add a service/tool integration. This task needs reusable guidance, so a local skill and project instructions are sufficient. They can guide different models; they do not retrain the underlying model or guarantee perfect future behavior.

The skill passed the bundled skill validator. A fresh local Codex skill-discovery query found `app-iteration` enabled at user scope both inside this project and in an unrelated temporary directory. An independent agent applied it to three fictional cases: a plan-only layout reversal, a failing continuous drag, and a two-country release with an unsigned archive. Those reviews checked decision-making and led to clearer guidance for provisional plans and account actions; they were not application or physical-device tests. A second review checked the project instructions against source and found no material issues.

The packaging choice follows the official guidance on [reusable skills](https://learn.chatgpt.com/docs/build-skills) and [project instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md). The installed runtime's successful discovery check is the evidence for this Mac's skill location.

## What should not become a permanent rule

Do not turn one layout decision into a universal design style. Do not preserve superseded UI labels, guessed causes, temporary membership/signing state, device identifiers, prices or historical test counts as permanent instructions. Check changing platform requirements when they matter. Avoid adding an instruction for every incident: retain only lessons that improve a future decision.

The user's current request remains authoritative. Update these records when an accepted decision changes; do not use this retrospective to resist a new direction.
