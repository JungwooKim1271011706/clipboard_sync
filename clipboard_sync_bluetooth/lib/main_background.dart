// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   initializeService();
//   runApp(MyApp());
// }
//
// void initializeService() {
//   FlutterBackgroundService.initialize(onStart);
// }
//
// void onStart(ServiceInstance service) {
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//
//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: "Flutter Background Service",
//       content: "Background Service is running",
//     );
//   }
//
//   service.on('setAsForeground').listen((event) {
//     service.setAsForegroundService();
//   });
//
//   service.on('setAsBackground').listen((event) {
//     service.setAsBackgroundService();
//   });
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//
//   // 백그라운드 작업을 주기적으로 실행
//   Timer.periodic(Duration(seconds: 5), (timer) async {
//     // 여기에 블루투스 스캔 작업을 추가할 수 있습니다.
//     print("Background service is running");
//   });
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Background Service Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Flutter Background Service Demo'),
//         ),
//         body: Center(
//           child: ElevatedButton(
//             onPressed: () {
//               FlutterBackgroundService().invoke('stopService');
//             },
//             child: Text('Stop Background Service'),
//           ),
//         ),
//       ),
//     );
//   }
// }
