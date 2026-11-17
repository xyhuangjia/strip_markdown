import 'dart:async';

import 'package:strip_markdown/src/entities/remove_markdown_options.dart';
import 'package:strip_markdown/src/mdx_imports.dart';
import 'package:strip_markdown/src/remove_markdown.dart';

/// Converts a stream of Markdown chunks into a stream of plain-text chunks.
///
/// The input chunks may split the Markdown at any position, for example one
/// token, one network packet, or one line at a time. Markdown syntax that
/// spans chunk boundaries is still removed: input is buffered until a
/// paragraph boundary (a blank line outside a fenced code block), stripped
/// with [removeMd], and emitted.
///
/// The emitted chunks join to the same text that [removeMd] returns for the
/// complete document, as long as Markdown constructs do not span blank lines
/// (for example multiline inline links are not supported). For exact
/// document-level semantics, collect the input first and call [removeMd] once.
///
/// When [RemoveMarkdownOptions.stripMdxImports] is enabled, leading MDX
/// imports are stripped as soon as the import block is known to be complete.
Stream<String> removeMdStream(
  Stream<String> markdown, [
  RemoveMarkdownOptions? options,
]) {
  return RemoveMarkdownTransformer(
    options ?? const RemoveMarkdownOptions(),
  ).bind(markdown);
}

/// A [StreamTransformer] that strips Markdown formatting chunk by chunk.
///
/// Use [removeMdStream] for the common case, or this transformer to plug into
/// `Stream.transform`:
///
/// ```dart
/// final plainText = markdownStream.transform(RemoveMarkdownTransformer());
/// ```
class RemoveMarkdownTransformer extends StreamTransformerBase<String, String> {
  /// Options used to strip each buffered segment of the stream.
  final RemoveMarkdownOptions options;

  const RemoveMarkdownTransformer([
    this.options = const RemoveMarkdownOptions(),
  ]);

  @override
  Stream<String> bind(Stream<String> stream) async* {
    final state = _RemoveMarkdownStreamState(options);
    await for (final chunk in stream) {
      state.add(chunk);
      for (final output in state.takeReady()) {
        yield output;
      }
    }
    for (final output in state.finish()) {
      yield output;
    }
  }
}

class _RemoveMarkdownStreamState {
  _RemoveMarkdownStreamState(this.options)
    : _atStart = options.stripMdxImports,
      _laterOptions = _withoutMdxImports(options);

  /// Prefix used while processing a seam so that line-anchored rules see the
  /// held whitespace as preceded by content, exactly like in the complete
  /// document.
  static const _sentinel = '\u0000';

  /// Probe appended to a flushed segment while the stream still has following
  /// content. Rules that greedily consume trailing whitespace (for example an
  /// empty heading) behave differently at end of input; the probe tells them
  /// that content follows.
  static const _probe = '\u0001';

  final RemoveMarkdownOptions options;
  final RemoveMarkdownOptions _laterOptions;

  String _buffer = '';
  bool _atStart;
  String _startRaw = '';
  int _scanFrom = 0;
  bool _fenceOpen = false;
  int _flushPosition = -1;

  /// Whitespace of the stripped text held back so that the next segment is
  /// processed together with it. Markdown rules inspect whitespace before a
  /// line (reference-style link definitions) or consume whitespace after a
  /// line (horizontal rules), so the seam is processed as a unit.
  String _pendingTail = '';

  void add(String chunk) {
    _buffer += chunk;
  }

  List<String> takeReady() {
    final outputs = <String>[];
    while (true) {
      _scan();
      if (_flushPosition < 0) break;
      final position = _flushPosition;
      // Wait for lookahead: processing the segment now could only be exact at
      // end of input, and the stream may still continue. The next chunk or
      // finish() resolves it.
      if (_buffer.substring(position).trim().isEmpty) break;

      final segment = _buffer.substring(0, position);
      _consume(position);

      final String result;
      if (_atStart) {
        _startRaw += segment;
        if (stripLeadingMdxImports(_startRaw).trim().isEmpty) {
          // Still inside the document-leading import block; buffer more input
          // so the imports are recognized as starting at the document start.
          continue;
        }
        _atStart = false;
        final raw = _startRaw;
        _startRaw = '';
        result = _strip(raw, options, lookahead: true);
      } else {
        result = _strip(segment, _laterOptions, lookahead: true);
      }

      final output = _holdTail(result);
      if (output.isNotEmpty) outputs.add(output);
    }
    return outputs;
  }

