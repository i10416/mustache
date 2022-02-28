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
      expectTokens(tokens, [const Token(TokenType.text, 'abc', 0, 3)]);
    });

    test('scan tag', () {
      const source = 'abc{{foo}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{', 3, 5),
        const Token(TokenType.identifier, 'foo', 5, 8),
        const Token(TokenType.closeDelimiter, '}}', 8, 10),
        const Token(TokenType.text, 'def', 10, 13)
      ]);
    });

    test('scan tag whitespace', () {
      const source = 'abc{{ foo }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{', 3, 5),
        const Token(TokenType.whitespace, ' ', 5, 6),
        const Token(TokenType.identifier, 'foo', 6, 9),
        const Token(TokenType.whitespace, ' ', 9, 10),
        const Token(TokenType.closeDelimiter, '}}', 10, 12),
        const Token(TokenType.text, 'def', 12, 15)
      ]);
    });

    test('scan tag sigil', () {
      const source = 'abc{{ # foo }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{', 3, 5),
        const Token(TokenType.whitespace, ' ', 5, 6),
        const Token(TokenType.sigil, '#', 6, 7),
        const Token(TokenType.whitespace, ' ', 7, 8),
        const Token(TokenType.identifier, 'foo', 8, 11),
        const Token(TokenType.whitespace, ' ', 11, 12),
        const Token(TokenType.closeDelimiter, '}}', 12, 14),
        const Token(TokenType.text, 'def', 14, 17)
      ]);
    });

    test('scan tag dot', () {
      const source = 'abc{{ foo.bar }}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{', 3, 5),
        const Token(TokenType.whitespace, ' ', 5, 6),
        const Token(TokenType.identifier, 'foo', 6, 9),
        const Token(TokenType.dot, '.', 9, 10),
        const Token(TokenType.identifier, 'bar', 10, 13),
        const Token(TokenType.whitespace, ' ', 13, 14),
        const Token(TokenType.closeDelimiter, '}}', 14, 16),
        const Token(TokenType.text, 'def', 16, 19)
      ]);
    });

    test('scan triple mustache', () {
      const source = 'abc{{{foo}}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{{', 3, 6),
        const Token(TokenType.identifier, 'foo', 6, 9),
        const Token(TokenType.closeDelimiter, '}}}', 9, 12),
        const Token(TokenType.text, 'def', 12, 15)
      ]);
    });

    test('scan triple mustache whitespace', () {
      const source = 'abc{{{ foo }}}def';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.text, 'abc', 0, 3),
        const Token(TokenType.openDelimiter, '{{{', 3, 6),
        const Token(TokenType.whitespace, ' ', 6, 7),
        const Token(TokenType.identifier, 'foo', 7, 10),
        const Token(TokenType.whitespace, ' ', 10, 11),
        const Token(TokenType.closeDelimiter, '}}}', 11, 14),
        const Token(TokenType.text, 'def', 14, 17)
      ]);
    });

    test('scan tag with equals', () {
      const source = '{{foo=bar}}';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.openDelimiter, '{{', 0, 2),
        const Token(TokenType.identifier, 'foo=bar', 2, 9),
        const Token(TokenType.closeDelimiter, '}}', 9, 11),
      ]);
    });

    test('scan comment with equals', () {
      const source = '{{!foo=bar}}';
      final scanner = Scanner(source, 'foo', '{{ }}');
      final tokens = scanner.scan();
      expectTokens(tokens, [
        const Token(TokenType.openDelimiter, '{{', 0, 2),
        const Token(TokenType.sigil, '!', 2, 3),
        const Token(TokenType.identifier, 'foo=bar', 3, 10),
        const Token(TokenType.closeDelimiter, '}}', 10, 12),
      ]);
    });
  });

  group('Parser', () {
    test('parse variable', () {
      const source = 'abc{{foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc', 0, 3),
        const VariableNode('foo', 3, 10, escape: true),
        const TextNode('def', 10, 13)
      ]);
    });

    test('parse variable whitespace', () {
      const source = 'abc{{ foo }}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc', 0, 3),
        const VariableNode('foo', 3, 12, escape: true),
        const TextNode('def', 12, 15)
      ]);
    });

    test('parse section', () {
      const source = 'abc{{#foo}}def{{/foo}}ghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc', 0, 3),
        SectionNode('foo', 3, 11, '{{ }}'),
        const TextNode('ghi', 22, 25)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [const TextNode('def', 11, 14)]);
    });

    test('parse section standalone tag whitespace', () {
      const source = 'abc\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n', 0, 4),
        SectionNode('foo', 4, 12, '{{ }}'),
        const TextNode('ghi', 26, 29)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [const TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace consecutive', () {
      const source = 'abc\n{{#foo}}\ndef\n{{/foo}}\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n', 0, 4),
        SectionNode('foo', 4, 12, '{{ }}'),
        SectionNode('foo', 26, 34, '{{ }}'),
        const TextNode('ghi', 48, 51),
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [const TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace on first line', () {
      const source = '  {{#foo}}  \ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(
          nodes, [SectionNode('foo', 2, 10, '{{ }}'), const TextNode('ghi', 26, 29)]);
      expectNodes(
          (nodes[0] as SectionNode).children, [const TextNode('def\n', 13, 17)]);
    });

    test('parse section standalone tag whitespace on last line', () {
      const source = '{{#foo}}def\n  {{/foo}}  ';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [SectionNode('foo', 0, 8, '{{ }}')]);
      expectNodes(
          (nodes[0] as SectionNode).children, [const TextNode('def\n', 8, 12)]);
    });

    test('parse variable newline', () {
      const source = 'abc\n\n{{foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n\n', 0, 5),
        const VariableNode('foo', 5, 12, escape: true),
        const TextNode('def', 12, 15)
      ]);
    });

    test('parse section standalone tag whitespace v2', () {
      const source = 'abc\n\n{{#foo}}\ndef\n{{/foo}}\nghi';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n\n', 0, 5),
        SectionNode('foo', 5, 13, '{{ }}'),
        const TextNode('ghi', 27, 30)
      ]);
      expectNodes(
          (nodes[1] as SectionNode).children, [const TextNode('def\n', 14, 18)]);
    });

    test('parse whitespace', () {
      const source = 'abc\n   ';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n   ', 0, 7),
      ]);
    });

    test('parse partial', () {
      const source = 'abc\n   {{>foo}}def';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('abc\n   ', 0, 7),
        const PartialNode('foo', 7, 15, '   '),
        const TextNode('def', 15, 18)
      ]);
    });

    test('parse change delimiters', () {
      const source = '{{= | | =}}<|#lambda|-|/lambda|>';
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      final nodes = parser.parse();
      expectNodes(nodes, [
        const TextNode('<', 11, 12),
        SectionNode('lambda', 12, 21, '| |'),
        const TextNode('>', 31, 32),
      ]);
      expect((nodes[1] as SectionNode).delimiters, equals('| |'));
      expectNodes((nodes[1] as SectionNode).children, [const TextNode('-', 21, 22)]);
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
        const VariableNode('#foo', 0, 12, escape: false),
        const TextNode(' ', 12, 13),
        const VariableNode('/foo', 13, 25, escape: false)
      ]);
    });

    test('toString', () {
      const TextNode('foo', 1, 3).toString();
      const VariableNode('foo', 1, 3).toString();
      const PartialNode('foo', 1, 3, ' ').toString();
      SectionNode('foo', 1, 3, '{{ }}').toString();
      const Token(TokenType.closeDelimiter, 'foo', 1, 3).toString();
      TokenType.closeDelimiter.toString();
    });

    test('exception', () {
      const source = "'{{ foo }} sdfffffffffffffffffffffffffffffffffffffffffffff "
          'dsfsdf sdfdsa fdsfads fsdfdsfadsf dsfasdfsdf sdfdsfsadf sdfadsfsdf ';
      final ex = TemplateException('boom!', 'foo.mustache', source, 2);
      ex.toString();
    });

    dynamic attemptLenient(String source) {
      final parser = Parser(source, 'foo', '{{ }}', lenient: false);
      parser.parse();
    }
    Matcher exceptionOfType<T extends Object>() => TypeMatcher<T>();
    test('parse eof', () {
      expect(()=>attemptLenient('{{#foo}}{{bar}}{{/foo}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}{{/foo}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}{{/foo'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}{{/'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}{{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{bar'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#foo}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{#'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ / foo }'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ / foo '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ / foo'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ / '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ /'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{ '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar }'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ bar'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{ '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}{'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo }'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # foo'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ # '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ #'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{ '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{'),throwsA(exceptionOfType<TemplateException>()));

      expect(()=>attemptLenient('{{= || || =}'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= || || ='),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= || || '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= || ||'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= || |'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= || '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= ||'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= |'),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{= '),throwsA(exceptionOfType<TemplateException>()));
      expect(()=>attemptLenient('{{='),throwsA(exceptionOfType<TemplateException>()));
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
