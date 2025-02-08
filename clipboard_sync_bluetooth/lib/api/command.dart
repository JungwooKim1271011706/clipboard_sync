import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:clipboard_sync_bluetooth/api/clibpardApi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

const MethodChannel _channel = MethodChannel("clipboard_chanel");
void startCommandListener(SendPort sendPort) {
  if (Platform.isWindows) {
    Isolate.spawn(registerGlobalHotKeys, sendPort);
  } else if (Platform.isIOS && int.parse(Platform.operatingSystemVersion.split(" ")[0]) >= 16) {
    _channel.invokeMethod("startClipboardWatcher");
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onClipboardChanged") {
       String clipboardData = call.arguments;
       print("클립보드 감지 :  $clipboardData");

       sendClipboardToServer(clipboardData);
      }
    });
  } else if (Platform.isAndroid) {
    _channel.invokeMethod("startForegroundService");
  }
}

const int MOD_ALT = 0x0001;
const int MOD_CONTROL = 0x0002;
const int MOD_SHIFT = 0x0004;
const int MOD_WIN = 0x0008;
const int VK_C = 0x43;
const int VK_V = 0x56;

bool simulateC() {
  final initClipboardSeq =  GetClipboardSequenceNumber();
  final Pointer<INPUT> inputCtrlDown = calloc<INPUT>();
  final Pointer<INPUT> inputCommand = calloc<INPUT>();
  final Pointer<INPUT> inputCtrlUp = calloc<INPUT>();
  bool clipboardUpdate = false;

  try {
    inputCtrlDown.ref.type = INPUT_KEYBOARD;
    inputCtrlDown.ref.ki.wVk = VK_CONTROL;
    inputCtrlDown.ref.ki.dwFlags = 0; // Key down

    inputCommand.ref.type = INPUT_KEYBOARD;
    inputCommand.ref.ki.wVk = VK_C;
    inputCommand.ref.ki.dwFlags = 0; // Key down

    inputCtrlUp.ref.type = INPUT_KEYBOARD;
    inputCtrlUp.ref.ki.wVk = VK_CONTROL;
    inputCtrlUp.ref.ki.dwFlags = KEYEVENTF_KEYUP; // Key up

    final inputList = calloc<INPUT>(3);
    inputList[0] = inputCtrlDown.ref;
    inputList[1] = inputCommand.ref;
    inputList[2] = inputCtrlUp.ref;

    final sent = SendInput(3, inputList, sizeOf<INPUT>());
    if (sent == 0) {
      print("❌ Windows 기본 복사 기능 실행 실패");
    } else {
      print("✅ Windows 기본 복사 기능 실행 성공");
      for (int i = 0; i < 10; i++) {
        if (GetClipboardSequenceNumber() != initClipboardSeq) {
          clipboardUpdate = true;
          break;
        }
        Sleep(100);
      }
    }
  } catch (e) {
    print(">>>> $e");
  } finally {
    calloc.free(inputCtrlDown);
    calloc.free(inputCommand);
    calloc.free(inputCtrlUp);
    return clipboardUpdate;
  }
}

bool simulateV() {
  final Pointer<INPUT> inputCtrlDown = calloc<INPUT>();
  final Pointer<INPUT> inputCommand = calloc<INPUT>();
  final Pointer<INPUT> inputCtrlUp = calloc<INPUT>();
  bool clipboardUpdate = false;

  try {
    inputCtrlDown.ref.type = INPUT_KEYBOARD;
    inputCtrlDown.ref.ki.wVk = VK_CONTROL;
    inputCtrlDown.ref.ki.dwFlags = 0; // Key down

    inputCommand.ref.type = INPUT_KEYBOARD;
    inputCommand.ref.ki.wVk = VK_V;
    inputCommand.ref.ki.dwFlags = 0; // Key down

    inputCtrlUp.ref.type = INPUT_KEYBOARD;
    inputCtrlUp.ref.ki.wVk = VK_CONTROL;
    inputCtrlUp.ref.ki.dwFlags = KEYEVENTF_KEYUP; // Key up

    final inputList = calloc<INPUT>(3);
    inputList[0] = inputCtrlDown.ref;
    inputList[1] = inputCommand.ref;
    inputList[2] = inputCtrlUp.ref;

    final sent = SendInput(3, inputList, sizeOf<INPUT>());
    if (sent == 0) {
      print("❌ Windows 기본 복사 기능 실행 실패");
    } else {
      print("✅ Windows 기본 복사 기능 실행 성공");
    }
  } catch (e) {
    print("$e");
  } finally {
    calloc.free(inputCtrlDown);
    calloc.free(inputCommand);
    calloc.free(inputCtrlUp);
    return clipboardUpdate;
  }
}

DateTime lastHotkeyTime = DateTime.now().subtract(Duration(seconds: 1));
Future<void> registerGlobalHotKeys(SendPort sendPort) async {
  final hWnd = FindWindow(TEXT("FLUTTER_RUNNER_WIN32_WINDOW"), nullptr);
  if (hWnd == 0) {
    print("창 핸들을 찾을 수 없음.");
    return;
  }

  final int ctrlC = RegisterHotKey(nullptr.address, 1, MOD_CONTROL | MOD_SHIFT, VK_C);
  final int ctrlV = RegisterHotKey(nullptr.address, 2, MOD_CONTROL | MOD_SHIFT, VK_V);
  if (ctrlC == 0 || ctrlV == 0) {
    print("글로벌 핫키 등록 실패 : ${GetLastError()}") ;
    return;
  }

  print("글로벌 핫키 등록 완료(Ctrl + C, V)");

  final msg = calloc<MSG>();
  try {
    while (GetMessage(msg, nullptr.address, 0, 0) != 0) {
      TranslateMessage(msg);
      DispatchMessage(msg);

      if (msg.ref.message == WM_HOTKEY) {
        final hotkeyId = msg.ref.wParam;
        final DateTime now = DateTime.now();

        if (now.difference(lastHotkeyTime) > Duration(milliseconds: 500)) {
          switch (hotkeyId) {
            case 1:
              lastHotkeyTime = now;
              print("감지됨. 서버로 클립보드 데이터 전송");
              if (simulateC()) {
                sendPort.send("sendClipboard");
              }
              break;
            case 2:
              print("감지됨. 서버에서 클립보드 데이터 추출");
              sendPort.send("fetchClipboard");
              break;
          }
        }
      }
    }
  } catch (e) {
    print("❌ : $e");
  }
  calloc.free(msg);
}

