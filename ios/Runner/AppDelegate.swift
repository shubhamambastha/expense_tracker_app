import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private func handleWidgetDeepLinkIfNeeded(_ url: URL) {
    guard url.scheme?.lowercased() == "expensetracker" else { return }
    AppLinks.shared.handleLink(url: url)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      handleWidgetDeepLinkIfNeeded(url)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleWidgetDeepLinkIfNeeded(url)
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
