# flutter_liquidcore
Node.js virtual machine for Android and iOS in Flutter.

A basic Flutter wrapper for the amazing https://github.com/LiquidPlayer/LiquidCore library.

You should check out the documentation on their [Wiki](https://github.com/LiquidPlayer/LiquidCore/wiki).

The iOS integration hasn't been implemented yet (PRs welcome!) as I don't have a Mac to develop on.

## Working
- `MicroService` integration on Android.
- Basic `JsContext` integration on Android.

    It's currently quite limited as it is, it allows you to evaluate scripts and read from them.
    Advanced manipulation of those objects in Dart isn't currently supported, so they'll need to be done in Javascript.
    I don't currently have any plans to provide low level object manipulation functionality.

## Todo
- Implement iOS integration of `MicroService`.
