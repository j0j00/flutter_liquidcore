## 1.1.1

- Android: Implement `onError` and `onExit` Microservice handler - [#12](https://github.com/j0j00/flutter_liquidcore/pull/12) (thanks [@itome](https://github.com/itome)!)

## 1.1.0

- Don't allow implicit casts - [#6](https://github.com/j0j00/flutter_liquidcore/pull/6) (thanks [@tvh](https://github.com/tvh)!)
- Android: Add Flutter 1.7+ support, by making all plugin invocations occur on the main thread - [#7](https://github.com/j0j00/flutter_liquidcore/pull/7) (thanks [@krista-koivisto](https://github.com/krista-koivisto)!) 

## 1.0.0

- Update the `uuid` dependency from `^1.0.0` to `^2.0.2`.
- Android: Migrate to AndroidX.
- Android: Bump LiquidCore dependency from `0.6.0` to `0.6.2`.

    Notable compatibility change: Removed the default `android.permission.WRITE_EXTERNAL_STORAGE` permission.

## 0.6.0

- iOS support and bugfixes.
- Provides full iOS support.
- Add `@flutter_assets/` uri support for the MicroService.
- LiquidCore bugfixes and improvement.

## 0.0.1

- Initial release!
- Provides basic MicroService Android integration
- Partial JsContext integration, simple evaluations can be executed.
