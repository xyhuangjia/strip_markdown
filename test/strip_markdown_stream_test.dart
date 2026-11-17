import 'dart:async';
import 'dart:math';

import 'package:strip_markdown/strip_markdown.dart';
import 'package:test/test.dart';

/// Splits [text] into chunks of exactly [size] characters.
List<String> _fixedChunks(String text, int size) {
  final chunks = <String>[];
  for (var i = 0; i < text.length; i += size) {
    chunks.add(text.substring(i, min(i + size, text.length)));
  }
  return chunks;
}

/// Splits [text] at random positions.
List<String> _randomChunks(String text, Random random, int maxSize) {
  final chunks = <String>[];
  var index = 0;
  while (index < text.length) {
    final size = 1 + random.nextInt(maxSize);
    chunks.add(text.substring(index, min(index + size, text.length)));
    index += size;
  }
  return chunks;
}

/// Splits [text] after every newline.
List<String> _lineChunks(String text) {
  final chunks = <String>[];
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n') {
      chunks.add(text.substring(start, i + 1));
      start = i + 1;
    }
  }
  if (start < text.length) chunks.add(text.substring(start));
  return chunks;
}

const _documents = <String>[
  'Javascript Developers are the best.',
  '*Javascript* developers* are the _best_.',
  '*Javascript* [developers]()* are the _best_.',
  '<p>Hello World</p>',
  '# Heading\n\nA paragraph with **bold**, *italic* and [a link](https://example.com).',
  'A paragraph\nwith a **bold** line\nand _emphasis_.\n\nSecond paragraph.\n\n',
  'Text before\n\n```\ncode line 1\n\ncode line 2\n```\n\nText after',
  'Text\n\n~~~\nfenced\n\ncontent\n~~~\n\nAfter',
  'Some text on a line\n\n---\n\nA line below',
  '- One\n- Two\n\n1. First\n2. Second',
  '> Quote\n> second line\n\nNormal\n\n## Heading\n\nText',
  'Title\n===\n\nSetext\n---\n\nNext',
  '[Notes](https://example.com)\n\n[Notes](https://example.com "title")',
  'Read [the notes][notes].\n\n[notes]: https://example.com',
  'This is a [link [with brackets]](http://www.disney.com/).',
  'Some [text](url) then [more](url2).\n\n[A] and [B](c)',
  '![alt](img.png)\n\n![alt [nested]](img.png)',
  'In `Getting Started` we set up `something` foo.\n\nDone',
  'a | b\n--- | ---\n1 | 2\n\n| Name | Value |\n| --- | --- |\n| A | B |',
  'Tea &amp; biscuits.\n\n<p>A <strong>small</strong> detail.</p>',
  '**bold *nested* text**\n\n__double__ and _single_\n\nend',
  'Line with trailing spaces   \n\nNext line   ',
  '100 > 0 and 100 >= 1 and 1 < 2\n\nPlain',
  '*[HTML]: HyperText Markup Language\n\nHTML is useful.\n\nend',
  '\n\n\nLeading blank lines\n\nText',
  'text\r\n\r\nmore\r\n\r\n# Head\r\n\r\nend',
  'import a from "a";\nimport b from "b";\n\n# Title\n\nBody',
  'import {\n  A,\n  B as C,\n} from "pkg";\n\n# Heading\n\nText',
  'Unclosed fence\n\n```js\nconst x = 1;\n\nstill code\n',
  '```code```\n\nnext paragraph',
  'a\n\n```\n\n```\n\nb',
  'Setext\n===\n\n\n---\n---\n\n\nunicode — café 🌿 你好',
  '**bold** ```js\nconst x = 1;\n\nconst y = 2;\n``` - list item',
  '',
  '\n\n',
];

const _variants = <String, RemoveMarkdownOptions>{
  'default': RemoveMarkdownOptions(),
  'stripMdxImports': RemoveMarkdownOptions(stripMdxImports: true),
  'gfm disabled': RemoveMarkdownOptions(gfm: false),
  'list leaders kept': RemoveMarkdownOptions(stripListLeaders: false),
  'list unicode char': RemoveMarkdownOptions(listUnicodeChar: '•'),
  'image alt text removed': RemoveMarkdownOptions(useImgAltText: false),
  'abbreviations removed': RemoveMarkdownOptions(abbr: true),
  'links replaced by URL': RemoveMarkdownOptions(replaceLinksWithURL: true),
  'links separated': RemoveMarkdownOptions(separateLinksAndTexts: ': '),
  'html tags skipped': RemoveMarkdownOptions(htmlTagsToSkip: ['code', 'a']),
};

