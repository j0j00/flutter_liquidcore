import Flutter
import UIKit

public class SwiftLiquidcorePlugin: NSObject, FlutterPlugin {
    
    public static var NAMESPACE : String = "io.jojodev.flutter.liquidcore"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        MicroServiceHandler.register(with: registrar)
        JsContextHandler.register(with: registrar)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Unused stub.
        result(FlutterMethodNotImplemented)
    }

    /**
     * Convert arguments to dart objects.
     *
     * @param args Object[]
     * @return Serializable arguments.
     * @see io.flutter.plugin.common.StandardMessageCodec#writeValue
     */
    public static func convertToDartObjects(args: [Any?], jsContext: JSContext? = nil) -> Array<Any?> {
        var allowedArgs = [Any?]();
        for value in args {
            allowedArgs.append(convertToDartObject(value, jsContext));
        }
        
        return allowedArgs;
    }
    
    /**
     * Convert objects into a format that can be easily digested by Dart.
     * @param value the object to transform.
     * @return the transformed object.
     */
    public static func convertToDartObject(
        _ value : Any?,
        _ jsContext: JSContext? = nil
    ) -> Any? {
        if ((value == nil || value is NSNull) ||
            value is NSNumber ||
            (value is NSString || value is String) ||
            value is FlutterStandardTypedData
            ) {
            return value;
        } else if var array = value as? [Any] {
            for (key,value) in array.enumerated() {
                // Attempt to recursively convert objects into a format that can be read by Flutter.
                array[key] = convertToDartObject(value, jsContext) as Any
            }
            return array
        } else if var dict = value as? Dictionary<AnyHashable, Any> {
            for (key,value) in dict {
                // Attempt to recursively convert objects into a format that can be read by Flutter.
                dict[key] = convertToDartObject(value, jsContext)
            }
            return dict
        } else if let date = value as? Date {
            // Convert to ISO_8601 format.
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.string(from: date)
        } else {
            if let jsValue = value as? JSValue {
                if (jsValue.isNull || jsValue.isUndefined || jsValue.isNumber || jsValue.isString || jsValue.isBoolean) {
                    // Safe to pass.
                    return jsValue.toObject()
                }

                if (jsValue.isObject) {
                    if(jsValue.hasProperty("__dart_liquidcore_function_id__")) {
                        // This really only works if it's returning a function that was originally
                        // passed in from Dart.
                        var map : Dictionary<String, Any> = Dictionary();
                        map["__dart_liquidcore_type__"] = "function";
                        map["__dart_liquidcore_ref__"] = jsValue.forProperty("__dart_liquidcore_function_id__")?.toString();
                        return map;
                    }

                    /*
                    let typeofFn = jsContext?.globalObject.forProperty("__liquidcore_typeof__")
                    let typeof : String = (typeofFn?.call(withArguments: [jsValue])?.toString())!
                    print(typeof)
                    */

                    let isErrorFn = jsContext?.globalObject.forProperty("__liquidcore_is_error__")
                    let isError : Bool = (isErrorFn?.call(withArguments: [jsValue])?.toBool())!
                    if (isError) {
                        var map : Dictionary<String, Any> = Dictionary()
                        map["__dart_liquidcore_type__"] = "exception"
                        map["type"] = jsValue.forProperty("name")?.toString()
                        map["message"] = jsValue.forProperty("message")?.toString()
                        map["stack"] = jsValue.forProperty("stack")?.toString()
                        return map
                    }
                }

                let safeObjectFn = jsContext?.globalObject.forProperty("__liquidcore_safe_object__")
                let safeObject: JSValue? = safeObjectFn?.call(withArguments: [jsValue])
                return safeObject?.toObject()
            }

            if let error = value as? NSError {
                var map : Dictionary<String, Any> = Dictionary();
                map["__dart_liquidcore_type__"] = "exception"
                map["type"] = error.domain;
                map["message"] = error.localizedDescription;
                map["stack"] = Thread.callStackSymbols;
                return map;
            } else {
                return String(describing: value);
            }
        }
    }
}
