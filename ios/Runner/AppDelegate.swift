import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API 키: ios/Flutter/Secrets.xcconfig(gitignore 대상)의 MAPS_API_KEY가
    // Info.plist의 $(MAPS_API_KEY)로 빌드 시 치환되어 여기로 들어온다.
    // 로컬 세팅: ios/Flutter/Secrets.xcconfig.example 참고.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
      !apiKey.isEmpty
    {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
