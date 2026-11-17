import 'package:strip_markdown/src/entities/remove_markdown_options.dart';
import 'package:strip_markdown/src/mdx_imports.dart';

/// Strips Markdown formatting from [md], returning plain text.
///
/// On error, the original [md] input is returned unchanged, unless
/// [RemoveMarkdownOptions.throwError] is set, in which case the error is
/// rethrown.
String removeMd(String md, [RemoveMarkdownOptions? options]) {
  final opts = options ?? const RemoveMarkdownOptions();

  String output = md;

  if (opts.stripMdxImports) {
    // Inspect the original structure before list markers, rules or fences are
    // removed.
    output = stripLeadingMdxImports(output);
  }

  // Remove horizontal rules (stripListHeaders conflict with this rule, which is why it has been moved to the top)
  output = output.replaceAll(
    RegExp(
      r'^ {0,3}((?:-[\t ]*){3,}|(?:_[ \t]*){3,}|(?:\*[ \t]*){3,})(?:\n+|$)',
      multiLine: true,
    ),
    '',
  );

  try {
    if (opts.stripListLeaders) {
      if (opts.listUnicodeChar != null) {
        output = output.replaceAllMapped(
          RegExp(r'^([\s\t]*)([\*\-\+]|\d+\.)\s+', multiLine: true),
          (match) => '${opts.listUnicodeChar} ${match.group(1) ?? ''}',
        );
      } else {
        output = output.replaceAllMapped(
          RegExp(r'^([\s\t]*)([\*\-\+]|\d+\.)\s+', multiLine: true),
          (match) => match.group(1) ?? '',
        );
      }
    }

    if (opts.gfm) {
      output = output
          // Header
          .replaceAll(RegExp(r'\n={2,}'), '\n')
          // Fenced codeblocks
          .replaceAll(RegExp(r'~{3}.*\n'), '')
          // Strikethrough
          .replaceAll(RegExp('~~'), '')
          // Fenced codeblocks with backticks
          .replaceAllMapped(
            RegExp(r'```(?:.*)\n([\s\S]*?)```'),
            (match) => match.group(1)?.trim() ?? '',
          );
    }

    if (opts.abbr) {
      // Remove abbreviations
      output = output.replaceAll(RegExp(r'\*\[.*\]:.*\n'), '');
    }

    RegExp htmlReplaceRegex = RegExp('<[^>]*>');
    if (opts.htmlTagsToSkip.isNotEmpty) {
      // Create a regex that matches tags not in htmlTagsToSkip
      final joinedHtmlTagsToSkip = opts.htmlTagsToSkip.join('|');
      htmlReplaceRegex = RegExp(
        '<(?!\\/?($joinedHtmlTagsToSkip)(?=>|\\s[^>]*>))[^>]*>',
      );
    }

    final separator = opts.separateLinksAndTexts;
    if (separator != null && separator.isNotEmpty) {
      output = output.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
        (match) => '${match.group(1) ?? ''}$separator${match.group(2) ?? ''}',
      );
    }

    output = output
        // Remove HTML tags
        .replaceAll(htmlReplaceRegex, '')
        // Remove setext-style headers
        .replaceAll(RegExp(r'^[=\-]{2,}\s*$', multiLine: true), '')
        // Remove footnotes?
        .replaceAll(RegExp(r'\[\^.+?\](\: .*?$)?', multiLine: true), '')
        .replaceAll(RegExp(r'\s{0,2}\[.*?\]: .*?$', multiLine: true), '')
        // Remove images
        .replaceAllMapped(
          RegExp(r'\!\[(.*?)\][\[\(].*?[\]\)]'),
          (match) => opts.useImgAltText ? (match.group(1) ?? '') : '',
        )
        // Remove inline links. Nested brackets in the link text are matched so
        // that `[link [with brackets]](url)` keeps its text, while a lone
        // bracket pair elsewhere on the line (e.g. `[note] and [link](url)`)
        // cannot swallow the following link.
        .replaceAllMapped(
          RegExp(r'\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\s*[\(\[](.*?)[\)\]]'),
          (match) => opts.replaceLinksWithURL
              ? (match.group(2) ?? '')
              : (match.group(1) ?? ''),
        )
        // Remove blockquotes
        .replaceAllMapped(
          RegExp(r'^(\n)?\s{0,3}>\s?', multiLine: true),
          (match) => match.group(1) ?? '',
        )
        // Remove reference-style links?
        .replaceAll(
          RegExp(r'^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$', multiLine: true),
          '',
        )
        // Remove atx-style headers
        .replaceAllMapped(
          RegExp(
            r'^(\n)?\s{0,}#{1,6}\s*( (.+))? +#+$|^(\n)?\s{0,}#{1,6}\s*( (.+))?$',
            multiLine: true,
          ),
          (match) =>
              '${match.group(1) ?? ''}${match.group(3) ?? ''}${match.group(4) ?? ''}${match.group(6) ?? ''}',
        )
        // Remove * emphasis
        .replaceAllMapped(
          RegExp(r'([\*]+)(\S)(.*?\S)??\1'),
          (match) => '${match.group(2) ?? ''}${match.group(3) ?? ''}',
        )
        // Remove _ emphasis. Unlike *, _ emphasis gets rendered only if
        //   1. Either there is a whitespace character before opening _ and after closing _.
        //   2. Or _ is at the start/end of the string.
        .replaceAllMapped(
          RegExp(r'(^|\W)([_]+)(\S)(.*?\S)??\2($|\W)'),
          (match) =>
              '${match.group(1) ?? ''}${match.group(3) ?? ''}${match.group(4) ?? ''}${match.group(5) ?? ''}',
        )
        // Remove single-line code blocks (already handled multiline above in gfm section)
        .replaceAllMapped(
          RegExp(r'(`{3,})(.*?)\1', multiLine: true),
          (match) => match.group(2) ?? '',
        )
        // Remove inline code
        .replaceAllMapped(RegExp('`(.+?)`'), (match) => match.group(1) ?? '')
        // Replace strike through
        .replaceAllMapped(RegExp('~(.*?)~'), (match) => match.group(1) ?? '');
  } catch (e) {
    if (opts.throwError) rethrow;

    // print('remove-markdown encountered error: $e');
    return md;
  }

  return output;
}
