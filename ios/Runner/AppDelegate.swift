import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("WalletKeeper iOS: AppDelegate didFinishLaunching started")
    GeneratedPluginRegistrant.register(with: self)
    NSLog("WalletKeeper iOS: GeneratedPluginRegistrant finished")
    application.applicationIconBadgeNumber = 0
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("WalletKeeper iOS: super.application finished = \(result)")
    return result
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    application.applicationIconBadgeNumber = 0
  }
}
