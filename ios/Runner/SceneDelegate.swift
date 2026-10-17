import Flutter
import UIKit
import app_links

class SceneDelegate: FlutterSceneDelegate {
  /// Widget deep links only — sign-in uses native Google/Apple sheets, not URL callbacks.
  private func handleWidgetDeepLinkIfNeeded(_ url: URL) {
    guard url.scheme?.lowercased() == "jebbo" else { return }
    AppLinks.shared.handleLink(url: url)
  }

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for context in connectionOptions.urlContexts {
      handleWidgetDeepLinkIfNeeded(context.url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      handleWidgetDeepLinkIfNeeded(context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
