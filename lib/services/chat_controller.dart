import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChatController extends ChangeNotifier {
  InAppWebViewController? webViewController;

  bool showInput = true;
  bool isLoading = false;
  bool isWebReady = false;
  String? currentResponseText;

  String? errorText;

  void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  void resetInput() {
    showInput = true;
    currentResponseText = null;
    errorText = null;
    isLoading = false;
    notifyListeners();
  }

  void handleWebMessage(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      final status = data['status'];

      if (status == 'ready') {
        isWebReady = true;
        notifyListeners();
      } else if (status == 'loading') {
        showInput = false;
        isLoading = true;
        currentResponseText = null;
        errorText = null;
        notifyListeners();
      } else if (status == 'response') {
        showInput = false;
        isLoading = false;
        currentResponseText = data['text'];
        notifyListeners();
      } else if (status == 'error') {
        showInput = false;
        isLoading = false;
        errorText = data['text'] ?? 'Terjadi kesalahan.';
        notifyListeners();
      }
    } catch (e) {
      print('Error parsing JS Channel message: $e');
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    if (webViewController != null) {
      // Set to loading manually initially, or wait for Web to send 'loading'
      // We will let Web send 'loading' so Flutter waits for Web.
      
      final escapedText = text
          .replaceAll("'", "\\'")
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n');
          
      webViewController!.evaluateJavascript(source: '''
        try {
          var inputField = document.getElementById('chat-input');
          var sendBtn = document.getElementById('send-btn');
          
          if(inputField) {
            inputField.value = '$escapedText';
            inputField.dispatchEvent(new Event('input', { bubbles: true }));
          }
          
          if(sendBtn) {
            sendBtn.click();
          }
        } catch(e) { 
          console.error("Error mengirim pesan ke WebView", e); 
        }
      ''');
    }
  }
}
