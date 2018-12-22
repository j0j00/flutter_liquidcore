import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_liquidcore/liquidcore.dart';

void main() {
  enableLiquidCoreLogging = true;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Random _rng;
  MicroService _microService;
  JSContext _jsContext;

  String _jsContextResponse = '<empty>';
  String _microServiceResponse = '<empty>';
  int _microServiceWorld = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FlutterLiquidcore App'),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: const Text('MicroService'),
                onPressed: initMicroService,
              ),
              Center(
                child: Text('MicroService response: $_microServiceResponse\n'),
              ),
              RaisedButton(
                child: const Text('Execute JSContext'),
                onPressed: _initializeJsContext,
              ),
              Center(
                child: Text('JSContext response: $_jsContextResponse\n'),
              )
            ]),
      ),
    );
  }

  @override
  void dispose() {
    if (_microService != null) {
      // Free up the resources.
      _microService.exitProcess(0);
    }
    if (_jsContext != null) {
      // Free up the context resources.
      _jsContext.cleanUp();
    }
    super.dispose();
  }

  void _initializeJsContext() async {
    if (Platform.isAndroid) {
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        if (_jsContext == null) {
          _jsContext = new JSContext();
          const code = """
        // Attached as a property of the current global context scope.
        var obj = {
          number: 1,
          string: 'string',
          date: new Date(),
          array: [1, 'string', null, undefined], 
          func: function () {}
        };
        var a = 10;
        // Is a variable, and not attached as a property of the context.
        let objLet = { number: 1, yayForLet: true };
        """;
          await _jsContext.evaluateScript(code);
          try {
            // Evaluate an invalid javascript call.
            await _jsContext.evaluateScript('invalid.call()');
          } catch(e) {
            print(e);
          }
          try {
            // Catch an exception.
            await _jsContext.evaluateScript('throw new Error("My exception message")');
          } catch(e) {
            print(e);
          }
          // This will return a promise object, but you won't be able to manipulate it from Dart.
          var promise = await _jsContext.evaluateScript('''
            var response;
            (async () => {
              response = await Promise.reject();
            })();
            ''');
          var obj = await _jsContext.property("obj");
          var aValue = await _jsContext.property("a");
          var objLet = await _jsContext.evaluateScript("objLet");

          // Add factorial function.
          await _jsContext.setProperty("factorial", (double x) {
            int factorial = 1;
            for (; x > 1; x--) {
              factorial *= x.toInt();
            }
            return factorial;
          });
          // Return a declared function (currently only works with dart functions).
          var factorialFn = await _jsContext.property("factorial");

          await _jsContext.setProperty("factorialThen",
              (double factorial) async {
            var f = await _jsContext.property("f");
            _setJsContextResponse(
                "Factorial of ${f.toInt()} = ${factorial.toInt()} !");

            return factorial;
          });

          print("******************************");
          print("obj = $obj");
          print("a = $aValue");
          print("promise = $promise");
          print("objLet = $objLet");
          print("factorialFn = ${factorialFn.runtimeType.toString()}");
          print("******************************");
        }

        if (_rng == null) {
          _rng = new Random();
        }
        // Generate a random number.
        var factorialNumber = _rng.nextInt(10);
        await _jsContext.setProperty("f", factorialNumber);
        await _jsContext.evaluateScript("factorial(f).then(factorialThen);");

        //returnVal = await context.evaluateScript("( function(){ return factorial($factorialNumber).then(factorialThen) })() ");
      } on PlatformException {
        _setJsContextResponse('Failed to get factorial from Javascript. $e');
      }
    } else {
      _setJsContextResponse('JSContext is only supported on Android.');
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initMicroService() async {
    if (_microService == null) {
      String uri;
      if (Platform.isAndroid) {
        // Android doesn't allow dashes in the res/raw directory.
        uri = "android.resource://io.jojodev.flutter.liquidcoreexample/raw/liquidcore_sample";
      } else {
        uri = "Resources/liquidcore_sample";
      }

      _microService = new MicroService(uri);
      await _microService.addEventListener('ready',
          (service, event, eventPayload) {
        // The service is ready.
        if (!mounted) {
          return;
        }
        //_emit();
      });
      await _microService.addEventListener('pong',
          (service, event, eventPayload) {
        if (!mounted) {
          return;
        }

        _setMicroServiceResponse(eventPayload['message']);
      });

      // Start the service.
      await _microService.start();
    }

    if (_microService.isStarted) {
      _emit();
    }
  }

  _emit() async {
    // Send the name over to the MicroService.
    await _microService.emit('ping', 'World ${++_microServiceWorld}');
  }

  _setMicroServiceResponse(message) {
    setState(() {
      _microServiceResponse = message;
    });
  }

  _setJsContextResponse(value) {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _jsContextResponse = value;
    });
  }
}
