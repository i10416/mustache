import 'package:mustache_template/mustache.dart';

mixin Renderable {}


extension RenderString on Renderable {
  String renderString2(dynamic values) {
    if(this is Template){
      return (this as Template).renderString(values);
    }else if(this is LambdaContext) {
      return (this as LambdaContext).renderString(value:values);
    } else {
      throw UnimplementedError();
    }
  }
}