void main() {
  group('removeMdStream', () {
    group('matches removeMd for arbitrary chunking', () {
      for (final document in _documents) {
        for (final variant in _variants.entries) {
          test('${_describe(document)} with ${variant.key}', () async {
            final options = variant.value;
            final expected = removeMd(document, options);
            final chunkings = <List<String>>[
              [document],
              _fixedChunks(document, 1),
              _fixedChunks(document, 2),
              _fixedChunks(document, 3),
              _fixedChunks(document, 7),
              _lineChunks(document),
              _randomChunks(document, Random(document.length * 31 + 7), 5),
            ];
            for (final chunks in chunkings) {
              final actual = await removeMdStream(
                Stream.fromIterable(chunks),
                options,
              ).join();
              expect(actual, equals(expected), reason: 'chunks=$chunks');
            }
          });
        }
      }
    });

    test(
      'matches removeMd for every two-way split of short documents',
      () async {
        for (final document in _documents.where((d) => d.length <= 80)) {
          final expected = removeMd(document);
          for (var split = 0; split <= document.length; split++) {
            final actual = await removeMdStream(
              Stream.fromIterable([
                document.substring(0, split),
                document.substring(split),
              ]),
            ).join();
            expect(actual, equals(expected), reason: 'split=$split');
          }
        }
      },
    );

    test('matches removeMd for generated documents', () async {
      final random = Random(20261117);
      const tokens = <String>[
        '# Heading',
        '## Sub heading ##',
        'Setext\n===',
        '**bold**',
        '*italic*',
        '_under_',
        '~~strike~~',
        '[link](https://example.com/a?b=1)',
        '[link [nested]](https://e.com)',
        '[notes]: https://example.com "title"',
        '![alt](img.png)',
        '`inline code`',
        '```js\nconst x = 1;\n\nconst y = 2;\n```',
        '- list item',
        '1. ordered',
        '> quote',
        '---',
        '___',
        '<p>html</p>',
        'plain text',
        'import x from "pkg";',
        'a | b',
        'unicode — café 🌿 你好',
      ];
      const separators = <String>['\n', '\n\n', ' ', '', '\r\n'];
      const optionsVariants = <RemoveMarkdownOptions>[
        RemoveMarkdownOptions(),
        RemoveMarkdownOptions(stripMdxImports: true),
        RemoveMarkdownOptions(
          gfm: false,
          listUnicodeChar: '•',
          replaceLinksWithURL: true,
        ),
      ];
      for (var i = 0; i < 40; i++) {
        final parts = <String>[
          for (var j = 0; j < 1 + random.nextInt(5); j++)
            tokens[random.nextInt(tokens.length)],
        ];
        final document = parts.join(
          separators[random.nextInt(separators.length)],
        );
        for (final options in optionsVariants) {
          final expected = removeMd(document, options);
          final chunkings = <List<String>>[
            [document],
            _fixedChunks(document, 1 + random.nextInt(3)),
            _randomChunks(document, random, 12),
            _lineChunks(document),
          ];
          for (final chunks in chunkings) {
            final actual = await removeMdStream(
              Stream.fromIterable(chunks),
              options,
            ).join();
            expect(actual, equals(expected), reason: 'doc=$document');
          }
        }
      }
    });

    test('emits plain text incrementally', () async {
      final chunks = await removeMdStream(
        Stream.fromIterable([
          'First ',
          'paragraph.\n\nSecond ',
          'paragraph.\n\nThird ',
          'paragraph.',
        ]),
      ).toList();
      expect(
        chunks.join(),
        equals('First paragraph.\n\nSecond paragraph.\n\nThird paragraph.'),
      );
      expect(chunks.length, greaterThan(1));
    });

    test('emits nothing for an empty stream', () async {
      final chunks = await removeMdStream(
        const Stream<String>.empty(),
      ).toList();
      expect(chunks, isEmpty);
    });

    test('handles a stream without a trailing newline', () async {
      const markdown = '# Title\n\nA **paragraph** without a final newline.';
      final output = await removeMdStream(
        Stream.fromIterable(_fixedChunks(markdown, 1)),
      ).join();
      expect(output, equals(removeMd(markdown)));
    });

    test('handles text containing the internal marker code points', () async {
      const markdown = 'a\u0000b\n\nc\u0001d\n\ne';
      final output = await removeMdStream(
        Stream.fromIterable(_fixedChunks(markdown, 2)),
      ).join();
      expect(output, equals(removeMd(markdown)));
    });

    test('forwards source stream errors', () async {
      final controller = StreamController<String>();
      final outputs = <String>[];
      Object? error;
      final done = Completer<void>();
      removeMdStream(controller.stream).listen(
        outputs.add,
        onError: (Object streamError) => error = streamError,
        onDone: done.complete,
      );
      controller.add('Some **text**\n\nMore');
      controller.addError(StateError('boom'));
      await controller.close();
      await done.future;
      expect(error, isA<StateError>());
      expect((error! as StateError).message, equals('boom'));
    });

    test('works through Stream.transform', () async {
      const markdown = '# Title\n\nSome **bold** text.';
      final output = await Stream.value(
        markdown,
      ).transform(const RemoveMarkdownTransformer()).join();
      expect(output, equals(removeMd(markdown)));
    });

    group('stripMdxImports', () {
      const mdxDocument =
          'import { Card } from "./components";\n'
          'import "./styles.css";\n\n'
          '# Welcome\n\n'
          'A **fresh** start.';

      test('strips leading imports when enabled', () async {
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(mdxDocument, 3)),
          const RemoveMarkdownOptions(stripMdxImports: true),
        ).join();
        expect(output, equals('Welcome\n\nA fresh start.'));
      });

      test('keeps leading imports by default', () async {
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(mdxDocument, 3)),
        ).join();
        expect(output, equals(removeMd(mdxDocument)));
        expect(output, contains('import { Card }'));
      });

      test('strips imports after leading blank lines', () async {
        const markdown = '\n\n\nimport A from "a";\n\n\n\nText';
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(markdown, 1)),
          const RemoveMarkdownOptions(stripMdxImports: true),
        ).join();
        expect(output, equals('Text'));
      });

      test(
        'does not strip imports that appear later in the document',
        () async {
          const markdown = 'Text\n\nimport A from "a";\n\nMore';
          final output = await removeMdStream(
            Stream.fromIterable(_fixedChunks(markdown, 2)),
            const RemoveMarkdownOptions(stripMdxImports: true),
          ).join();
          expect(output, equals('Text\n\nimport A from "a";\n\nMore'));
        },
      );

      test(
        'strips imports when the stream ends after the import block',
        () async {
          const markdown = 'import A from "a";\n';
          final output = await removeMdStream(
            Stream.fromIterable(_fixedChunks(markdown, 2)),
            const RemoveMarkdownOptions(stripMdxImports: true),
          ).join();
          expect(output, isEmpty);
        },
      );
    });

    group('options', () {
      test('replaces list leaders with a unicode character', () async {
        const markdown = '- One\n- Two';
        const options = RemoveMarkdownOptions(listUnicodeChar: '•');
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(markdown, 2)),
          options,
        ).join();
        expect(output, equals('• One\n• Two'));
        expect(output, equals(removeMd(markdown, options)));
      });

      test('replaces links with their URL', () async {
        const markdown = 'This is a [link](http://www.disney.com/).';
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(markdown, 3)),
          const RemoveMarkdownOptions(replaceLinksWithURL: true),
        ).join();
        expect(output, equals('This is a http://www.disney.com/.'));
      });

      test('keeps link text and URL joined by the separator', () async {
        const markdown = 'some [inline link](http://www.disney.com/).';
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(markdown, 4)),
          const RemoveMarkdownOptions(separateLinksAndTexts: ': '),
        ).join();
        expect(output, equals('some inline link: http://www.disney.com/.'));
      });

      test('preserves skipped HTML tags', () async {
        const markdown = '<code class="language-js">const x = 1</code>';
        final output = await removeMdStream(
          Stream.fromIterable(_fixedChunks(markdown, 5)),
          const RemoveMarkdownOptions(htmlTagsToSkip: ['code']),
        ).join();
        expect(output, equals(markdown));
      });
    });
  });
}

String _describe(String document) {
  final label = document.length > 40
      ? '${document.substring(0, 40)}...'
      : document;
  return label.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
}