  List<String> finish() {
    final outputs = <String>[];
    if (_atStart) {
      final raw = '$_startRaw$_buffer';
      _startRaw = '';
      _buffer = '';
      _atStart = false;
      final output = removeMd(raw, options);
      if (output.isNotEmpty) outputs.add(output);
      return outputs;
    }
    if (_buffer.isNotEmpty) {
      final output = _strip(_buffer, _laterOptions, lookahead: false);
      _buffer = '';
      if (output.isNotEmpty) outputs.add(output);
    }
    if (_pendingTail.isNotEmpty) {
      outputs.add(_pendingTail);
      _pendingTail = '';
    }
    return outputs;
  }

  /// Strips [segment] together with the whitespace seam held back from the
  /// previous segment and, when [lookahead] is set, a probe representing the
  /// following content.
  String _strip(
    String segment,
    RemoveMarkdownOptions useOptions, {
    required bool lookahead,
  }) {
    final hasTail = _pendingTail.isNotEmpty;
    // Do not inject markers into text that already contains them.
    final markersSafe =
        !segment.contains(_sentinel) &&
        !segment.contains(_probe) &&
        !_pendingTail.contains(_sentinel) &&
        !_pendingTail.contains(_probe);
    final useSentinel = hasTail && markersSafe;
    final useProbe = lookahead && markersSafe;
    var input = hasTail ? '$_pendingTail$segment' : segment;
    if (useSentinel) input = '$_sentinel$input';
    if (useProbe) input += _probe;
    _pendingTail = '';
    var result = removeMd(input, useOptions);
    if (useSentinel) result = result.replaceFirst(_sentinel, '');
    if (useProbe) result = result.replaceFirst(_probe, '');
    return result;
  }

  /// Holds back the trailing whitespace of [result] and returns the rest.
  String _holdTail(String result) {
    final trailing = RegExp(r'\s+$').firstMatch(result);
    if (trailing == null) return result;
    _pendingTail = result.substring(trailing.start);
    return result.substring(0, trailing.start);
  }

  void _consume(int position) {
    _buffer = _buffer.substring(position);
    _scanFrom = 0;
    _fenceOpen = false;
    _flushPosition = -1;
  }

  /// Scans newly buffered complete lines for paragraph boundaries outside
  /// fenced code blocks, remembering the last safe flush position.
  void _scan() {
    var index = _scanFrom;
    while (index < _buffer.length) {
      final newline = _buffer.indexOf('\n', index);
      if (newline < 0) break;
      final line = _buffer.substring(index, newline);
      if (_fenceMarkerCount(line).isOdd) {
        _fenceOpen = !_fenceOpen;
      }
      if (!_fenceOpen && line.trim().isEmpty) {
        _flushPosition = newline + 1;
      }
      index = newline + 1;
    }
    _scanFrom = index;
  }

  /// Counts non-overlapping triple-backtick markers in [line]. Fenced code
  /// blocks start and close with an odd number of markers; inline code such as
  /// ` ```code``` ` has an even number.
  static int _fenceMarkerCount(String line) {
    var count = 0;
    var index = line.indexOf('```');
    while (index >= 0) {
      count++;
      index = line.indexOf('```', index + 3);
    }
    return count;
  }
}

RemoveMarkdownOptions _withoutMdxImports(RemoveMarkdownOptions options) {
  if (!options.stripMdxImports) return options;
  return RemoveMarkdownOptions(
    stripListLeaders: options.stripListLeaders,
    listUnicodeChar: options.listUnicodeChar,
    gfm: options.gfm,
    useImgAltText: options.useImgAltText,
    abbr: options.abbr,
    replaceLinksWithURL: options.replaceLinksWithURL,
    separateLinksAndTexts: options.separateLinksAndTexts,
    htmlTagsToSkip: options.htmlTagsToSkip,
    throwError: options.throwError,
  );
}
