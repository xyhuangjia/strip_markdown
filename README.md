# Strip Markdown

[简体中文](#简体中文) | [English](#english)

# 简体中文

## 这是什么？

**strip_markdown** 是一个 Dart 包，用于移除（剥离）文本中的 Markdown 格式。它是流行的 Node.js [remove-markdown](https://github.com/zuchka/remove-markdown) 包的 Dart 移植版，当前对齐上游 **0.8.0** 版本。

*Markdown 格式*大体上指所有看起来不像普通文本的内容，比如方括号、星号、井号等。

## 什么时候需要它？

典型使用场景是展示一段 Markdown 文本的摘要，而不带任何 Markdown 语法——例如文章列表、搜索结果或内容预览。

## 安装

将以下内容添加到你的包的 ```pubspec.yaml``` 文件中：

```yaml
dependencies:
  strip_markdown: ^1.2.0
```

然后运行：
```bash
dart pub get
```

## 使用

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

你也可以向函数传入选项对象。目前支持以下选项：

```dart
final plainText = removeMd(markdown, const RemoveMarkdownOptions(
  stripListLeaders: true,      // 是否移除列表符号（默认：true）
  stripMdxImports: false,      // 是否移除文档开头的 MDX 导入语句（默认：false）
  listUnicodeChar: '•',        // 用来替代被移除列表符号的字符（默认：null）
  gfm: true,                   // 是否支持 GitHub 风格 Markdown（默认：true）
  useImgAltText: true,         // 是否用图片的 alt 文本替换图片（默认：true）
  abbr: false,                 // 是否移除缩写定义（默认：false）
  replaceLinksWithURL: false,  // 是否用链接地址替换内联链接（默认：false）
  separateLinksAndTexts: ': ', // 用文本、分隔符和地址替换内联链接（默认：null）
  htmlTagsToSkip: ['a', 'b'],  // 需要保留、不做移除的 HTML 标签（默认：[]）
  throwError: false,           // 出错时抛出异常，而不是返回原始文本（默认：false）
));
```

将 ```stripListLeaders``` 设为 ```false``` 会保留任何列表符号（```*, -, +, (数字).```）。

将 ```listUnicodeChar``` 设为某个字符串（例如 ```'•'```）会使用该字符替换列表符号，而不是直接移除。

将 ```replaceLinksWithURL``` 设为 ```true``` 时，内联链接会替换为链接地址，而不是链接文本。

将 ```separateLinksAndTexts``` 设为非空字符串时，内联链接的文本和 URL 会同时保留，并用该字符串连接。例如设为 ```': '``` 时，```[text](http://example.com)``` 会变成 ```text: http://example.com```。非空的分隔符优先于 ```replaceLinksWithURL```。

将 ```htmlTagsToSkip``` 设为 HTML 标签名列表时，会保留这些标签（包括带属性的标签），而不是移除它们。标签名按精确名称匹配，因此跳过 ```code``` 不会保留 ```codes```。

## MDX 导入

将 ```stripMdxImports``` 设为 ```true``` 会移除文档开头的一整块默认导入、具名导入、命名空间导入或副作用导入：

```dart
const markdown = '''
import { Card, Button } from "./components";
import "./styles.css";

# Welcome
''';

print(removeMd(markdown, const RemoveMarkdownOptions(stripMdxImports: true)));
// 输出：Welcome
```

具名导入可以跨多行，并支持别名和尾随逗号。每条语句必须位于行首，并以换行或文件结尾结束；分号、行尾的空格或制表符都是可选的。支持空行（包括仅含空白的行）以及 LF/CRLF 换行。

这个保守的过滤器会在遇到其他内容或不支持的导入语法（例如注释、import 属性）时停止。标题或其他内容之后的导入会保留在输出中。列表和代码块中的导入仍按常规的 Markdown 剥离行为处理。该选项默认值为 ```false```。

## 功能

本包支持移除：
- 标题（ATX ```#``` 和 Setext ```===``` 两种风格）
- 强调（使用 ```*``` 和 ```_``` 的粗体与斜体）
- 链接和图片
- 代码块和行内代码
- 列表（有序和无序）
- 引用块
- 水平分割线
- HTML 标签（可通过列表跳过指定标签）
- 删除线
- 缩写定义
- 文档开头的 MDX/ESM 导入语句（需开启选项）
- 以及更多！

## 上游兼容性

本 Dart 移植版遵循 [remove-markdown](https://github.com/zuchka/remove-markdown) 0.8.0 的行为与选项。对于链接文本中包含方括号的内联链接（例如 ```[link [with brackets]](http://example.com)```），仍能正确剥离，且不会出现上游 PR [#93](https://github.com/zuchka/remove-markdown/pull/93) 的过度匹配问题：同一行中其他位置独立的方括号对不会被视为后续链接的开头。

## 致谢

本包是 Node.js [remove-markdown](https://github.com/zuchka/remove-markdown) 包的 Dart 移植版。

原始 JavaScript 代码基于 Brett Terpstra 的 **Markdown Service Tools - Strip Markdown**。

### 原作者
- Stian Grytøyr（原始作者）
- [zuchka](https://github.com/zuchka)（2023 年起的维护者）

### Dart 移植
- Fabian Freund（Dart 实现）

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

---

# English

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
