import 'package:mustache_template/src/node.dart';
import 'package:mustache_template/src/parser.dart';
import 'package:mustache_template/src/scanner.dart';
import 'package:mustache_template/src/template_exception.dart';
import 'package:mustache_template/src/token.dart';
import 'package:test/test.dart';

void main() {
  group('Scanner', () {
    test('scan text', () {
      const source = 'abc';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [Token(TokenType.text, 'abc', 0, 3)]);
    });

    test('scan tag', () {
      const source = 'abc{{foo}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{', 3, 5),
        Token(TokenType.identifier, 'foo', 5, 8),
        Token(TokenType.closeDelimiter, '}}', 8, 10),
        Token(TokenType.text, 'def', 10, 13)
      ]);
    });

    test('scan tag whitespace', () {
      const source = 'abc{{ foo }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{', 3, 5),
        Token(TokenType.whitespace, ' ', 5, 6),
        Token(TokenType.identifier, 'foo', 6, 9),
        Token(TokenType.whitespace, ' ', 9, 10),
        Token(TokenType.closeDelimiter, '}}', 10, 12),
        Token(TokenType.text, 'def', 12, 15)
      ]);
    });

    test('scan tag sigil', () {
      const source = 'abc{{ # foo }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{', 3, 5),
        Token(TokenType.whitespace, ' ', 5, 6),
        Token(TokenType.sigil, '#', 6, 7),
        Token(TokenType.whitespace, ' ', 7, 8),
        Token(TokenType.identifier, 'foo', 8, 11),
        Token(TokenType.whitespace, ' ', 11, 12),
        Token(TokenType.closeDelimiter, '}}', 12, 14),
        Token(TokenType.text, 'def', 14, 17)
      ]);
    });

    test('scan tag dot', () {
      const source = 'abc{{ foo.bar }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{', 3, 5),
        Token(TokenType.whitespace, ' ', 5, 6),
        Token(TokenType.identifier, 'foo', 6, 9),
        Token(TokenType.dot, '.', 9, 10),
        Token(TokenType.identifier, 'bar', 10, 13),
        Token(TokenType.whitespace, ' ', 13, 14),
        Token(TokenType.closeDelimiter, '}}', 14, 16),
        Token(TokenType.text, 'def', 16, 19)
      ]);
    });

    test('scan triple mustache', () {
      const source = 'abc{{{foo}}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{{', 3, 6),
        Token(TokenType.identifier, 'foo', 6, 9),
        Token(TokenType.closeDelimiter, '}}}', 9, 12),
        Token(TokenType.text, 'def', 12, 15)
      ]);
    });

    test('scan triple mustache whitespace', () {
      const source = 'abc{{{ foo }}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.text, 'abc', 0, 3),
        Token(TokenType.openDelimiter, '{{{', 3, 6),
        Token(TokenType.whitespace, ' ', 6, 7),
        Token(TokenType.identifier, 'foo', 7, 10),
        Token(TokenType.whitespace, ' ', 10, 11),
        Token(TokenType.closeDelimiter, '}}}', 11, 14),
        Token(TokenType.text, 'def', 14, 17)
      ]);
    });

    test('scan tag with equals', () {
      const source = '{{foo=bar}}';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.openDelimiter, '{{', 0, 2),
        Token(TokenType.identifier, 'foo=bar', 2, 9),
        Token(TokenType.closeDelimiter, '}}', 9, 11),
      ]);
    });

    test('scan comment with equals', () {
      const source = '{{!foo=bar}}';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        Token(TokenType.openDelimiter, '{{', 0, 2),
        Token(TokenType.sigil, '!', 2, 3),
        Token(TokenType.identifier, 'foo=bar', 3, 10),
        Token(TokenType.closeDelimiter, '}}', 10, 12),
      ]);
    });
  });

  group('Parser', () {
    test('parse variable', () {
      const source = 'abc{{foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc', 0, 3),
        VariableNode('foo', 3, 10, escape: true),
        TextNode('def', 10, 13)
      ]);
    });

    test('parse variable whitespace', () {
      const source = 'abc{{ foo }}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc', 0, 3),
        VariableNode('foo', 3, 12, escape: true),
        TextNode('def', 12, 15)
      ]);
    });

    test('parse section', () {
      const source = 'abc{{#foo}}def{{/foo}}ghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc', 0, 3),
        SectionNode('foo', 3, 11, '{{ }}'),
        TextNode('ghi', 22, 25)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [TextNode('def', 11, 14)]);
    });

    test('parse section standalone tag whitespace', () {
      const source = 'abc\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n', 0, 4),
        SectionNode('foo', 4, 12, '{{ }}'),
        TextNode('ghi', 26, 29)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace consecutive', () {
      const source = 'abc\n{{#foo}}\ndef\n{{/foo}}\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n', 0, 4),
        SectionNode('foo', 4, 12, '{{ }}'),
        SectionNode('foo', 26, 34, '{{ }}'),
        TextNode('ghi', 48, 51),
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace on first line', () {
      const source = '  {{#foo}}  \ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(
          nodes, [SectionNode('foo', 2, 10, '{{ }}'), TextNode('ghi', 26, 29)]);
      expectNodes(
          (nodes[0] as SectionNode).children, [TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace on last line', () {
      const source = '{{#foo}}def\n  {{/foo}}  ';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [SectionNode('foo', 0, 8, '{{ }}')]);
      expectNodes(
          (nodes[0] as SectionNode).children, [TextNode('def\n', 8, 12)]);
    });

    test('parse variable newline', () {
      const source = 'abc\n\n{{foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n\n', 0, 5),
        VariableNode('foo', 5, 12, escape: true),
        TextNode('def', 12, 15)
      ]);
    });

    test('parse section standalone tag whitespace v2', () {
      const source = 'abc\n\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n\n', 0, 5),
        SectionNode('foo', 5, 13, '{{ }}'),
        TextNode('ghi', 27, 30)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [TextNode('def\n', 14, 18)]);
    });

    test('parse whitespace', () {
      const source = 'abc\n   ';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n   ', 0, 7),
      ]);
    });

    test('parse partial', () {
      const source = 'abc\n   {{>foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('abc\n   ', 0, 7),
        PartialNode('foo', 7, 15, '   '),
        TextNode('def', 15, 18)
      ]);
    });

    test('parse change delimiters', () {
      const source = '{{= | | =}}<|#lambda|-|/lambda|>';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        TextNode('<', 11, 12),
        SectionNode('lambda', 12, 21, '| |'),
        TextNode('>', 31, 32),
      ]);
      expect((nodes[1] as SectionNode).delimiters, equals('| |'));
      expectNodes((nodes[1] as SectionNode).children, [TextNode('-', 21, 22)]);
    });

    test('corner case strict', () {
      const source = '{{{ #foo }}} {{{ /foo }}}';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      try {
        parser.parse();
        fail('Should fail.');
      } on Exception catch (e) {
        expect(e is TemplateException, isTrue);
      }
    });

    test('corner case lenient', () {
      const source = '{{{ #foo }}} {{{ /foo }}}';
      final parser = Parser(source, 'foo', '{{ }}', lenient: true);
      final nodes = parser.parse();
      expectNodes(nodes, [
        VariableNode('#foo', 0, 12, escape: false),
        TextNode(' ', 12, 13),
        VariableNode('/foo', 13, 25, escape: false)
      ]);
    });

    test('toString', () {
      TextNode('foo', 1, 3).toString();
      VariableNode('foo', 1, 3).toString();
      PartialNode('foo', 1, 3, ' ').toString();
      SectionNode('foo', 1, 3, '{{ }}').toString();
      Token(TokenType.closeDelimiter, 'foo', 1, 3).toString();
      TokenType.closeDelimiter.toString();
    });

    test('exception', () {
      const source = "'{{ foo }} sdfffffffffffffffffffffffffffffffffffffffffffff "
          'dsfsdf sdfdsa fdsfads fsdfdsfadsf dsfasdfsdf sdfdsfsadf sdfadsfsdf ';
      final ex = TemplateException('boom!', 'foo.mustache', source, 2);
      ex.toString();
    });

    dynamic parseFail(String source) {
      try {
        final parser = Parser(source, 'foo', '{{ }}', lenient: false);
        parser.parse();
        fail('Did not throw.');
      } on Exception catch (ex, st) {
        if (ex is! TemplateException) {
          // ignore: avoid_print
          print(ex);
          // ignore: avoid_print
          print(st);
        }
        return ex;
      }
    }

    test('parse eof', () {
      void expectTemplateEx(dynamic ex) => expect(ex is TemplateException, isTrue);

      expectTemplateEx(parseFail('{{#foo}}{{bar}}{{/foo}'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}}{{/foo'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}}{{/'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}}{{'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}}{'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}}'));
      expectTemplateEx(parseFail('{{#foo}}{{bar}'));
      expectTemplateEx(parseFail('{{#foo}}{{bar'));
      expectTemplateEx(parseFail('{{#foo}}{{'));
      expectTemplateEx(parseFail('{{#foo}}{'));
      expectTemplateEx(parseFail('{{#foo}}'));
      expectTemplateEx(parseFail('{{#foo}'));
      expectTemplateEx(parseFail('{{#'));
      expectTemplateEx(parseFail('{{'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ / foo }'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ / foo '));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ / foo'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ / '));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ /'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{ '));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{{'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}{'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }}'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar }'));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar '));
      expectTemplateEx(parseFail('{{ # foo }}{{ bar'));
      expectTemplateEx(parseFail('{{ # foo }}{{ '));
      expectTemplateEx(parseFail('{{ # foo }}{{'));
      expectTemplateEx(parseFail('{{ # foo }}{'));
      expectTemplateEx(parseFail('{{ # foo }}'));
      expectTemplateEx(parseFail('{{ # foo }'));
      expectTemplateEx(parseFail('{{ # foo '));
      expectTemplateEx(parseFail('{{ # foo'));
      expectTemplateEx(parseFail('{{ # '));
      expectTemplateEx(parseFail('{{ #'));
      expectTemplateEx(parseFail('{{ '));
      expectTemplateEx(parseFail('{{'));

      expectTemplateEx(parseFail('{{= || || =}'));
      expectTemplateEx(parseFail('{{= || || ='));
      expectTemplateEx(parseFail('{{= || || '));
      expectTemplateEx(parseFail('{{= || ||'));
      expectTemplateEx(parseFail('{{= || |'));
      expectTemplateEx(parseFail('{{= || '));
      expectTemplateEx(parseFail('{{= ||'));
      expectTemplateEx(parseFail('{{= |'));
      expectTemplateEx(parseFail('{{= '));
      expectTemplateEx(parseFail('{{='));
    });
  });
}

