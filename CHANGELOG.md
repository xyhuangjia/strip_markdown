## 1.2.0

Tracks upstream [remove-markdown](https://github.com/zuchka/remove-markdown) 0.8.0
and adds streaming input support.

### Added

- `stripMdxImports` option to remove a leading block of default, named,
  namespace, or side-effect MDX/ESM imports (default: `false`). Supports
  multiline named imports, aliases, trailing commas, optional semicolons,
  LF/CRLF line endings, and stops at other content or unsupported syntax.
- `separateLinksAndTexts` option to replace an inline link with its text, a
  custom separator, and its URL (e.g. `[text](url)` becomes `text: url`).
- `removeMdStream` and `RemoveMarkdownTransformer` convert a `Stream<String>`
  of Markdown chunks into a stream of plain-text chunks. Chunks may split the
  Markdown at any position and Markdown syntax spanning chunk boundaries is
  still removed: input is buffered until a paragraph boundary outside fenced
  code blocks, stripped, and emitted.
- The joined streamed output matches `removeMd` on the complete document for
  paragraph-oriented Markdown, including CRLF input, fenced code blocks with
  blank lines, MDX imports, and every option.
- Dartdoc for every `RemoveMarkdownOptions` field, for `removeMd`, and for the
  streaming API.
- Regression tests for all upstream 0.8.0 behaviors and for streaming input
  (arbitrary chunkings, incremental emission, MDX imports, options, error
  forwarding, and the `StreamTransformer` API).

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

### Changed

- The document-leading MDX import stripping is shared between `removeMd` and
  the streaming converter. `removeMd` behavior is unchanged.

### Documentation

- README documents the new options, MDX import behavior, streaming input, and
  upstream compatibility.
- README now leads with a complete Simplified Chinese translation, followed
  by the English documentation.
- The example demonstrates `removeMdStream` and `RemoveMarkdownTransformer`.

## 1.1.0

- Don't match nested brackets in links for now

## 1.0.0

- Initial version.
