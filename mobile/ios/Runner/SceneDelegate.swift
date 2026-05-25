import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    if let url = URLContexts.first?.url, url.scheme == "dailyticker" {
      WidgetDeepLinkStore.enqueue(host: url.host)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
