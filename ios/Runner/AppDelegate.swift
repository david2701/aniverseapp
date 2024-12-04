import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

     if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  // Añadir este método para manejar notificaciones en primer plano
      @available(iOS 10.0, *)
      override func userNotificationCenter(
          _ center: UNUserNotificationCenter,
          willPresent notification: UNNotification,
          withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
      ) {
          completionHandler([[.alert, .sound, .badge]])
      }
}
