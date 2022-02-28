import 'package:mustache_template/mustache.dart' as m;
import 'package:mustache_template/src/ability.dart';
import 'package:meta/meta.dart';

import 'node.dart';
import 'parser.dart' as parser;
import 'renderer.dart';
import 'template_exception.dart';

/// Passed as an argument to a mustache lambda function.
class LambdaContext extends m.LambdaContext with HasSource,LambdaCtxWritable {
  final Node _node;
  final Renderer _renderer;
  bool _closed = false;

  LambdaContext(this._node, this._renderer);

  void close() {
    _closed = true;
  }

  void _checkClosed() {
    if (_closed) throw _error('LambdaContext accessed outside of callback.');
  }

  @internal
  bool get isClosed => _closed;

  @internal
  Renderer get renderer => _renderer;

  @internal
  Node get node =>_node;

  TemplateException _error(String msg) {
    return TemplateException(
        msg, _renderer.templateName, _renderer.source, _node.start);
  }

  @override
  String renderString({Object? value}) {
    _checkClosed();
    if (_node is! SectionNode) {
      _error(
          'LambdaContext.renderString() can only be called on section tags.');
    }
    final sink = StringBuffer();
    _renderSubtree(sink, value);
    return sink.toString();
  }

  void _renderSubtree(StringSink sink, Object? value) {
    final renderer = Renderer.subtree(_renderer, sink);
    final section = _node as SectionNode;
    if (value != null) renderer.push(value);
    renderer.render(section.children);
  }

  @override
  void render({Object? value}) {
    _checkClosed();
    if (_node is! SectionNode) {
      _error('LambdaContext.render() can only be called on section tags.');
    }
    _renderSubtree(_renderer.sink, value);
  }

  @internal
  void checkClosedOrThrow() => _checkClosed();

  @override
  String get source {
    _checkClosed();

    if(_node is SectionNode) {
     final node = _node as SectionNode;
      if(node.children.isEmpty){
       return '';
      } else {
        if(node.children.length == 1 && node.children.first is TextNode) {
          return (node.children.single as TextNode).text;
        } else {
          return _renderer.source.substring(node.contentStart, node.contentEnd);
        }
      }
    }else{
      return '';
     }
  }

  @override
  String renderSource(String source, {Object? value}) {
    _checkClosed();
    final sink = StringBuffer();

    // Lambdas used for sections should parse with the current delimiters.
    final delimiters =  _node is SectionNode ? (_node as SectionNode).delimiters : '{{ }}';

    final nodes = parser.parse(
        source, _renderer.lenient, _renderer.templateName, delimiters);

    final renderer =
        Renderer.lambda(_renderer, source, _renderer.indent, sink, delimiters);

    if (value != null) renderer.push(value);
    renderer.render(nodes);

    return sink.toString();
  }

  @override
  Object? lookup(String variableName) {
    _checkClosed();
    return _renderer.resolveValue(variableName);
  }
}
