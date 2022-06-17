# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.1.5](https://github.com/livebook-dev/vega_lite/tree/v0.1.5) (2022-06-17)

### Fixed

- Channel validation to allow `url` ([#32](https://github.com/livebook-dev/vega_lite/pull/32))

## [v0.1.4](https://github.com/livebook-dev/vega_lite/tree/v0.1.4) (2022-04-27)

### Added

- `:only` option to `data_from_values/3` to include a subset of fields in the specification ([#29](https://github.com/livebook-dev/vega_lite/pull/29))

### Changed

- `data_from_values/3` to accept any tabular data ([#29](https://github.com/livebook-dev/vega_lite/pull/29))

### Deprecated

- `data_from_series/3` in favour of the new `data_from_values/3` ([#29](https://github.com/livebook-dev/vega_lite/pull/29))

### Fixed

- Fixed the svg, png and pdf exports to work on Windows ([#28](https://github.com/livebook-dev/vega_lite/pull/28))

## [v0.1.3](https://github.com/livebook-dev/vega_lite/tree/v0.1.3) (2022-01-21)

### Added

- Support for the `:x_offset` and `:y_offset` encoding channels ([#25](https://github.com/livebook-dev/vega_lite/pull/25))

## [v0.1.2](https://github.com/livebook-dev/vega_lite/tree/v0.1.2) (2021-09-20)

### Added

- Support for specifying datasets ([#17](https://github.com/livebook-dev/vega_lite/pull/17))

## [v0.1.1](https://github.com/livebook-dev/vega_lite/tree/v0.1.1) (2021-09-15)

### Added

- Support for encoding channels with arrays ([#15](https://github.com/livebook-dev/vega_lite/pull/15))

## [v0.1.0](https://github.com/livebook-dev/vega_lite/tree/v0.1.0) (2021-05-24)

Initial release.
