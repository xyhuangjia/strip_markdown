import 'package:strip_markdown/strip_markdown.dart';
import 'package:test/test.dart';

void main() {
  group('remove Markdown', () {
    group('removeMd', () {
      test('should leave a string alone without markdown', () {
        const string = 'Javascript Developers are the best.';
        expect(removeMd(string), equals(string));
      });

      test('should strip out remaining markdown', () {
        const string = '*Javascript* developers are the _best_.';
        const expected = 'Javascript developers are the best.';
        expect(removeMd(string), equals(expected));
      });

      test('should leave non-matching markdown markdown', () {
        const string = '*Javascript* developers* are the _best_.';
        const expected = 'Javascript developers* are the best.';
        expect(removeMd(string), equals(expected));
      });

      test('should leave non-matching markdown, but strip empty anchors', () {
        const string = '*Javascript* [developers]()* are the _best_.';
        const expected = 'Javascript developers* are the best.';
        expect(removeMd(string), equals(expected));
      });

      test('should strip HTML', () {
        const string = '<p>Hello World</p>';
        const expected = 'Hello World';
        expect(removeMd(string), equals(expected));
      });

      group('MDX imports', () {
        group('stripMdxImports', () {
          test('should strip MDX import statements', () {
            const tests = [
              (
                'import page404 from "@/assets/images/404.png"\n\n'
                    'Here is some text',
                'Here is some text',
              ),
              ('import "mycomponent.astro";\nWelcome back!', 'Welcome back!'),
              (
                "import { Validator as val } from '../util.js'\n"
                    'Super imports?',
                'Super imports?',
              ),
              (
                'import page404 from "@/assets/images/404.png";\n'
                    'import page403 from "@/assets/images/403.png";\n\n'
                    'Some errors, huh',
                'Some errors, huh',
              ),
              (
                "\nimport a from 'b'\n"
                    "import * as a from 'b'\n"
                    "import {a} from 'b'\n"
                    "import {a as b} from 'c'\n"
                    "import a, {b as c} from 'd'\n"
                    "import a, * as b from 'c'\n"
                    "import 'a'",
                '',
              ),
              ('import "with-carrier-return"\r\nA', 'A'),
              (
                'After text:\nimport "keep-it!"',
                'After text:\nimport "keep-it!"',
              ),
            ];
            for (final (markdown, expected) in tests) {
              expect(
                removeMd(
                  markdown,
                  const RemoveMarkdownOptions(stripMdxImports: true),
                ),
                equals(expected),
              );
            }
          });

          test('should not strip import statements from code blocks', () {
            const string =
                'import test from "module";\n```\nimport test from "module";\n'
                'test.run();```';
            const expected = 'import test from "module";\ntest.run();';
            expect(
              removeMd(
                string,
                const RemoveMarkdownOptions(stripMdxImports: true),
              ),
              equals(expected),
            );
          });

          test('should not strip MDX imports by default', () {
            const string = 'import test from "module";\n';
            expect(removeMd(string), equals(string));
          });

          group('MDX import regressions', () {
            const mdxOptions = RemoveMarkdownOptions(stripMdxImports: true);

            final imports = <String>[
              'import { A, B } from "pkg";',
              'import { A, B as C, } from "pkg";',
              'import Default, { A, B as C } from "pkg";',
              'import {\n  A,\n  B as C,\n} from "pkg";',
              'import Default,\n{ A, B }\nfrom "pkg";',
              'import {} from "pkg";',
              r'import $Component from "pkg";',
              'import  Default from "pkg";',
              'import Default, * as components from "pkg";',
              r"import Component from 'path/with\'quote';",
            ];

            for (final statement in imports) {
              test('should strip ${statement.replaceAll('\n', r'\n')}', () {
                final string = '$statement\nimport Next from "next";\n\n# Text';
                expect(removeMd(string, mdxOptions), equals('Text'));
                expect(removeMd(statement, mdxOptions), equals(''));
                expect(removeMd(statement), equals(statement));
                expect(
                  removeMd(
                    statement,
                    // ignore: avoid_redundant_argument_values
                    const RemoveMarkdownOptions(stripMdxImports: false),
                  ),
                  equals(statement),
                );
              });
            }

            for (final newline in ['\n', '\r\n']) {
              test(
                'should consume trailing and blank-line whitespace with '
                '${newline.replaceAll('\r', r'\r').replaceAll('\n', r'\n')}',
                () {
                  final string =
                      ' \t$newline'
                      'import A from "a"; \t$newline'
                      ' \t$newline'
                      'import { B, C } from "b" \t; \t$newline'
                      '\t $newline# Text';
                  expect(removeMd(string, mdxOptions), equals('Text'));
                },
              );
            }

            test('should consume trailing whitespace at EOF', () {
              expect(removeMd('import A from "a"; \t', mdxOptions), equals(''));
            });

            final contentCases = <(String, String, String)>[
              (
                'a list item',
                '- import "data"\n\nText',
                'import "data"\n\nText',
              ),
              (
                'an ordered list item',
                '1. import "data"\n\nText',
                'import "data"\n\nText',
              ),
              (
                'quoted prose in a list',
                '- import "data" using the "Import" button.',
                'import "data" using the "Import" button.',
              ),
              (
                'quoted prose',
                'import "data" using the "Import" button.',
                'import "data" using the "Import" button.',
              ),
              (
                'indented code',
                '    import A from "a";\n\nText',
                '    import A from "a";\n\nText',
              ),
              (
                'a horizontal rule',
                '---\nimport A from "a";\n\nText',
                'import A from "a";\n\nText',
              ),
              (
                'a heading',
                '# Heading\n\nimport A from "a";\n\nText',
                'Heading\n\nimport A from "a";\n\nText',
              ),
              (
                'a code fence',
                '```js\nimport A from "a";\n```',
                'import A from "a";',
              ),
              (
                'a trailing comment',
                'import A from "a"; // comment\n\nText',
                'import A from "a"; // comment\n\nText',
              ),
              (
                'an unsupported import',
                'import A from "a" with { type: "json" };\n'
                    'import B from "b";',
                'import A from "a" with { type: "json" };\n'
                    'import B from "b";',
              ),
            ];

            for (final (name, string, expected) in contentCases) {
              test('should preserve content after $name', () {
                expect(removeMd(string, mdxOptions), equals(expected));
                expect(
                  removeMd('import First from "first";\n\n$string', mdxOptions),
                  equals(expected),
                );
              });
            }

            test('should preserve list options when stripping imports', () {
              const string = 'import First from "first";\n\n- import "data"';
              expect(
                removeMd(
                  string,
                  const RemoveMarkdownOptions(
                    stripMdxImports: true,
                    stripListLeaders: false,
                  ),
                ),
                equals('- import "data"'),
              );
              expect(
                removeMd(
                  string,
                  const RemoveMarkdownOptions(
                    stripMdxImports: true,
                    listUnicodeChar: '•',
                  ),
                ),
                equals('• import "data"'),
              );
            });
          });
        });
      });

      test('should strip anchors', () {
        const string =
            '*Javascript* [developers](https://engineering.condenast.io/)* are the _best_.';
        const expected = 'Javascript developers* are the best.';
        expect(removeMd(string), equals(expected));
      });

      test('should strip img tags', () {
        const string =
            '![](https://placebear.com/640/480)*Javascript* developers are the _best_.';
        const expected = 'Javascript developers are the best.';
        expect(removeMd(string), equals(expected));
      });

      test('should use the alt-text of an image, if it is provided', () {
        const string =
            '![This is the alt-text](https://www.example.com/images/logo.png)';
        const expected = 'This is the alt-text';
        expect(removeMd(string), equals(expected));
      });

      test('should strip code tags', () {
        const string = 'In `Getting Started` we set up `something` foo.';
        const expected = 'In Getting Started we set up something foo.';
        expect(removeMd(string), equals(expected));
      });

      test('should strip simple multiline code tags', () {
        const string = '```\ncode\n```';
        const expected = 'code';
        expect(removeMd(string), equals(expected));
      });

      test(
        'should strip complex multiline code blocks with language specified',
        () {
          const string =
              '```javascript\nconst x = 1;\nconst y = 2;\nconsole.log(x + y);\n```';
          const expected = 'const x = 1;\nconst y = 2;\nconsole.log(x + y);';
          expect(removeMd(string), equals(expected));
        },
      );

      test('should strip multiline code blocks with multiple paragraphs', () {
        const string =
            'Text before\n\n```\ncode line 1\n\ncode line 2\n```\n\nText after';
        const expected =
            'Text before\n\ncode line 1\n\ncode line 2\n\nText after';
        expect(removeMd(string), equals(expected));
      });

      test('should leave hashtags in headings', () {
        const string = '## This #heading contains #hashtags';
        const expected = 'This #heading contains #hashtags';
        expect(removeMd(string), equals(expected));
      });

      test('should remove emphasis', () {
        const string = 'I italicized an *I* and it _made_ me *sad*.';
        const expected = 'I italicized an I and it made me sad.';
        expect(removeMd(string), equals(expected));
      });

      test(
        'should remove emphasis only if there is no space between word and emphasis characters.',
        () {
          const string =
              'There should be no _space_, *before* *closing * _ephasis character _.';
          const expected =
              'There should be no space, before *closing * _ephasis character _.';
          expect(removeMd(string), equals(expected));
        },
      );

      test(
        'should remove "_" emphasis only if there is space before opening and after closing emphasis characters.',
        () {
          const string =
              '._Spaces_ _ before_ and _after _ emphasised character results in no emphasis.';
          const expected =
              '.Spaces _ before_ and _after _ emphasised character results in no emphasis.';
          expect(removeMd(string), equals(expected));
        },
      );

      test('should remove double emphasis', () {
        const string = '**this sentence has __double styling__**';
        const expected = 'this sentence has double styling';
        expect(removeMd(string), equals(expected));
      });

      test('should not mistake a horizontal rule when symbols are mixed ', () {
        const string = 'Some text on a line\n\n--*\n\nA line below';
        const expected = 'Some text on a line\n\n--*\n\nA line below';
        expect(removeMd(string), equals(expected));
      });

      test('should remove horizontal rules', () {
        const string = 'Some text on a line\n\n---\n\nA line below';
        const expected = 'Some text on a line\n\nA line below';
        expect(removeMd(string), equals(expected));
      });

      test('should remove horizontal rules with space-separated asterisks', () {
        const string = 'Some text on a line\n\n* * *\n\nA line below';
        const expected = 'Some text on a line\n\nA line below';
        expect(removeMd(string), equals(expected));
      });

      test('should remove blockquotes', () {
        const string = '>I am a blockquote';
        const expected = 'I am a blockquote';
        expect(removeMd(string), equals(expected));
      });

      test('should remove blockquotes with spaces', () {
        const string = '> I am a blockquote';
        const expected = 'I am a blockquote';
        expect(removeMd(string), equals(expected));
      });

      test('should remove indented blockquotes', () {
        final tests = [
          {'string': ' > I am a blockquote', 'expected': 'I am a blockquote'},
          {'string': '  > I am a blockquote', 'expected': 'I am a blockquote'},
          {'string': '   > I am a blockquote', 'expected': 'I am a blockquote'},
        ];
        for (final test in tests) {
          expect(removeMd(test['string']!), equals(test['expected']));
        }
      });

      test('should remove blockquotes over multiple lines', () {
        const string =
            '> I am a blockquote firstline  \n>I am a blockquote secondline';
        const expected =
            'I am a blockquote firstline  \nI am a blockquote secondline';
        expect(removeMd(string), equals(expected));
      });

      test('should remove blockquotes following other content', () {
        const string =
            '## A headline\n\nA paragraph of text\n\n> I am a blockquote';
        const expected =
            'A headline\n\nA paragraph of text\n\nI am a blockquote';
        expect(removeMd(string), equals(expected));
      });

      test('should not remove greater than signs', () {
        final tests = [
          {'string': '100 > 0', 'expected': '100 > 0'},
          {'string': '100 >= 0', 'expected': '100 >= 0'},
          {'string': '100>0', 'expected': '100>0'},
          {'string': '> 100 > 0', 'expected': '100 > 0'},
          {'string': '1 < 100', 'expected': '1 < 100'},
          {'string': '1 <= 100', 'expected': '1 <= 100'},
        ];
        for (final test in tests) {
          expect(removeMd(test['string']!), equals(test['expected']));
        }
      });

      test('should strip unordered list leaders', () {
        const string =
            'Some text on a line\n\n* A list Item\n* Another list item';
        const expected =
            'Some text on a line\n\nA list Item\nAnother list item';
        expect(removeMd(string), equals(expected));
      });

      test('should strip ordered list leaders', () {
        const string =
            'Some text on a line\n\n9. A list Item\n10. Another list item';
        const expected =
            'Some text on a line\n\nA list Item\nAnother list item';
        expect(removeMd(string), equals(expected));
      });

      test('should strip list items with bold word in the beginning', () {
        const string =
            'Some text on a line\n\n- **A** list Item\n- **Another** list item';
        const expected =
            'Some text on a line\n\nA list Item\nAnother list item';
        expect(removeMd(string), equals(expected));
      });

      test('should handle paragraphs with markdown', () {
        const paragraph =
            '\n## This is a heading ##\n\nThis is a paragraph with [a link](http://www.disney.com/).\n\n### This is another heading\n\nIn `Getting Started` we set up `something` foo.\n\n  * Some list\n  * With items\n    * Even indented';
        const expected =
            '\nThis is a heading\n\nThis is a paragraph with a link.\n\nThis is another heading\n\nIn Getting Started we set up something foo.\n\n  Some list\n  With items\n    Even indented';
        expect(removeMd(paragraph), equals(expected));
      });

      test('should remove links', () {
        const string = 'This is a [link](http://www.disney.com/).';
        const expected = 'This is a link.';
        expect(removeMd(string), equals(expected));
      });

      test('should remove links with square brackets', () {
        const string =
            'This is a [link [with brackets]](http://www.disney.com/).';
        const expected = 'This is a link [with brackets].';
        expect(removeMd(string), equals(expected));
      });

      test(
        'should not treat a standalone bracket pair as the start of a following link',
        () {
          const string =
              'This is a [link] and [another](http://www.example.com/).';
          const expected = 'This is a [link] and another.';
          expect(removeMd(string), equals(expected));
        },
      );

      test(
        'should keep url instead of text when replaceLinksWithURL is on',
        () {
          const string = 'This is a [link](http://www.disney.com/).';
          const expected = 'This is a http://www.disney.com/.';
          expect(
            removeMd(
              string,
              const RemoveMarkdownOptions(replaceLinksWithURL: true),
            ),
            equals(expected),
          );
        },
      );

      test('should replace inline link with text and link, with separator', () {
        const string = 'some [inline link](http://www.disney.com/).';
        const expected = 'some inline link: http://www.disney.com/.';
        expect(
          removeMd(
            string,
            const RemoveMarkdownOptions(separateLinksAndTexts: ': '),
          ),
          equals(expected),
        );
      });

      test(
        'separateLinksAndTexts should take precedence over replaceLinksWithURL',
        () {
          const string = 'some [inline link](http://www.disney.com/).';
          const expected = 'some inline link: http://www.disney.com/.';
          expect(
            removeMd(
              string,
              const RemoveMarkdownOptions(
                separateLinksAndTexts: ': ',
                replaceLinksWithURL: true,
              ),
            ),
            equals(expected),
          );
        },
      );

      test('empty separateLinksAndTexts should be ignored', () {
        const string = 'some [inline link](http://www.disney.com/).';
        const expected = 'some inline link.';
        expect(
          removeMd(
            string,
            const RemoveMarkdownOptions(separateLinksAndTexts: ''),
          ),
          equals(expected),
        );
      });

      test('should not strip paragraphs without content', () {
        const paragraph = '\n#This paragraph\n##This paragraph#';
        const expected = paragraph;
        expect(removeMd(paragraph), equals(expected));
      });

      test('should not trigger ReDoS with atx-headers', () {
        final start = DateTime.now().millisecondsSinceEpoch;

        final paragraph = '\n## This is a long "${' ' * 200}" heading ##\n';
        final expected = RegExp(r'\nThis is a long " {200}" heading\n');
        expect(removeMd(paragraph), matches(expected));

        final duration = DateTime.now().millisecondsSinceEpoch - start;
        expect(duration, lessThan(1000));
      });

      test('should not trigger ReDoS with brackets', () {
        final start = DateTime.now().millisecondsSinceEpoch;

        final paragraph = '[${'a' * 5000}](${'b' * 5000})';
        expect(removeMd(paragraph), equals('a' * 5000));

        final duration = DateTime.now().millisecondsSinceEpoch - start;
        expect(duration, lessThan(1000));
      });

      test('should work fast even with lots of whitespace', () {
        const string =
            'Some text with lots of                                                                                                                                                                                                       whitespace';
        const expected =
            'Some text with lots of                                                                                                                                                                                                       whitespace';
        expect(removeMd(string), equals(expected));
      });

      // test('should still remove escaped markdown syntax', () {
      //   const string = r'\# Heading in _italic_';
      //   const expected = 'Heading in italic';
      //   expect(removeMd(string), equals(expected));
      // });

      test(
        'should skip specified HTML tags when htmlTagsToSkip option is provided',
        () {
          const markdown =
              '<div>HTML content <sub>Superscript</sub> <span>span text</span></div>';
          final result = removeMd(
            markdown,
            const RemoveMarkdownOptions(htmlTagsToSkip: ['sub']),
          );
          expect(
            result,
            equals('HTML content <sub>Superscript</sub> span text'),
          );

          final result2 = removeMd(
            markdown,
            const RemoveMarkdownOptions(htmlTagsToSkip: ['sub', 'span']),
          );
          expect(
            result2,
            equals(
              'HTML content <sub>Superscript</sub> <span>span text</span>',
            ),
          );
        },
      );

      test(
        'should skip HTML tags with attributes when htmlTagsToSkip is provided',
        () {
          const markdown = '<code class="language-js">const x = 1</code>';
          final result = removeMd(
            markdown,
            const RemoveMarkdownOptions(htmlTagsToSkip: ['code']),
          );
          expect(
            result,
            equals('<code class="language-js">const x = 1</code>'),
          );
        },
      );

      test(
        'should not skip HTML tags whose name merely starts with a skipped tag name',
        () {
          const markdown = '<codes>const x = 1</codes>';
          final result = removeMd(
            markdown,
            const RemoveMarkdownOptions(htmlTagsToSkip: ['code']),
          );
          expect(result, equals('const x = 1'));
        },
      );
    });
  });
}
