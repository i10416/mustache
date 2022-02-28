library mustache_test;

import 'package:mustache_template/mustache.dart';
import 'package:test/test.dart';

const MISMATCHED_TAG = 'Mismatched tag';
const UNEXPECTED_EOF = 'Unexpected end of input';
const BAD_VALUE_SECTION = 'Invalid value type for section';
const BAD_VALUE_INV_SECTION = 'Invalid value type for inverse section';
const BAD_TAG_NAME = 'Unless in lenient mode, tags may only contain';
const VALUE_NULL = 'Value was null or missing';
const VALUE_MISSING = 'Value was missing';
const UNCLOSED_TAG = 'Unclosed tag';

Template parse(String source, {bool lenient = false}) =>
    Template(source, lenient: lenient);

class NestedVarClass {
  final String foo;
  NestedVarClass(this.foo);
}

class NestedSectionClass {
  final NestedVarClass v;
  NestedSectionClass(this.v);
}

class SectionClass {
  final NestedSectionClass section;
  SectionClass(this.section);
}

class ClassWithOptionalParamMethod {
  String myMethod([String value = 'hello']) => value;
}

void main() {
  group('Basic', () {
    test('Variable', () {
      final output = parse('_{{var}}_').renderString({'var': 'bob'});
      expect(output, equals('_bob_'));
    });
    test('Comment', () {
      final output = parse('_{{! i am a\n comment ! }}_').renderString(<dynamic,dynamic>{});
      expect(output, equals('__'));
    });
  });
  group('Section', () {
    test('Map', () {
      final output = parse('{{#section}}_{{var}}_{{/section}}').renderString({
        'section': {'var': 'bob'}
      });
      expect(output, equals('_bob_'));
    });
    test('List', () {
      final output = parse('{{#section}}_{{var}}_{{/section}}').renderString({
        'section': [
          {'var': 'bob'},
          {'var': 'jim'}
        ]
      });
      expect(output, equals('_bob__jim_'));
    });
    test('Empty List', () {
      final output = parse('{{#section}}_{{var}}_{{/section}}')
          .renderString({'section': <dynamic>[]});
      expect(output, equals(''));
    });
    test('False', () {
      final output = parse('{{#section}}_{{var}}_{{/section}}')
          .renderString({'section': false});
      expect(output, equals(''));
    });
    test('Invalid value', () {
      final ex = renderFail('{{#section}}_{{var}}_{{/section}}', {'section': 42});
      expect(ex is TemplateException, isTrue);
      expect(ex.message, startsWith(VALUE_MISSING));
    });
    test('Invalid value - lenient mode', () {
      final output = parse('{{#var}}_{{var}}_{{/var}}', lenient: true)
          .renderString({'var': 42});
      expect(output, equals('_42_'));
    });

    test('True', () {
      final output =
          parse('{{#section}}_ok_{{/section}}').renderString({'section': true});
      expect(output, equals('_ok_'));
    });

    test('Nested', () {
      final output = parse(
              '{{#section}}.{{var}}.{{#nested}}_{{nestedvar}}_{{/nested}}.{{/section}}')
          .renderString({
        'section': {
          'var': 'bob',
          'nested': [
            {'nestedvar': 'jim'},
            {'nestedvar': 'sally'}
          ]
        }
      });
      expect(output, equals('.bob._jim__sally_.'));
    });

    test('Whitespace in section tags', () {
      expect(
          parse('{{#foo.bar}}oi{{/foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{# foo.bar}}oi{{/foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{#foo.bar }}oi{{/foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{# foo.bar }}oi{{/foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{#foo.bar}}oi{{/ foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{#foo.bar}}oi{{/foo.bar }}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{#foo.bar}}oi{{/ foo.bar }}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
      expect(
          parse('{{# foo.bar }}oi{{/ foo.bar }}').renderString({
            'foo': {'bar': true}
          }),
          equals('oi'));
    });

    test('Whitespace in variable tags', () {
      expect(
          parse('{{foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('true'));
      expect(
          parse('{{ foo.bar}}').renderString({
            'foo': {'bar': true}
          }),
          equals('true'));
      expect(
          parse('{{foo.bar }}').renderString({
            'foo': {'bar': true}
          }),
          equals('true'));
      expect(
          parse('{{ foo.bar }}').renderString({
            'foo': {'bar': true}
          }),
          equals('true'));
    });

    test('Odd whitespace in tags', () {
      void render(String source, dynamic values,String output) => expect(
          parse(source, lenient: true).renderString(values), equals(output));

      render('{{\t# foo}}oi{{\n/foo}}', {'foo': true}, 'oi');

      render(
          '{{ # # foo }} {{ oi }} {{ / # foo }}',
          {
            '# foo': [
              {'oi': 'OI!'}
            ]
          },
          ' OI! ');

      render(
          '{{ #foo }} {{ oi }} {{ /foo }}',
          {
            'foo': [
              {'oi': 'OI!'}
            ]
          },
          ' OI! ');

      render(
          '{{\t#foo }} {{ oi }} {{ /foo }}',
          {
            'foo': [
              {'oi': 'OI!'}
            ]
          },
          ' OI! ');

      render('{{{ #foo }}} {{{ /foo }}}', {'#foo': 1, '/foo': 2}, '1 2');

// Invalid - I'm ok with that for now.
//      render(
//        "{{{ { }}}",
//        {'{': 1},
//        '1');

      render('{{\nfoo}}', {'foo': 'bar'}, 'bar');

      render('{{\tfoo}}', {'foo': 'bar'}, 'bar');

      render('{{\t# foo}}oi{{\n/foo}}', {'foo': true}, 'oi');

      render('{{{\tfoo\t}}}', {'foo': true}, 'true');

//FIXME empty, or error in strict mode.
//      render(
//        "{{ > }}",
//        {'>': 'oi'},
//        '');
    });

    test('Empty source', () {
      final t = Template('');
      expect(t.renderString(<dynamic,dynamic>{}), equals(''));
    });

    test('Template name', () {
      final t = Template('', name: 'foo');
      expect(t.name, equals('foo'));
    });

    test('Bad tag', () {
      expect(() => Template('{{{ foo }|'), throwsException);
    });
  });

  group('Inverse Section', () {
    test('Map', () {
      final output = parse('{{^section}}_{{var}}_{{/section}}').renderString({
        'section': {'var': 'bob'}
      });
      expect(output, equals(''));
    });
    test('List', () {
      final output = parse('{{^section}}_{{var}}_{{/section}}').renderString({
        'section': [
          {'var': 'bob'},
          {'var': 'jim'}
        ]
      });
      expect(output, equals(''));
    });
    test('Empty List', () {
      final output =
          parse('{{^section}}_ok_{{/section}}').renderString({'section': <dynamic>[]});
      expect(output, equals('_ok_'));
    });
    test('False', () {
      final output = parse('{{^section}}_ok_{{/section}}')
          .renderString({'section': false});
      expect(output, equals('_ok_'));
    });
    test('Invalid value', () {
      final ex = renderFail('{{^section}}_{{var}}_{{/section}}', {'section': 42});
      expect(ex is TemplateException, isTrue);
      expect(ex.message, startsWith(BAD_VALUE_INV_SECTION));
    });
    test('Invalid value - lenient mode', () {
      final output = parse('{{^var}}_ok_{{/var}}', lenient: true)
          .renderString({'var': 42});
      expect(output, equals(''));
    });
    test('True', () {
      final output =
          parse('{{^section}}_ok_{{/section}}').renderString({'section': true});
      expect(output, equals(''));
    });
  });

  group('Html escape', () {
    test('Escape at start', () {
      final output = parse('_{{var}}_').renderString({'var': '&.'});
      expect(output, equals('_&amp;._'));
    });

    test('Escape at end', () {
      final output = parse('_{{var}}_').renderString({'var': '.&'});
      expect(output, equals('_.&amp;_'));
    });

    test('&', () {
      final output = parse('_{{var}}_').renderString({'var': '&'});
      expect(output, equals('_&amp;_'));
    });

    test('<', () {
      final output = parse('_{{var}}_').renderString({'var': '<'});
      expect(output, equals('_&lt;_'));
    });

    test('>', () {
      final output = parse('_{{var}}_').renderString({'var': '>'});
      expect(output, equals('_&gt;_'));
    });

    test('"', () {
      final output = parse('_{{var}}_').renderString({'var': '"'});
      expect(output, equals('_&quot;_'));
    });

    test("'", () {
      final output = parse('_{{var}}_').renderString({'var': "'"});
      expect(output, equals('_&#x27;_'));
    });

    test('/', () {
      final output = parse('_{{var}}_').renderString({'var': '/'});
      expect(output, equals('_&#x2F;_'));
    });
  });

  group('Invalid format', () {
    test('Mismatched tag', () {
      const source = '{{#section}}_{{var}}_{{/notsection}}';
      final ex = renderFail(source, {
        'section': {'var': 'bob'}
      });
      expectFail(ex, 1, 22, 'Mismatched tag');
    });

    test('Unexpected EOF', () {
      const source = '{{#section}}_{{var}}_{{/section';
      final ex = renderFail(source, {
        'section': {'var': 'bob'}
      });
      expectFail(ex, 1, 31, UNEXPECTED_EOF);
    });

    test('Bad tag name, open section', () {
      const source = r'{{#section$%$^%}}_{{var}}_{{/section}}';
      final ex = renderFail(source, {
        'section': {'var': 'bob'}
      });
      expectFail(ex, null, null, BAD_TAG_NAME);
    });

    test('Bad tag name, close section', () {
      const source = r'{{#section}}_{{var}}_{{/section$%$^%}}';
      final ex = renderFail(source, {
        'section': {'var': 'bob'}
      });
      expectFail(ex, null, null, BAD_TAG_NAME);
    });

    test('Bad tag name, variable', () {
      const source = r'{{#section}}_{{var$%$^%}}_{{/section}}';
      final ex = renderFail(source, {
        'section': {'var': 'bob'}
      });
      expectFail(ex, null, null, BAD_TAG_NAME);
    });

    test('Missing variable', () {
      const source = r'{{#section}}_{{var}}_{{/section}}';
      final ex = renderFail(source, {'section': <dynamic,dynamic>{}});
      expectFail(ex, null, null, VALUE_MISSING);
    });

    // Null variables shouldn't be a problem.
    test('Null variable', () {
      final t = Template('{{#section}}_{{var}}_{{/section}}');
      final output = t.renderString({
        'section': {'var': null}
      });
      expect(output, equals('__'));
    });

    test('Unclosed section', () {
      const source = r'{{#section}}foo';
      final ex = renderFail(source, {'section': <dynamic,dynamic>{}});
      expectFail(ex, null, null, UNCLOSED_TAG);
    });
  });

  group('Lenient', () {
    test('Odd section name', () {
      final output =
          parse(r'{{#section$%$^%}}_{{var}}_{{/section$%$^%}}', lenient: true)
              .renderString({
        r'section$%$^%': {'var': 'bob'}
      });
      expect(output, equals('_bob_'));
    });

    test('Odd variable name', () {
      final output =
          parse(r'{{#section}}_{{var$%$^%}}_{{/section}}', lenient: true)
              .renderString({
        'section': {r'var$%$^%': 'bob'}
      });
      expect(output, equals('_bob_'));
    });

    test('Null variable', () {
      final output = parse(r'{{#section}}_{{var}}_{{/section}}', lenient: true)
          .renderString({
        'section': {'var': null}
      });
      expect(output, equals('__'));
    });

    test('Null section', () {
      final output = parse('{{#section}}_{{var}}_{{/section}}', lenient: true)
          .renderString({'section': null});
      expect(output, equals(''));
    });

// Known failure
//		test('Null inverse section', () {
//			var output = parse('{{^section}}_{{var}}_{{/section}}', lenient: true)
//				.renderString({"section": null}, lenient: true);
//			expect(output, equals(''));
//		});
  });

  group('Escape tags', () {
    test('{{{ ... }}}', () {
      final output = parse('{{{blah}}}').renderString({'blah': '&'});
      expect(output, equals('&'));
    });
    test('{{& ... }}', () {
      final output = parse('{{{blah}}}').renderString({'blah': '&'});
      expect(output, equals('&'));
    });
  });

  group('Partial tag', () {
    String _partialTest(Map<String,dynamic> values, Map<String,String> sources, String renderTemplate,
        {bool lenient = false}) {
      final templates = <String, Template?>{};
      final resolver = (String name) => templates[name];
      for (var k in sources.keys) {
        if(sources[k] == null){
          templates[k] = null;
        }else {
         templates[k] = Template(sources[k]!,
            name: k, lenient: lenient, partialResolver: resolver);
        }
      }
      final t = resolver(renderTemplate);
      return t!.renderString(values);
    }

    test('basic', () {
      final output = _partialTest({'foo': 'bar'},
          {'root': '{{>partial}}', 'partial': '{{foo}}'}, 'root');
      expect(output, 'bar');
    });

    test('missing partial strict', () {
      var threw = false;
      try {
        _partialTest({'foo': 'bar'}, {'root': '{{>partial}}'}, 'root',
            lenient: false);
      } on Exception catch (e) {
        expect(e is TemplateException, isTrue);
        threw = true;
      }
      expect(threw, isTrue);
    });

    test('missing partial lenient', () {
      final output = _partialTest(
          {'foo': 'bar'}, {'root': '{{>partial}}'}, 'root',
          lenient: true);
      expect(output, equals(''));
    });

    test('context', () {
      final output = _partialTest({
        'text': 'content'
      }, {
        'root': '"{{>partial}}"',
        'partial': '*{{text}}*'
      }, 'root', lenient: true);
      expect(output, equals('"*content*"'));
    });

    test('recursion', () {
      final output = _partialTest({
        'content': 'X',
        'nodes': [
          {'content': 'Y', 'nodes': <dynamic>[]}
        ]
      }, {
        'root': '{{>node}}',
        'node': '{{content}}<{{#nodes}}{{>node}}{{/nodes}}>'
      }, 'root', lenient: true);
      expect(output, equals('X<Y<>>'));
    });

    test('standalone without previous', () {
      final output = _partialTest(
          {}, {'root': '  {{>partial}}\n>', 'partial': '>\n>'}, 'root',
          lenient: true);
      expect(output, equals('  >\n  >>'));
    });

    test('standalone indentation', () {
      final output = _partialTest({
        'content': '<\n->'
      }, {
        'root': '\\\n {{>partial}}\n\/\n',
        'partial': '|\n{{{content}}}\n|\n'
      }, 'root', lenient: true);
      expect(output, equals('\\\n |\n <\n->\n |\n\/\n'));
    });
  });

  group('Lambdas', () {
    void _lambdaTest({required String template, required String Function(dynamic) lambda, required String output}) => expect(
        parse(template).renderString({'lambda': lambda}), equals(output));

    test('basic', () {
      _lambdaTest(
          template: 'Hello, {{lambda}}!',
          lambda: (_) => 'world',
          output: 'Hello, world!');
    });

    test('escaping', () {
      _lambdaTest(
          template: '<{{lambda}}{{{lambda}}}',
          lambda: (_) => '>',
          output: '<&gt;>');
    });

    test('sections', () {
      _lambdaTest(
          template: '{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}',
          lambda: (LambdaContext ctx) => '__${ctx.renderString()}__',
          output: '__FILE__ != __LINE__');
    });

    //FIXME
    test('inverted sections truthy', () {
      const template = '<{{^lambda}}{{static}}{{/lambda}}>';
      final values = {'lambda': (_) => false, 'static': 'static'};
      const output = '<>';
      expect(parse(template).renderString(values), equals(output));
    }, skip: 'skip test');

    test("seth's use case", () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (ctx) => ctx.renderString().toLowerCase(),
        'content': 'OI YOU!'
      };
      const output = '<oi you!>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('Lambda v2', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {'markdown': (ctx) => ctx.source, 'content': 'OI YOU!'};
      const output = '<{{content}}>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('Lambda v2...', () {
      const template = '<{{#markdown}}dsfsf dsfsdf dfsdfsd{{/markdown}}>';
      final values = {'markdown': (ctx) => ctx.source};
      const output = '<dsfsf dsfsdf dfsdfsd>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('Alternate Delimiters', () {
      // A lambda's return value should parse with the default delimiters.

      const template = '{{= | | =}}\nHello, (|&lambda|)!';

      //function() { return "|planet| => {{planet}}" }
      final values = {
        'planet': 'world',
        'lambda': (LambdaContext ctx) =>
            ctx.renderSource('|planet| => {{planet}}')
      };

      const output = 'Hello, (|planet| => world)!';

      expect(parse(template).renderString(values), equals(output));
    });

    test('Alternate Delimiters 2', () {
      // Lambdas used for sections should parse with the current delimiters.

      const template = '{{= | | =}}<|#lambda|-|/lambda|>';

      //function() { return "|planet| => {{planet}}" }
      final values = {
        'planet': 'Earth',
        'lambda': (LambdaContext ctx) {
          final txt = ctx.source;
          return ctx.renderSource('$txt{{planet}} => |planet|$txt');
        }
      };

      const output = '<-{{planet}} => Earth->';

      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext.lookup', () {
      final t = Template('{{ foo }}');
      final s = t.renderString({'foo': (lc) => lc.lookup('bar'), 'bar': 'jim'});
      expect(s, equals('jim'));
    });

    test('LambdaContext.lookup closed', () {
      final t = Template('{{ foo }}');
      var lc2;
      t.renderString({'foo': (lc) => lc2 = lc, 'bar': 'jim'});
      expect(() => lc2.lookup('foo'), throwsException);
    });
  });

  group('Other', () {
    test('Standalone line', () {
      final val = parse('|\n{{#bob}}\n{{/bob}}\n|').renderString({'bob': <dynamic>[]});
      expect(val, equals('|\n|'));
    });
  });

  group('Array indexing', () {
    test('Basic', () {
      final val = parse('{{array.1}}').renderString({
        'array': [1, 2, 3]
      });
      expect(val, equals('2'));
    });
    test('RangeError', () {
      final error = renderFail('{{array.5}}', {
        'array': [1, 2, 3]
      });
      expect(error, isA<TemplateException>());
    });
  });

  group('Delimiters', () {
    test('Basic', () {
      final val = parse('{{=<% %>=}}(<%text%>)').renderString({'text': 'Hey!'});
      expect(val, equals('(Hey!)'));
    });

    test('Single delimiters', () {
      final val = parse('({{=[ ]=}}[text])').renderString({'text': 'It worked!'});
      expect(val, equals('(It worked!)'));
    });
  });

  group('Template with custom delimiters', () {
    test('Basic', () {
      final t = Template('(<%text%>)', delimiters: '<% %>');
      final val = t.renderString({'text': 'Hey!'});
      expect(val, equals('(Hey!)'));
    });
  });

  group('Lambda context', () {
    test('LambdaContext write', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (ctx) {
          ctx.write('foo');
        }
      };
      const  output = '<foo>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext render', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'content': 'bar',
        'markdown': (ctx) {
          ctx.render();
        }
      };
      const output = '<bar>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext render with value', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (LambdaContext ctx) {
          ctx.render(value: {'content': 'oi!'});
        }
      };
      const output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext renderString with value', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (LambdaContext ctx) {
          return ctx.renderString(value: {'content': 'oi!'});
        }
      };
      const output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext write and return', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (LambdaContext ctx) {
          ctx.write('foo');
          return 'bar';
        }
      };
      const output = '<foobar>';
      expect(parse(template).renderString(values), equals(output));
    });

    test('LambdaContext renderSource with value', () {
      const template = '<{{#markdown}}{{content}}{{/markdown}}>';
      final values = {
        'markdown': (LambdaContext ctx) {
          return ctx.renderSource(ctx.source, value: {'content': 'oi!'});
        }
      };
      const output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));
    });
  });
}

dynamic renderFail(String source, dynamic values) {
  try {
    parse(source).renderString(values);
    return null;
  } on Exception catch (e) {
    return e;
  }
}

void expectFail(dynamic ex, int? line, int? column, [String? msgStartsWith]) {
  expect(ex is TemplateException, isTrue);
  if (line != null) expect(ex.line, equals(line));
  if (column != null) expect(ex.column, equals(column));
  if (msgStartsWith != null) expect(ex.message, startsWith(msgStartsWith));
}
