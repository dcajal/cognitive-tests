## 1.2.0

- Exported `StroopSequenceEntry` and exposed the immutable original word/color sequence through `StroopTest.sequence` after initialization.
- Added `sequence` and `language` to `StroopTestResult` so applications can store the source data and reconstruct all three pages for later scoring.
- Preserved existing result constructors with optional parameters and kept the existing page-level timestamps and audio behavior.
- Corrected the package's GitHub repository links.

## 1.1.0

- Added optional `audioPathProvider` to `StroopTest` to customize the output directory and filename for WAV recordings.
- Preserved the default timestamped audio path when no provider is supplied.
- Documented custom audio paths, directory creation, and error propagation.

## 1.0.1

Stroop: Added support for German, Turkish and Italian

## 1.0.0

Trail Making Test and Stroop Test with random item generation.
