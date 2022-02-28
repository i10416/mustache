


import 'package:mustache_template/src/lambda_context.dart';

import 'package:mustache_template/mustache.dart' as m;

mixin HasSource {
  /// The template source.
  String get source;
}

mixin Writable<T>{
  T? get self;
  void write(Object object);
}

mixin LambdaCtxWritable on m.LambdaContext implements Writable<LambdaContext> {
  LambdaContext? get self => this is LambdaContext ? this as LambdaContext : null;
  @override
  void write(Object object) {
    if(self == null){
      throw UnimplementedError();
    }else {
      self as LambdaContext;
      self!.checkClosedOrThrow();
      self!.renderer.write(object);
    }
  }
}
