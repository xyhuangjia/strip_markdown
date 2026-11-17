/// Removes a leading block of MDX/ESM import statements from [input].
///
/// This intentionally supports only a leading block of imports, not all MDX
/// ESM. It is used by [removeMd] and by the streaming converter, which needs
/// to know when the document-leading import block has ended.
///
/// The [input] is returned unchanged when no supported import block is found.
String stripLeadingMdxImports(String input) {
  // Inspect the original structure before list markers, rules or fences are
  // removed.
  const identifier = r'[A-Za-z_$][\w$]*';
  const specifier = '$identifier(?:\\s+as\\s+$identifier)?\\s*';
  const namedImports =
      '\\{\\s*(?:$specifier(?:,\\s*$specifier)*(?:,\\s*)?)?\\}';
  const namespaceImport = '\\*\\s+as\\s+$identifier';
  const bindings =
      '(?:$identifier(?:\\s*,\\s*(?:$namedImports|$namespaceImport))?'
      '|$namedImports|$namespaceImport)';
  const modulePath =
      r'''(?:"(?:\\[^\r\n]|[^"\\\r\n])*"|'(?:\\[^\r\n]|[^'\\\r\n])*')''';
  const blankLines = '(?:[\\t ]*\\r?\\n)*';
  final importRegex = RegExp(
    '^${blankLines}import[\\t ]+(?:$bindings\\s+from\\s+)?$modulePath'
    '[\\t ]*(?:;[\\t ]*)?(?:\\r?\\n|\$)$blankLines',
  );

  var output = input;
  while (true) {
    final match = importRegex.firstMatch(output);
    if (match == null) break;
    output = output.substring(match.end);
  }
  return output;
}
