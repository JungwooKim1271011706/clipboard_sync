import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var clipboardObserver: NSObjectProtocol?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let clipboardChannel = FlutterMethodChannel(name: "clipboard_channel", binaryMessenger: controller.binaryMessenger)

        clipboardChannel.setMethodCallHandler { (call, result) in
            if call.method == "startClipboardWatcher" {
                self.startClipboardWatcher()
                result("Clipboard watching started")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func startClipboardWatcher() {
        let pasteboard = UIPasteboard.general

        if #available(iOS 16.0, *) {
            pasteboard.detectPatterns(for: [.all]) { (detected, error) in
                if detected {
                    //print("📋 클립보드 변경 감지됨: \(pasteboard.string ?? "No Text")")

                    // ✅ 클립보드 변경 감지 시, Flutter로 데이터 전송
                    DispatchQueue.main.async {
                        let clipboardChannel = FlutterMethodChannel(name: "clipboard_channel", binaryMessenger: (self.window?.rootViewController as! FlutterViewController).binaryMessenger)
                        clipboardChannel.invokeMethod("onClipboardChanged", arguments: pasteboard.string ?? "")
                    }
                }
            }
        } else {
            print("❌ iOS 16 이상에서만 UIPasteboard 변경 감지 기능을 사용할 수 있습니다.")
        }
    }
}
