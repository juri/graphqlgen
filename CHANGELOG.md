# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0](https://www.github.com/juri/graphqler/compare/0.2...0.3.0) (2021-03-07)

### Bug Fixes

- Fix version format to be semver compliant with three digits.
- Upgrade Jazzy to a version that doesn't have a security vulnerability. Add configuration to ensure it does the right thing.

### Features

- Add `EnumValue` for representing values of an Enum type.
- Replace most `let`s inside the structs with `var`s.
- Add mutating `append` methods to `Arguments`.

### Other changes

- Remove the unnecessary and broken workspace from the repository.
- Change spec links to link to graphql.org.
