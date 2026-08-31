import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Registered here, alongside the generated plugins, because this is the
    // only point where the engine exists and the scene lifecycle has not yet
    // built a window to hang a view controller from.
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TextRecognitionHandler"
    ) {
      TextRecognitionHandler.register(with: registrar)
    }
  }
}
