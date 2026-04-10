# Optical Lithography Simulator

MATLAB app for exploring optical lithography imaging with configurable source shape, mask geometry, condenser, projection pupil, and beam propagation views.

## What It Does

- Simulates partially coherent lithography imaging with an Abbe-style source-point sum
- Lets you change source shape: point, circular, annular, dipole, quadrupole, and freeform
- Lets you change mask shape and projection pupil shape
- Shows source, mask, pupil-plane beam intensity, detector image, and propagation views
- Includes built-in lecture examples and validation scripts

## Main App

Run:

```matlab
lithography_specular_gui
```

## Validation

Smoke test:

```matlab
lithography_specular_gui('selftest')
```

Benchmark and physicality checks:

```matlab
lithography_validation_report(true)
lithography_full_path_wave_test(true)
lithography_nearfield_shape_test(true)
```

## Notes

- The main image and XY beam-path slices use the most physical model in this project.
- The top ray sketch and YZ panel are still visualization models for intuition.
- The app includes warnings for clipping, coarse sampling, and other settings that may reduce reliability.
