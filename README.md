# flutter_liquidcore
Node.js/Javascript virtual machine for Android and iOS in Flutter.

A basic Flutter wrapper for the amazing https://github.com/LiquidPlayer/LiquidCore library.

You should check out the documentation on their [Wiki](https://github.com/LiquidPlayer/LiquidCore/wiki) for more information as to how it works.

## Features
- `MicroService` integration - A way to communicate with your script/service using an `EventEmitter`.
- `JsContext` integration - A way to execute arbitrary scripts in a self-contained vm.

    It's currently quite limited as it is, it allows you to evaluate scripts and read from them.
    
    Advanced manipulation of those `JsContext` objects in Dart isn't currently supported, so they'll need to be done in Javascript.
    
    There's currently no plans to provide low level object manipulation functionality.