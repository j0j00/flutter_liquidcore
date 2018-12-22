//import 'package:flutter_test/flutter_test.dart';
//import 'package:flutter_driver/driver_extension.dart';
//
//import 'package:liquidcore/liquidcore.dart';
//
///// TODO: Implement proper integration tests.
//void main() {
//  test('test jsContext properties', () async {
//    enableFlutterDriverExtension();
//
//    final jsContext = JSContext();
//    const code = """
//    // Attached as a property of the current global context scope.
//    var obj = {
//      number: 1,
//      string: 'string',
//      date: new Date(2000, 0, 1), // 01/01/2000
//      array: [1, 'string', null, undefined],
//      func: function () {}
//    };
//    var a = 10;
//    // Is a variable, and not attached as a property of the context.
//    let objLet = { number: 1, yayForLet: true };
//    """;
//    await jsContext.evaluateScript(code);
//    var obj = await jsContext.property('obj');
//    expect(obj['number'], 1);
//    expect(obj['string'], 'string');
//    expect(obj['date'], '1');
//    expect(obj['array'].length, 4);
//
//    expect(await jsContext.property("a"), 10);
//
//    expect(() async => await jsContext.property("objLet"), throwsNoSuchMethodError);
//    expect((await jsContext.evaluateScript("objLet"))['yayForLet'], true);
//  });
//}
