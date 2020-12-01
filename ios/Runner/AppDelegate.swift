import UIKit
import Flutter
import GoogleMaps
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GMSServices.provideAPIKey("AIzaSyD72_WqxqD9vrCSbfZM42l1ATfNa6TqGLc")
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
//    if #available(iOS 10.0, *) {
//      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
//    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
