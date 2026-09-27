# Working on Optical Bench

The owner studies science and is not a software engineer. Keep replies intuitive, accurate and brief. Explain results and meaningful limitations; keep routine implementation detail in project records.

## Source and scope

- This repository contains the MATLAB application and a tracked `web/` subtree. In this workspace, `optical-bench/` is a separate managed Sites checkout for web/iOS work. Inspect the relevant Git roots and current commits before editing. Do not independently patch both copies or overwrite a newer copy with an older one; use the established subtree workflow when synchronization is part of the task.
- MATLAB source is in `src/`, with the main app at the root. Read `docs/DEVELOPMENT.md` for MATLAB tests and `docs/FULL_PATH_MODEL.md` for physical-model changes. Web/native instructions are in the managed checkout's `AGENTS.md`, `README.md` and `IOS_INSTALL.md` when present; otherwise use the documentation under `web/`.
- A request to plan first is not authorization to change the app. After approval, proceed with the approved scope and include still-open earlier feedback. Keep later reversals as the current requirement rather than accumulating incompatible plans.

## Invariants

- Keep illumination/source pupil and projection aperture distinct. Moving an observation plane must not move the physical Image plane.
- Distinguish raw computed fields, display normalization/interpolation and illustrated component dimensions. UI polish must not silently change the physics, sampling or precision.
- Preserve current startup parameters separately from frozen reference and benchmark fixtures. Refine numerical settings and compare results on matching physical coordinates; do not adjust fixtures merely to make a changed solver pass.
- Test visual relationships in the rendered UI and continuous controls through multiple updates. Numerical tests alone cannot establish layout or gesture correctness. Run relevant checks for the change; use the broader scientific suites for numerical changes and release verification.

## Continuity

- Current product preference: readable Key positions images and natural scrolling; fitting all content into one desktop viewport was explicitly superseded. New user instructions can change this again.
- When recording verification, state the revision/artifact, environment and actual checks. Historical `TEST_REPORT.md` entries, screenshot counts and deployment claims are not current certification. Keep implemented, installed, submitted and publicly available distinct.
- Read `docs/DEVELOPMENT_LESSONS.md` when planning a substantial UI iteration or native port; ordinary small edits do not require rereading the retrospective.
