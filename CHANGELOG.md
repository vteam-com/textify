<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

## [0.1.6] - 2024-10-13

### Changed

- Improve Band assignement of artifacts
- Major refactoring
  
## [0.1.5] - 2024-10-12

### Changed

- Update Matrices.json to hit 100% match for the 4 fontds at size 40
- refactor clean up code

## [0.1.4] - 2024-10-10

### Changed

- Removed [image_pipeline.dart]
- Rename "Encloser" to "Enclosure"
  
## [0.1.3] - 2024-10-09

### Changed

- Updated README.md
- Updated Example/Dashboard

### Fixed

- Fixed enclosure count for 'R'

## [0.1.2] - 2024-10-08

### Added

- Support for characters: ! @ # & * - + = { } [ ] < > ?

## [0.1.1] - 2024-10-06

### Changed

- Use embedded fonts for generating template [Arial, Courier, Helvetica, Times New Roman]

## [0.1.0] - 2024-10-03

### Changed

- Removed unused function
- Made functions private
- Documented code

## [0.0.9] - 2024-10-02

### Changed

- Refactored to handle Bands and detect spaces

## [0.0.8] - 2024-10-01

### Added

- Documented public API - Artifact, Band, CharacterDefinitions

## [0.0.7] - 2024-10-01

### Added

- Support for characters: $ ; \

### Changed

- Refactored to enable better editing of templates

## [0.0.6] - 2024-10-01

### Added

- Documented Matrix.dart

### Changed

- Performance improvement: avoid scoring the Artifact for space " "

### Fixed

- Bug in the Example:Edit Screen

## [0.0.5] - 2024-09-30

### Added

- New top-level API "String getTextFromImage(IMAGE)"

### Changed

- Ran `dart format .`

## [0.0.4] - 2024-09-30

### Added

- Linked package to GitHub repo: <https://github.com/vteam-com/textify>

## [0.0.3] - 2024-09-30

### Changed

- Updated README.md

## [0.0.2] - 2024-09-30

### Added

- Support for characters-allowed

### Changed

- Updated Example - When pasting, just show the resulting text

### Fixed

- Fixed many typos

## [0.0.1] - 2024-09-23

### Added

- Initial implementation
