import 'dart:async';
import 'dart:isolate';

import 'package:clipboard_sync_bluetooth/tray/trayManager.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';

import 'api/clibpardApi.dart';
import 'api/command.dart';

final ReceivePort receivePort = ReceivePort();
void main() async {
  initTrayManager();

  final sendPort = receivePort.sendPort;
  startCommandListener(sendPort);

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClipboardSyncScreen(),
    );
  }
}

class ClipboardSyncScreen extends StatefulWidget {
  @override
  _ClipboardSyncScreenState createState() => _ClipboardSyncScreenState();
}

String userId = "";
class _ClipboardSyncScreenState extends State<ClipboardSyncScreen> with ClipboardListener {
  final TextEditingController _outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ClipboardWatcher.instance.addListener(this);
    ClipboardWatcher.instance.start();
    initTrayManager();
    // setupSystemTray();

    receivePort.listen((message) {
      if (message == "sendClipboard") {
        Future.delayed(Duration(milliseconds: 100), () => sendClipboardToServer(userId));
      } else if (message == "fetchClipboard") {
        Future.delayed(Duration(milliseconds: 100), () => fetchClipboardData(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Clipboard Sync ")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _outputController,
              decoration: InputDecoration(labelText: "사용할 아이디를 입력하세요."),
            ),
            ElevatedButton(onPressed: () {
              userId = _outputController.text.trim();
              if (userId.isNotEmpty) {
                minimizeApp();
              } else {
                print("아이디 입력~~");
              }
            }, child: Text("시작하기"))
          ],
        ),
      ),
    );
  }
}
