
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';


void initTrayManager() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    final systemTray = SystemTray();

    await systemTray.initSystemTray(
      iconPath: "assets/app_icon.ico",
      title: "Clipboard sync",
      toolTip: "Clipboard sync",
    );

    systemTray.registerSystemTrayEventHandler((eventName) {
      switch (eventName) {
        case kSystemTrayEventRightClick:
          systemTray.popUpContextMenu();
          break;
        case kSystemTrayEventDoubleClick:
          print("시스템 트레이 클릭됨! 앱을 다시 활성화");
          windowManager.show();
          break;
      }
    });

    void _closeApp() {
      systemTray.destroy();
      exit(0);
    }

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: '닫기', onClicked: (_) => _closeApp()),
    ]);
    await systemTray.setContextMenu(menu);
  } else if (Platform.isIOS) {
    final service = FlutterBackgroundService();

    await service.configure(iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      onForeground: onStart,
    ), androidConfiguration:
        AndroidConfiguration(onStart: onStart,
        autoStart: false,
        isForegroundMode: false)
    );
    service.startService();
  } else if (Platform.isAndroid) {
    final service = FlutterBackgroundService();

    await service.configure(iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      autoStart: false,
      onForeground: onStart,
    ), androidConfiguration:
    AndroidConfiguration(onStart: onStart,
        autoStart: true,
        isForegroundMode: false)
    );
    service.startService();
  }
  print("시스템 트레이 초기화 완료");
}
@pragma('vm::entry-point')
bool onIosBackground(ServiceInstance service) {
  return Platform.isIOS;
}

onStart(ServiceInstance service) {
  service.on("stopService").listen((event) {
    service.stopSelf();
  });

  service.on("ping").listen((event) {
    print("백그라운드 서비스 핑");
  });
}

void minimizeApp () async {
  if (Platform.isWindows) {
    await windowManager.hide();
  } else if (Platform.isIOS) {

  } else if (Platform.isAndroid) {
    MethodChannel _channel = MethodChannel("clipboard_channel");
    _channel.invokeMethod("moveToBackground");
  }
}



