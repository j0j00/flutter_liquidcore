public class WrappedMicroService : NSObject, LCMicroServiceEventListener, LCMicroServiceDelegate {
    private var microService : LCMicroService!;
    private final var serviceStartListener : IMicroServiceListener;
    private var listenerCount : Dictionary<String, Int> = Dictionary();

    // List of events to add immediately before the service is executed.
    private var events : [String] = [];
    private var started : Bool = false;

    public init(_ url : URL, _ _serviceStartListener : IMicroServiceListener) {
        serviceStartListener = _serviceStartListener;
        super.init();
        microService = LCMicroService(url: url, delegate: self);
    }

    public func onStart(_ service: LCMicroService) {
        // .. The environment is live, but the startup JS code (from the URI)
        // has not been executed yet.
        started = true;
        
        // Add the event listeners synchronously, so there's no race conditions.
        for event : String in events {
            microService.addEventListener(event, listener: self);
        }
        
        serviceStartListener.onStart!(service);
    }

    public func getMicroService() -> LCMicroService {
        return microService;
    }

    public func addEventListener(_ event : String) {
        if (!(listenerCount[event] != nil)) {
            listenerCount[event] = 1;
            if (started) {
                // Add the listener asynchronously.
                microService.addEventListener(event, listener: self);
            } else {
                // Bubble the events until the service has been started.
                events.append(event);
            }
        } else {
            listenerCount[event] = (listenerCount[event] ?? 0) + 1;
        }
    }

    public func removeEventListener(_ event : String) -> Bool {
        let count : Int = listenerCount[event] ?? 0;
        if (count <= 0) {
            return false;
        }
        listenerCount[event] = count - 1;
        if (count == 1) {
            microService.removeEventListener(event, listener: self);
        }
        if let index = events.index(of: event) {
            events.remove(at: index)
        }
        return true;
    }

    public func onEvent(_ service: LCMicroService, event: String, payload: Any?) {
        serviceStartListener.onEvent(service, event: event, payload: payload);
    }
}
