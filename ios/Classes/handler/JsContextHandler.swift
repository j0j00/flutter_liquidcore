import Flutter

/**
 * WIP: Need to implement properly.
 * It currently allows you to evaluate javascript and get properties back.
 * As well as provide basic functionality for returning references to callback objects.
 */
public class JsContextHandler : NSObject, FlutterPlugin, FlutterStreamHandler {
    private final var lockFile = DispatchQueue(label: "com.liquidcore.jscontext")
    private final var instances : Dictionary<String, WrappedJSContext> = Dictionary<String, WrappedJSContext>()

    private var jsContextChannel : FlutterMethodChannel
    private var eventSink : FlutterEventSink?

    public class func register(with registrar: FlutterPluginRegistrar) {
        _ = JsContextHandler(registrar)
    }

    private init(_ registrar: FlutterPluginRegistrar) {
        jsContextChannel = FlutterMethodChannel(name: SwiftLiquidcorePlugin.NAMESPACE + "/jscontext", binaryMessenger: registrar.messenger())
        super.init()
        registrar.addMethodCallDelegate(self, channel: jsContextChannel)

        let contextException = FlutterEventChannel(name: SwiftLiquidcorePlugin.NAMESPACE + "/jscontextException", binaryMessenger: registrar.messenger())
        contextException.setStreamHandler(self)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try handleMethodCall(call, result)
        } catch {
            print(Thread.callStackSymbols)
            result(FlutterError(code: "exception", message: error.localizedDescription, details: SwiftLiquidcorePlugin.convertToDartObject(error)))
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let args = call.arguments
        let argsDict:Dictionary<String, Any> = args as! Dictionary<String, Any>
        let contextId : String = argsDict["contextId"] as! String

        let wrappedJsContext : WrappedJSContext = getOrCreateInstance(contextId)
        let jsContext : JSContext = wrappedJsContext.getJSContext()
        let globalObject = jsContext.globalObject

        if ("evaluateScript" == call.method) {
            let script : String? = argsDict["script"] as? String
            let sourceURLString : String? = argsDict["sourceURL"] as? String
            let sourceURL = sourceURLString == nil ? nil : URL(string: sourceURLString!)
            if (script == nil) {
                result(FlutterError(code: "error", message: "Please specify a script!", details: nil))
                return
            }
            let response = SwiftLiquidcorePlugin.convertToDartObject(jsContext.evaluateScript(script, withSourceURL: sourceURL), jsContext)
            let jsContextException = jsContext.exception
            if (jsContextException != nil) {
                // Uncaught exception occurred, handle it.
                jsContext.exception = nil
                result(FlutterError(code: "exception", message: jsContextException?.toString(), details: SwiftLiquidcorePlugin.convertToDartObject(jsContextException, jsContext)))
                return
            }
            result(response)
        } else if ("setExceptionHandler" == call.method) {
            jsContext.exceptionHandler = {
                (context, exception) -> Void in
                self.eventSink?(JsContextHandler.buildArguments(contextId, exception))
            }
            result(nil)
        } else if ("clearExceptionHandler" == call.method) {
            jsContext.exceptionHandler = nil
            result(nil)
        } else if ("property" == (call.method)) {
            let prop : String = argsDict["prop"] as! String
            result(SwiftLiquidcorePlugin.convertToDartObject(globalObject?.forProperty(prop), jsContext))
        } else if ("setProperty" == (call.method)) {
            let prop : String = argsDict["prop"] as! String
            var value : Any? = argsDict["value"]
            let attr : Int = argsDict["attr"] as? Int ?? 0
            let type : String? = argsDict["type"] as? String

            if ("function" == type) {
                // Returns a promise.
                let functionId : String = value as! String
                let dartCb: @convention(block) (JSValue, JSValue, [Any]) -> Any = { resolve, error, args in
                    var arguments : Dictionary<String, Any> = JsContextHandler.buildArguments(contextId, SwiftLiquidcorePlugin.convertToDartObjects(args: args, jsContext: JSContext.current()))
                    arguments["functionId"] = functionId
                    self.jsContextChannel.invokeMethod("dynamicFunction", arguments: arguments, result: { (result) in
                        if let flutterError = result as? FlutterError {
                            error.call(withArguments: [flutterError.message ?? "Unexpected flutter error"])
                        } /*else if let notImplemented = result as? FlutterMethodNotImplemented {
                            error.call(withArguments: ["dynamicFunction not implemented!"])
                        }*/ else {
                            resolve.call(withArguments: [result as Any])
                        }
                    })
                    return NSNull()
                }

                let code : String = "(function (dartCb) {\n" +
                        "  return function () {\n" +
                        "    let args = arguments;\n" +
                        "    return new Promise((resolve, error) => {\n" +
                        "      return dartCb.call(dartCb, resolve, error, [].slice.call(args));\n" +
                        "    })\n" +
                        "  };\n" +
                        "})"

                let anon = jsContext.evaluateScript(code)
                let jsValue = anon!.call(withArguments: [unsafeBitCast(dartCb, to: AnyObject.self)]) // Return the promise.
                // Store a reference to the dart function's uuid.
                jsValue!.setValue(functionId, forProperty: "__dart_liquidcore_function_id__")
                value = jsValue
            }

            if(attr != 0) {
                var descriptor = Dictionary<String, Any>()
                if (attr & kJSPropertyAttributeReadOnly != 0) { // 2
                    // JSPropertyAttributeReadOnly
                    descriptor[JSPropertyDescriptorWritableKey] = false
                }
                if (attr & kJSPropertyAttributeDontEnum != 0) { // 4
                    // JSPropertyAttributeDontEnum
                    descriptor[JSPropertyDescriptorEnumerableKey] = false
                }
                if (attr & kJSPropertyAttributeDontDelete != 0) { // 8
                    // JSPropertyAttributeDontDelete
                    descriptor[JSPropertyDescriptorConfigurableKey] = false
                }
                globalObject?.defineProperty(prop, descriptor: nil)
            }
            globalObject?.setValue(value, forProperty: prop)
            result(nil)
        } else if ("hasProperty" == (call.method)) {
            let prop : String = argsDict["prop"] as! String
            result(globalObject?.hasProperty(prop))
        } else if ("deleteProperty" == (call.method)) {
            let prop : String = argsDict["prop"] as! String
            result(globalObject?.deleteProperty(prop))
        } else if ("cleanUp" == (call.method)) {
            // Remove all references to the jsContext.
            lockFile.sync {
                instances.removeValue(forKey: contextId)
                wrappedJsContext.freeUp()
            }
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }

    private func getOrCreateInstance(_ key : String) -> WrappedJSContext {
        return lockFile.sync {
            var instance : WrappedJSContext? = instances[key]
            if (instance == nil) {
                instance = WrappedJSContext()
                instances[key] = instance
            }
            return instance!
        }
    }

    private class func buildArguments(_ contextId : String, _ value : Any?) -> Dictionary<String, Any> {
        var result : Dictionary<String, Any> = Dictionary()
        result["contextId"] = contextId
        result["value"] = value
        return result
    }
}
