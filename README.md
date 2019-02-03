# flutter_liquidcore
Node.js/Javascript virtual machine for Android and iOS in Flutter.

A basic Flutter wrapper for the amazing https://github.com/LiquidPlayer/LiquidCore library.

You should check out the documentation on their [Wiki](https://github.com/LiquidPlayer/LiquidCore/wiki).

## Features
- `MicroService` integration.
- Basic `JsContext` integration.

    It's currently quite limited as it is, it allows you to evaluate scripts and read from them.
    Advanced manipulation of those objects in Dart isn't currently supported, so they'll need to be done in Javascript.
    There's currently no plans to provide low level object manipulation functionality.

## iOS integration.
Until the LiquidCore library has been published as a CocoaPod, you'll have to specify the LiquidCore source in your applications `Podfile` like this:

```ruby
pod 'LiquidCore', :git => 'https://github.com/LiquidPlayer/LiquidCore.git', :tag => '0.6.0-pre1'
```
