/// Options controlling which Markdown formatting [removeMd] strips and how.
class RemoveMarkdownOptions {
  /// Strip list leaders (`*`, `-`, `+`, or `1.`) from the start of list items.
  ///
  /// Set to `false` to keep the leaders in the output.
  ///
  /// Defaults to `true`.
  final bool stripListLeaders;

  /// Strip a leading block of MDX imports (e.g. `import x from "pkg"`).
  ///
  /// Supports default, named, namespace, and side-effect imports. Stops at
  /// other content or unsupported syntax (including comments and import
  /// attributes). Only imports at the very start of the document are removed.
  ///
  /// Defaults to `false`.
  final bool stripMdxImports;

  /// Character to insert in place of a stripped list leader (e.g. `'•'`).
  ///
  /// Only takes effect when [stripListLeaders] is `true`.
  ///
  /// Defaults to `null`, which removes the leaders.
  final String? listUnicodeChar;

  /// Strip GitHub-Flavored Markdown extensions: fenced code blocks,
  /// strikethrough (`~~text~~`), and setext-style (`===`) headers.
  ///
  /// Defaults to `true`.
  final bool gfm;

  /// When removing an image (`![alt](url)`), keep its alt text in the output
  /// instead of deleting the image entirely.
  ///
  /// Defaults to `true`.
  final bool useImgAltText;

  /// Remove Markdown abbreviation definitions
  /// (lines like `*[HTML]: HyperText Markup Language`).
  ///
  /// Defaults to `false`.
  final bool abbr;

  /// Replace inline link text with its URL.
  ///
  /// Ignored for inline links when [separateLinksAndTexts] is non-empty.
  ///
  /// Defaults to `false`.
  final bool replaceLinksWithURL;

  /// For inline links (`[text](url)`), keep both text and URL, joined by this
  /// separator (e.g. `': '` turns `[text](url)` into `text: url`).
  ///
  /// A non-empty separator takes precedence over [replaceLinksWithURL].
  /// An empty string disables this option.
  ///
  /// Defaults to `null`.
  final String? separateLinksAndTexts;

  /// HTML tag names to leave untouched instead of stripping
  /// (e.g. `['a', 'b']`).
  ///
  /// Defaults to `const []`.
  final List<String> htmlTagsToSkip;

  /// Throw errors encountered while processing instead of catching them and
  /// returning the original input.
  ///
  /// Defaults to `false`.
  final bool throwError;

  const RemoveMarkdownOptions({
    this.stripListLeaders = true,
    this.stripMdxImports = false,
    this.listUnicodeChar,
    this.gfm = true,
    this.useImgAltText = true,
    this.abbr = false,
    this.replaceLinksWithURL = false,
    this.separateLinksAndTexts,
    this.htmlTagsToSkip = const [],
    this.throwError = false,
  });
}
