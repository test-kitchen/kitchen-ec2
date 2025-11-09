# Change log

## [v0.2.1] - 2021-03-09

### Changed
* Change to relax unicode-display_width version constraint to allow 2.0 release

## [v0.2.0] - 2020-08-11

### Changed
* Change String#wrap to preserve newline character breaks
* Change gemspec to remove test artefacts and bundler dev dependency
* Change gemspec to require Ruby >= 2.0.0

## [v0.1.8] - 2019-11-24

### Fixed
* Fix Ruby 2.7 warnings by Ryan Davis(@zenspider)

## [v0.1.7] - 2019-11-14

### Added
* Add metadata to gemspec

### Fixed
* Fix Truncate#truncate to accept length of 1 by Katelyn Schiesser(@slowbro)

## [v0.1.6] - 2019-08-28

### Changed
* Change Wrap#wrap, Align#align & Pad#pad to handle different line endings
* Change Pad#pad to pad empty lines

### Fixed
* Fix Wrap#wrap to handle adjacent ANSI codes
* Fix Wrap#insert_ansi to handle nested ANSI codes

## [v0.1.5] - 2019-03-29

### Changed
* Change to update unicode-display_width to the latest version
* Change to relax development dependencies versions

## [v0.1.4] - 2018-09-10

### Fixed
* Fix align_center for multiline text with tight width by @DannyBen

## [v0.1.3] - 2018-08-28

### Changed
* Change to extract Strings::ANSI to strings-ansi gem

## [v0.1.2] - 2018-08-10

### Changed
* Change unicode-display_width to latest version

## [v0.1.1] - 2018-02-20

### Added
* Add ability to refine String class with extensions

## [v0.1.0] - 2018-01-07

* Initial implementation and release

[v0.2.1]: https://github.com/piotrmurach/strings/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/piotrmurach/strings/compare/v0.1.8...v0.2.0
[v0.1.8]: https://github.com/piotrmurach/strings/compare/v0.1.7...v0.1.8
[v0.1.7]: https://github.com/piotrmurach/strings/compare/v0.1.6...v0.1.7
[v0.1.6]: https://github.com/piotrmurach/strings/compare/v0.1.5...v0.1.6
[v0.1.5]: https://github.com/piotrmurach/strings/compare/v0.1.4...v0.1.5
[v0.1.4]: https://github.com/piotrmurach/strings/compare/v0.1.3...v0.1.4
[v0.1.3]: https://github.com/piotrmurach/strings/compare/v0.1.2...v0.1.3
[v0.1.2]: https://github.com/piotrmurach/strings/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/piotrmurach/strings/compare/v0.1.0...v0.1.1
[v0.1.0]: https://github.com/piotrmurach/strings/compare/v0.1.0
