public class WrappedJSContext {
    private var jsContext : JSContext

    public init() {
        jsContext = JSContext()
        setGlobalProperties()
    }
    
    private func setGlobalProperties() {
        let liquidcoreReadOnlyProperties: [String : Bool] = [
            JSPropertyDescriptorWritableKey: false,
        ]
        jsContext.evaluateScript("function __liquidcore_is_error__(obj) { return obj instanceof Error; }");
        jsContext.globalObject.defineProperty("__liquidcore_is_error__", descriptor: liquidcoreReadOnlyProperties)
        
        jsContext.evaluateScript("function __liquidcore_typeof__(obj){ return typeof obj }")
        jsContext.globalObject.defineProperty("__liquidcore_typeof__", descriptor: liquidcoreReadOnlyProperties)
        
        let safeStringify = "function __liquidcore_safe_stringify__(obj, replacer, spaces, cycleReplacer) {\n" +
            "    function serializer(replacer, cycleReplacer) {\n" +
            "       var stack = [], keys = []\n" +
            "       if (cycleReplacer == null) cycleReplacer = function(key, value) {\n" +
            "           if (stack[0] === value) return '[Circular ~]'\n" +
            "           return'[Circular ~.' + keys.slice(0, stack.indexOf(value)).join('.')+']'\n" +
            "       }\n" +
            "       return function(key, value) {\n" +
            "           if (stack.length > 0) {\n" +
            "               var thisPos = stack.indexOf(this)\n" +
            "               ~thisPos ? stack.splice(thisPos + 1) : stack.push(this)\n" +
            "               ~thisPos ? keys.splice(thisPos, Infinity, key) : keys.push(key)\n" +
            "               if (~stack.indexOf(value))value=cycleReplacer.call(this, key, value)\n" +
            "           }\n" +
            "           else stack.push(value)\n" +
            "           if (typeof value === 'function') {\n" +
            "               value = {\n" +
            "                   __liquidcore_type__: 'function',\n" +
            "                   __liquidcore_value__: value.toString()\n" +
            "               };\n" +
            "           }\n" +
            "\n" +
            "           return replacer == null ? value : replacer.call(this, key, value)\n" +
            "       }\n" +
            "   }\n" +
            "   return JSON.stringify(obj, serializer(replacer, cycleReplacer), spaces)\n" +
            "}"
        jsContext.evaluateScript(safeStringify)
        jsContext.globalObject.defineProperty("__liquidcore_safe_stringify__", descriptor: liquidcoreReadOnlyProperties)
        
        jsContext.evaluateScript("function __liquidcore_safe_object__(obj){ return JSON.parse(__liquidcore_safe_stringify__(obj)); }")
        jsContext.globalObject.defineProperty("__liquidcore_safe_object__", descriptor: liquidcoreReadOnlyProperties)
        
    }

    public func getJSContext() -> JSContext {
        return jsContext;
    }

    public func freeUp() {
        // noop, handled by Swift.
    }
}
