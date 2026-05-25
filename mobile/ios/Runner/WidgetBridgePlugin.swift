import Flutter
import UIKit

public class WidgetBridgePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.dailyticker/widget_bridge",
            binaryMessenger: registrar.messenger()
        )
        let instance = WidgetBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "writeSnapshot":
            guard let json = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
                return
            }
            do {
                try WidgetDataStore.writeRaw(json)
                WidgetDataStore.reloadTimelines()
                result(nil)
            } catch {
                result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
            }
        case "readSnapshot":
            result(WidgetDataStore.readRaw())
        case "consumeDeepLink":
            result(WidgetDeepLinkStore.consume())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
