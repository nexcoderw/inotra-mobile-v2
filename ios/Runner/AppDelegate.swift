import UIKit
import Flutter
import GoogleMaps
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Firebase
    FirebaseApp.configure()

    // ✅ Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyBxDQkBVb0L9RtzxNoz-XqolzbE0C_xisA")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
