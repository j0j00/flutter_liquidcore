import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../liquidcore.dart';

typedef void OnStartListener(MicroService service);
typedef void OnErrorListener(MicroService service, error);
typedef void OnExitListener(MicroService service, int exitCode);

typedef void EventListener(
    MicroService service, String event, dynamic eventPayload);

class MicroService {
  static final MethodChannel _methodChannel =
      const MethodChannel('$NAMESPACE/microservice')
        ..setMethodCallHandler(_platformCallHandler);

  static final _uuid = new Uuid();
  static final _instances = new Map<String, MicroService>();

  final Map<String, List<EventListener>> _eventListeners = new Map();

  String _instanceId;
  String _uri;
  bool _isStarted = false;
  bool _hasExit = false;

  OnStartListener _onStartListener;
  OnErrorListener _onErrorListener;
  OnExitListener _onExitListener;

  /// Creates a new MicroService instance.
  /// [uri] The URI (can be a network URL or local file/resource) of the MicroService code.
  ///
  /// Example local file URIs are as follows:
  ///   Flutter asset: '@flutter_assets/path/to/asset.js'
  ///   Raw Android assets:
  ///     - 'android.resource://$android_package_name$/raw/script' (without the .js extension)
  ///     - 'file:///android_asset/script.js'
  ///   Raw iOS bundle resource formats:
  ///     - 'Resources/script.js'
  MicroService(String uri,
      [OnStartListener _onStartListener,
      OnErrorListener _onErrorListener,
      OnExitListener _onExitListener]) {
    _instanceId = _uuid.v4();
    _instances[_instanceId] = this;
    this._uri = uri;
    this._onStartListener = _onStartListener;
    this._onErrorListener = _onErrorListener;
    this._onExitListener = _onExitListener;
  }

  /// Return the current Dart UUID.
  String id() {
    return _instanceId;
  }

  /// Start the MicroService.
  /// The initialization and startup will occur asynchronously in a separate thread.
  /// It will download the code from the service URI (if not cached), set the
  /// [arguments] in `process.argv` and execute the script.
  ///
  /// [arguments] is the list of arguments to send to the MicroService. This is similar to running
  /// node from a command line. The first two arguments will be the application (node)
  /// followed by the local module code (/home/module/{service.js}. 'argv' arguments
  /// will then be appended in process.argv[2:]
  Future<void> start([List<String> arguments]) {
    return _invokeMethod("start", {'argv': arguments});
  }

  /// Add an event listener.
  /// These should usually be added before starting the service
  /// so as not to have a race condition with your emissions.
  Future<void> addEventListener(String event, EventListener listener) {
    var listeners = _eventListeners[event];
    if (listeners == null) {
      listeners = new List();
      _eventListeners[event] = listeners;
    }
    listeners.add(listener);
    return _invokeMethod('addEventListener', {'event': event});
  }

  /// Remove event listener.
  Future<bool> removeEventListener(String event, EventListener listener) async {
    var listeners = _eventListeners[event];
    if (listeners != null) {
      var status = await _invokeMethod('removeEventListener', {'event': event}) as bool;
      var removed = listeners.remove(listener);
      if (listeners.isEmpty) {
        _eventListeners.remove(event);
      }
      return status && removed;
    }
    return false;
  }

  /// Exit the MicroService.
  Future<void> exitProcess(int exitCode) async {
    return _invokeMethod('exitProcess', {
      'exitCode': exitCode,
    });
  }

  /// Emit an event.
  Future<void> emit(String event, [dynamic value]) async {
    return _invokeMethod('emit', {
      'event': event,
      'value': value,
    });
  }

  /// Get the internal MicroService id.
  Future<String> getMicroServiceId() async {
    return await _invokeMethod('getId') as String;
  }

  /// Send a message over to the native implementation.
  Future<dynamic> _invokeMethod(String method,
      [Map<String, dynamic> arguments = const {}]) {
    Map<String, dynamic> argWithIds = Map.of(arguments);
    argWithIds['serviceId'] = _instanceId;
    argWithIds['uri'] = _uri;
    return _methodChannel.invokeMethod(method, argWithIds);
  }

  /// Return the development server.
  static Future<String> devServer([String filename, int port]) async {
    return _methodChannel.invokeMethod("devServer", {
      'filename': filename,
      'port': port,
    });
  }

  /// Uninstalls the MicroService from this host, and removes any
  /// global data associated with the service.
  static Future<void> uninstall(String serviceURI) async {
    return _methodChannel.invokeMethod("uninstall", serviceURI);
  }

  static Future<void> _platformCallHandler(MethodCall call) async {
    liquidcoreLog('_platformCallHandler call ${call.method} ${call.arguments}');
    var arguments = (call.arguments as Map);
    String serviceId = arguments['serviceId'] as String;
    MicroService microService = _instances[serviceId];
    if (microService == null) {
      print("MicroService $serviceId was not found!");
      return null;
    }

    dynamic value = arguments['value'];

    try {
      switch (call.method) {
        case 'listener.onStart':
          microService._isStarted = true;
          if (microService._onStartListener != null) {
            microService._onStartListener(microService);
          }
          break;
        case 'listener.onError':
          if (microService._onErrorListener != null) {
            microService._onErrorListener(microService, value);
          }
          break;
        case 'listener.onExit':
          microService._hasExit = true;
          if (microService._onExitListener != null) {
            microService._onExitListener(microService, value as int);
          }
          break;
        case 'listener.onEvent':
          String event = value['event'] as String;
          dynamic payload = value['payload'];
          var listeners = microService._eventListeners[event];
          if (listeners != null) {
            // Notify the listeners.
            listeners.forEach((listener) {
              listener(microService, event, payload);
            });
          }
          break;
        default:
          liquidcoreLog('Unknown method called ${call.method}!');
      }
    } catch (e, stacktrace) {
      print("Unexpected error occurred: $e");
      print('Stack trace:\n $stacktrace');
      rethrow;
    }
  }

  set onStartListener(OnStartListener value) {
    _onStartListener = value;
  }

  set onErrorListener(OnErrorListener value) {
    _onErrorListener = value;
  }

  set onExitListener(OnExitListener value) {
    _onExitListener = value;
  }

  bool get hasExit => _hasExit;

  bool get isStarted => _isStarted;
}
