## 1.2.0

Tracks upstream [remove-markdown](https://github.com/zuchka/remove-markdown) 0.8.0.

### Added

- `stripMdxImports` option to remove a leading block of default, named,
  namespace, or side-effect MDX/ESM imports (default: `false`). Supports
  multiline named imports, aliases, trailing commas, optional semicolons,
  LF/CRLF line endings, and stops at other content or unsupported syntax.
- `separateLinksAndTexts` option to replace an inline link with its text, a
  custom separator, and its URL (e.g. `[text](url)` becomes `text: url`).
- Dartdoc for every `RemoveMarkdownOptions` field and for `removeMd`.
- Regression tests for all upstream 0.8.0 behaviors.

### Fixed

- `replaceLinksWithURL` now returns the link URL instead of dropping the link
  entirely. The link pattern lacked the URL capture group required by the
  option (upstream issue [#103](https://github.com/zuchka/remove-markdown/issues/103)).
- Inline links whose text contains square brackets (e.g.
  `[link [with brackets]](url)`) are stripped again, while a standalone
  bracket pair earlier on the line is no longer swallowed into a following link.
  This keeps the intent of upstream PR [#93](https://github.com/zuchka/remove-markdown/pull/93)
  without its over-matching regression.
- Verified `htmlTagsToSkip` against the upstream 0.7.1 fix: tags with attributes
  are preserved and tag names are matched exactly (skipping `code` does not
  preserve `<codes>`).

### Documentation

- README documents the new options, MDX import behavior, and upstream
  compatibility.

## 1.1.0

- Don't match nested brackets in links for now

## 1.0.0

- Initial version.
