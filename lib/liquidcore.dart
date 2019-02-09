export 'src/microservice.dart';
export 'src/jscontext.dart';

const NAMESPACE = "io.jojodev.flutter.liquidcore";

/// This enables more verbose logging, if desired.
bool enableLiquidCoreLogging = false;

void liquidcoreLog(String message) {
  if (enableLiquidCoreLogging) {
    print(message);
  }
}
