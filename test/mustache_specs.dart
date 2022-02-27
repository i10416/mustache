// Specification files can be downloaded here https://github.com/mustache/spec

// Test implemented by Georgios Valotasios.
// See: https://github.com/valotas/mustache4dart

library mustache_specs;

import 'dart:convert';
import 'dart:io';

import 'package:mustache_template/mustache.dart';
import 'package:test/test.dart';

String render(source, values, {partial}) {
  late Template? Function(String) resolver;
  resolver = (name) {
    final source = partial(name);
    if (source == null) return null;
    return Template(source, partialResolver: resolver, lenient: true);
  };
  final t = Template(source, partialResolver: resolver, lenient: true);
  return t.renderString(values);
}

void main() {
  defineTests();
}

void defineTests() {
  final specs_dir = Directory('test/spec/specs');
  specs_dir.listSync().forEach((f) {
    if (f is File) {
      final filename = f.path;
      if (shouldRun(filename)) {
        final text = f.readAsStringSync(encoding: utf8);
        _defineGroupFromFile(filename, text);
      }
    }
  });
}

void _defineGroupFromFile(filename, text) {
  final jsondata = json.decode(text) as Map<String,dynamic>;
  final tests = (jsondata['tests'] as Iterable<dynamic>).cast<Map<String,dynamic>>();
  filename = filename.substring(filename.lastIndexOf('/') + 1);
  group('Specs of $filename', () {
    tests.forEach((t) {
      final testDescription = StringBuffer(t['name'])
        ..write(': ')
        ..write(t['desc']);
      final String template = t['template'];
      final data = int.tryParse(t['data'].toString()) ?? (t['data'] is  Map<String,dynamic> ?  t['data'] as Map<String,dynamic> : t['data'] as String);
      final templateOneline =
      template.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
      final reason =
      StringBuffer("Could not render right '''$templateOneline'''");
      var expected = t['expected'];
      var partials = t['partials'];
      var partial = (String name) {
        if (partials == null) {
          return null;
        }
        return partials[name];
      };

      //swap the data.lambda with a dart real function
      if (data is Map<String,dynamic> && data['lambda'] != null) {
        data['lambda'] = lambdas[t['name'].toString()];
      }
      reason.write(" with '$data'");
      if (partials != null) {
        reason.write(' and partial: $partials');
      }
      test(
          testDescription.toString(),
              () => expect(render(template, data, partial: partial), expected,
              reason: reason.toString()));
    });
  });
}

bool shouldRun(String filename) {
  // filter out only .json files
  if (!filename.endsWith('.json')) {
    return false;
  }
  return true;
}

Function _dummyCallableWithState() {
  var _callCounter = 0;
  return (arg) {
    _callCounter++;
    return _callCounter.toString();
  };
}

Function wrapLambda(Function f) =>
        (LambdaContext ctx) => ctx.renderSource(f(ctx.source).toString());

final lambdas = {
  'Interpolation': wrapLambda((t) => 'world'),
  'Interpolation - Expansion': wrapLambda((t) => '{{planet}}'),
  'Interpolation - Alternate Delimiters':
  wrapLambda((t) => '|planet| => {{planet}}'),
  'Interpolation - Multiple Calls': wrapLambda(
      _dummyCallableWithState()), //function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }
  'Escaping': wrapLambda((t) => '>'),
  'Section': wrapLambda((txt) => txt == '{{x}}' ? 'yes' : 'no'),
  'Section - Expansion': wrapLambda((txt) => '$txt{{planet}}$txt'),
  'Section - Alternate Delimiters':
  wrapLambda((txt) => '$txt{{planet}} => |planet|$txt'),
  'Section - Multiple Calls': wrapLambda((t) => '__${t}__'),
  'Inverted Section': wrapLambda((txt) => false)
};