bool nodeEqual(Node a,Node b) {
  if (a is TextNode) {
    return b is TextNode &&
        a.text == b.text &&
        a.start == b.start &&
        a.end == b.end;
  } else if (a is VariableNode) {
    return  b is VariableNode &&   a.name == b.name &&
        a.escape == b.escape &&
        a.start == b.start &&
        a.end == b.end;
  } else if (a is SectionNode) {
    return  b is SectionNode &&  a.name == b.name &&
        a.delimiters == b.delimiters &&
        a.inverse == b.inverse &&
        a.start == b.start &&
        a.end == b.end;
  } else if (a is PartialNode) {
    return  b is PartialNode && a.name == b.name && a.indent == b.indent;
  } else {
    return false;
  }
}

bool tokenEqual(Token a, Token b) {
  return a.type == b.type &&
      a.value == b.value &&
      a.start == b.start &&
      a.end == b.end;
}

void expectTokens(List<Token> a, List<Token> b) {
  expect(a.length, equals(b.length), reason: '$a != $b');
  for (var i = 0; i < a.length; i++) {
    expect(tokenEqual(a[i], b[i]), isTrue, reason: '$a != $b');
  }
}

void expectNodes(List<Node> a, List<Node> b) {
  expect(a.length, equals(b.length), reason: '$a != $b');
  for (var i = 0; i < a.length; i++) {
    expect(nodeEqual(a[i], b[i]), isTrue, reason: '$a != $b');
  }
}
