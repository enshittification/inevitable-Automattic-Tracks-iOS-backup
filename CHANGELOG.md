# Changelog

The format of this document is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This is a comment, you won't see it when GitHub renders the Markdown file.

When releasing a new version:

1. Remove any empty section (those with `_None._`)
2. Update the `## Unreleased` header to `## [<version_number>](https://github.com/Automattic/Automattic-Tracks-iOS/releases/tag/<version_number>)`
3. Add a new "Unreleased" section for the next iteration, by copy/pasting the following template:

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

-->

## Unreleased

### Breaking Changes

- `logErrorImmediately` and `logErrorsImmediately` no longer have a `Result` parameter in their callback [#232]
- `logErrorImmediately` and `logErrorsImmediately` no longer `throws` [#236]

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

- Add this changelog file [#234]
- Log a message if events won't be collected because the user opted out [#239]