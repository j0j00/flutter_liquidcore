import Flutter
import UIKit

public protocol IMicroServiceListener : LCMicroServiceEventListener, LCMicroServiceDelegate {}

public class MicroServiceHandler : NSObject, FlutterPlugin {

    private static var microServiceMethodChannel : FlutterMethodChannel?

    private final var microServices : Dictionary<String, WrappedMicroService> = Dictionary<String, WrappedMicroService>()
    private final let microServicesMapLocker = DispatchQueue(label: "com.liquidcore.microservices")

    private final var registrar : FlutterPluginRegistrar

    private init(_ registrar : FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    /**
     * Plugin registration.
     */
    public static func register(with registrar: FlutterPluginRegistrar) {
        microServiceMethodChannel = FlutterMethodChannel(name: SwiftLiquidcorePlugin.NAMESPACE + "/microservice", binaryMessenger: registrar.messenger())

        let instance = MicroServiceHandler(registrar)
        registrar.addMethodCallDelegate(instance, channel: microServiceMethodChannel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try handleMethodCall(call, result)
        } catch {
            print(Thread.callStackSymbols)
            result(FlutterError(code: "exception", message: error.localizedDescription, details: SwiftLiquidcorePlugin.convertToDartObject(error)))
        }
    }
    
    private func normalizeUrl(_ uri: String) -> URL {
        if let urlComponents = URLComponents.init(string: uri), urlComponents.host != nil, urlComponents.url != nil {
            // This is a url path, keep it as is.
            return URL(string: uri)!
        }

        var filePath = uri
        if (uri.hasPrefix("@flutter_assets/")) {
            // Resolve a flutter resource.
            let asset = uri[(uri.index(uri.startIndex, offsetBy: 16))...]
            let key = registrar.lookupKey(forAsset: String(asset))
            filePath = Bundle.main.path(forResource: key, ofType: nil)!
        } else {
            // Return the raw resource path.
            filePath = Bundle.main.path(forResource: uri, ofType: nil)!
        }
        
        return URL(fileURLWithPath: filePath)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let args = call.arguments
        if ("devServer" == call.method) {
            var argsDict = args as! Dictionary<String, Any>
            let filename : String = argsDict["filename"] as! String
            let port : NSNumber = argsDict["port"] as! NSNumber
            result(LCMicroService.devServer(filename, port: port).absoluteString)
            return
        } else if ("uninstall" == call.method) {
            LCMicroService.uninstall(normalizeUrl(args as! String))
            result(nil)
            return
        }

        let argsDict:Dictionary<String, Any> = args as! Dictionary<String, Any>
        
        let serviceId : String = argsDict["serviceId"] as! String
        let uri : String = argsDict["uri"] as! String

        let wrappedMicroService : WrappedMicroService = getOrCreateService(serviceId, uri)

        let service : LCMicroService = wrappedMicroService.getMicroService()

        if ("start" == (call.method)) {
            let argv : [String]? = argsDict["argv"] as? [String]
            service.start(withArguments: argv)
            result(service.instanceId)
        } else if ("emit" == (call.method)) {
            let event : String = argsDict["event"] as! String
            let value : Any? = argsDict["value"]
            switch value {
            case is NSNull:
                service.emit(event)
            case is Bool:
                service.emitBoolean(event, boolean: value as! Bool)
            case is NSNumber:
                service.emitNumber(event, number: value as! NSNumber)
            case is String:
                service.emitString(event, string: value as! String)
            //case is Map:
            //case is Array:
            default:
                service.emitObject(event, object: value)
            }
            result(nil)
        } else if ("addEventListener" == (call.method)) {
            let event : String = argsDict["event"] as! String
            wrappedMicroService.addEventListener(event)
            result(nil)
        } else if ("removeEventListener" == (call.method)) {
            let event : String = argsDict["event"] as! String
            result(wrappedMicroService.removeEventListener(event))
        } else if ("getId" == (call.method)) {
            result(service.instanceId)
        } else if ("exitProcess" == (call.method)) {
            let exitCode = argsDict["exitCode"]
            let code : Int = exitCode == nil ? 0 : exitCode as! Int
            service.process?.exit(Int32(code))
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func getOrCreateService(_ serviceId : String, _ uri : String) -> WrappedMicroService {
        return microServicesMapLocker.sync {
            var service : WrappedMicroService
            if (!(microServices[serviceId] != nil)) {
                service = WrappedMicroService(normalizeUrl(uri), MicroServiceListener(serviceId, self))
                microServices[serviceId] = service
            } else {
                service = microServices[serviceId]!
            }
            
            return service
        }
    }

    private class func buildArguments(_ serviceId : String, _ value : Any?) -> Dictionary<String, Any> {
        var result : Dictionary<String, Any> = Dictionary()
        result["serviceId"] = serviceId
        result["value"] = value

        return result
    }
    
    func onExit(_ serviceId: String) {
        _ = microServicesMapLocker.sync {
            // Remove the service instance.
            microServices.removeValue(forKey: serviceId)
        }
    }

    private class MicroServiceListener : NSObject, IMicroServiceListener {
        private var serviceId : String
        private var handler: MicroServiceHandler

        init(_ serviceId : String, _ handler: MicroServiceHandler) {
            self.serviceId = serviceId
            self.handler = handler
        }

        public func onStart(_ service : LCMicroService) {
            microServiceMethodChannel?.invokeMethod("listener.onStart", arguments: buildArguments(serviceId, nil))
        }

        public func onError(service : LCMicroService, _ exception : NSException) {
            microServiceMethodChannel?.invokeMethod("listener.onError", arguments: buildArguments(serviceId, exception))
        }

        public func onExit(service : LCMicroService, _ exitCode : Int) {
            microServiceMethodChannel?.invokeMethod("listener.onExit", arguments: buildArguments(serviceId, exitCode))
            handler.onExit(serviceId)
        }
        
        func onEvent(_ service: LCMicroService, event: String, payload: Any?) {
            var map : Dictionary<String, Any> = Dictionary()
            map["event"] = event
            map["payload"] = SwiftLiquidcorePlugin.convertToDartObject(payload)
            microServiceMethodChannel?.invokeMethod("listener.onEvent", arguments: buildArguments(serviceId, map))
        }
    }
}
