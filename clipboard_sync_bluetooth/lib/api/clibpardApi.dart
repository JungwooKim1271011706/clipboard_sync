import 'dart:convert';
import 'dart:io';

import 'package:clipboard_sync_bluetooth/api/command.dart';
import 'package:flutter/services.dart';

import '../main.dart';

// 클립보드 데이터를 서버로 업로드
String clipboardServerUrl = "https://192.168.219.107/clipboard";

Future<void> sendClipboardToServer([String? clipboardIosData]) async {
  try {
    if (clipboardIosData != null && clipboardIosData.isNotEmpty){
      userId = clipboardIosData;
    }
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    String? clipboardDataText = clipboardData?.text;

    final uploadUrl = Uri.parse("$clipboardServerUrl/clipboard/upload");
    HttpClient httpClient = HttpClient();
    httpClient.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;

    try {
      HttpClientRequest request = await httpClient.postUrl(uploadUrl);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode({
      "userId": userId,
      "data": clipboardDataText,
      })));

      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        print("📤 클립보드 데이터 전송 성공: $clipboardDataText ");
      } else {
        print("❌ 클립보드 전송 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 네트워크 오류 발생: $e");
    }
  } catch(e) {
    print("❌ 클립보드 접근 오류 발생...: $e");
  }
}

Future<void> fetchClipboardData(String userId) async {
  final fetchUrl = Uri.parse("$clipboardServerUrl/clipboard/get/$userId");

  HttpClient httpClient = HttpClient();
  httpClient.badCertificateCallback =
  (X509Certificate cert, String host, int port) => true;

  HttpClientRequest request = await httpClient.getUrl(fetchUrl).timeout(const Duration(seconds: 5));
  request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
  try {
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      String resultJson = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(resultJson);
      String clipboardData = data['data'];
      await Clipboard.setData(ClipboardData(text: clipboardData));
      if (simulateV()) {
        print("클립보드 데이터 추출($userId) : $clipboardData");
      }
    } else {
      print("서버 코드가 200이 아님...");
    }
  } catch (e) {
    print("$e");
  }
}

