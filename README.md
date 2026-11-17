# Strip Markdown

## What is it?
**strip_markdown** is a Dart package that removes (strips) Markdown formatting from text. This is a port of the popular Node.js [remove-markdown](https://github.com/zuchka/remove-markdown) package, currently tracking upstream version **0.8.0**.

*Markdown formatting* means pretty much anything that doesn't look like regular text, like square brackets, asterisks, hash symbols, etc.

## When do I need it?
The typical use case is to display an excerpt from some Markdown text, without any of the actual Markdown syntax - for example in a list of posts, search results, or content previews.

## Installation

Add this to your package's ```pubspec.yaml``` file:

```yaml
dependencies:
  strip_markdown: ^1.2.0
```

Then run:
```bash
dart pub get
```

## Usage

```dart
import 'package:strip_markdown/strip_markdown.dart';

void main() {
  const markdown = '''
# This is a heading

This is a paragraph with [a link](http://www.example.com/) in it.

- List item 1
- List item 2

> This is a blockquote
''';

  final plainText = removeMd(markdown);
  print(plainText);
  // Output: This is a heading
  //
  // This is a paragraph with a link in it.
  //
  // List item 1
  // List item 2
  //
  // This is a blockquote
}
```

You can also supply an options object to the function. Currently, the following options are supported:

```dart
final plainText = removeMd(markdown, const RemoveMarkdownOptions(
  stripListLeaders: true,      // strip list leaders (default: true)
  stripMdxImports: false,      // strip leading MDX import statements (default: false)
  listUnicodeChar: '•',        // char to insert instead of stripped list leaders (default: null)
  gfm: true,                   // support GitHub-Flavored Markdown (default: true)
  useImgAltText: true,         // replace images with alt-text, if present (default: true)
  abbr: false,                 // remove abbreviations, if present (default: false)
  replaceLinksWithURL: false,  // replace inline links with their URLs (default: false)
  separateLinksAndTexts: ': ', // replace inline links with text, separator and link (default: null)
  htmlTagsToSkip: ['a', 'b'],  // HTML tags to skip, if present (default: [])
  throwError: false,           // throw errors instead of returning original text (default: false)
));
```

Setting ```stripListLeaders``` to ```false``` will retain any list characters (```*, -, +, (digit).```).

Setting ```listUnicodeChar``` to a string (e.g., ```'•'```) will replace list leaders with that character instead of removing them entirely.

Setting ```replaceLinksWithURL``` to ```true``` replaces inline links with their URL instead of their text.

Setting ```separateLinksAndTexts``` to a non-empty string keeps both the text and the URL of an inline link, joined by that separator. For example, with ```': '```, ```[text](http://example.com)``` becomes ```text: http://example.com```. A non-empty separator takes precedence over ```replaceLinksWithURL```.

Setting ```htmlTagsToSkip``` to a list of HTML tag names preserves those tags (including tags with attributes) instead of removing them. Tag names are matched exactly, so skipping ```code``` does not preserve ```codes```.

## MDX imports

Setting ```stripMdxImports``` to ```true``` removes a leading block of default, named, namespace, or side-effect MDX/ESM imports:

```dart
const markdown = '''
import { Card, Button } from "./components";
import "./styles.css";

# Welcome
''';

print(removeMd(markdown, const RemoveMarkdownOptions(stripMdxImports: true)));
// Output: Welcome
```

Named imports can span multiple lines and include aliases and trailing commas. Statements must start at the beginning of a line and end with a newline or EOF, with an optional semicolon and trailing spaces or tabs. Blank lines, including whitespace-only lines, and LF/CRLF line endings are supported.

This conservative filter stops at the first other content or unsupported import syntax, such as comments or import attributes. Imports after headings or other content remain in the output. Imports in lists and code blocks retain the usual Markdown-stripping behavior. This option defaults to ```false```.

## Features

This package supports removing:
- Headers (both ATX ```#``` and Setext ```===``` styles)
- Emphasis (bold and italic with ```*``` and ```_```)
- Links and images
- Code blocks and inline code
- Lists (ordered and unordered)
- Blockquotes
- Horizontal rules
- HTML tags (with a list of tags to skip)
- Strikethrough text
- Abbreviations
- Leading MDX/ESM import statements (opt-in)
- And more!

## Upstream compatibility

The Dart port follows the behavior and options of [remove-markdown](https://github.com/zuchka/remove-markdown) 0.8.0. Inline links whose text contains square brackets (for example ```[link [with brackets]](http://example.com)```) are still stripped correctly, without the over-matching regression of upstream PR [#93](https://github.com/zuchka/remove-markdown/pull/93): a standalone bracket pair elsewhere on the line is not treated as the start of a following link.

## Credits

This is a Dart port of the Node.js [remove-markdown](https://github.com/zuchka/remove-markdown) package.

The original JavaScript code is based on **Markdown Service Tools - Strip Markdown** by Brett Terpstra.

### Original Authors
- Stian Grytøyr (original creator)
- [zuchka](https://github.com/zuchka) (maintainer since 2023)

### Dart Port
- Fabian Freund (Dart implementation)

## License

MIT License - see the [LICENSE](LICENSE) file for details.
