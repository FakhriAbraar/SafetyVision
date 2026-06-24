import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/chat_controller.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: const _ChatScreenContent(),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  const _ChatScreenContent();

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final TextEditingController _textController = TextEditingController();
  InAppWebViewController? _webViewController;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      context.read<ChatController>().sendMessage(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final webViewUrl = dotenv.env['CLOUDFLARE_WEBVIEW_URL'] ?? 'https://questions-rocky-latinas-marcus.trycloudflare.com/web/';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Companion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Test Audio WebView',
            onPressed: () {
              _webViewController?.evaluateJavascript(source: '''
                try {
                  var testAudio = new Audio('https://www.soundjay.com/buttons/sounds/button-3.mp3');
                  testAudio.play().then(() => {
                    if(window.FlutterErrorChannel) window.FlutterErrorChannel.postMessage("Test Audio BERHASIL dimainkan WebView!");
                  }).catch(e => {
                    if(window.FlutterErrorChannel) window.FlutterErrorChannel.postMessage("Test Audio GAGAL: " + e.message);
                  });
                } catch(err) {
                  if(window.FlutterErrorChannel) window.FlutterErrorChannel.postMessage("JS Catch: " + err.message);
                }
              ''');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Visual Area (3D Vroid WebView)
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(webViewUrl)),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  transparentBackground: true,
                  javaScriptEnabled: true,
                  allowsInlineMediaPlayback: true,
                ),
                // Injected BEFORE any page scripts run — solves race condition
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source: '''
                      // Bridge: map window.FlutterChannel.postMessage → flutter_inappwebview handler
                      window.FlutterChannel = {
                        postMessage: function(message) {
                          if(window.flutter_inappwebview) {
                            window.flutter_inappwebview.callHandler('FlutterChannel', message);
                          }
                        }
                      };
                      
                      window.FlutterErrorChannel = {
                        postMessage: function(message) {
                          if(window.flutter_inappwebview) {
                            window.flutter_inappwebview.callHandler('FlutterErrorChannel', message);
                          }
                        }
                      };

                      window.onerror = function(message, source, lineno, colno, error) {
                        if(window.FlutterErrorChannel) {
                          window.FlutterErrorChannel.postMessage(message);
                        }
                      };
                      var originalError = console.error;
                      console.error = function() {
                        originalError.apply(console, arguments);
                        if(window.FlutterErrorChannel) {
                          window.FlutterErrorChannel.postMessage("Console Error: " + Array.from(arguments).join(" "));
                        }
                      };
                    ''',
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  ),
                  UserScript(
                    source: '''
                      var style = document.createElement('style');
                      style.innerHTML = `
                        body, html {
                          background-color: transparent !important;
                        }
                        #chat-input, #send-btn, .chat-ui, .controls { 
                          opacity: 0 !important; 
                          pointer-events: none !important; 
                          position: absolute !important; 
                          z-index: -9999 !important;
                        }
                      `;
                      document.head.appendChild(style);
                    ''',
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                  ),
                ]),
                onWebViewCreated: (webController) {
                  _webViewController = webController;
                  
                  webController.addJavaScriptHandler(handlerName: 'FlutterChannel', callback: (args) {
                    if (mounted && args.isNotEmpty) {
                      context.read<ChatController>().handleWebMessage(args[0].toString());
                    }
                  });
                  
                  webController.addJavaScriptHandler(handlerName: 'FlutterErrorChannel', callback: (args) {
                    if (mounted && args.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Web Error: ${args[0]}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  });
                  
                  if (mounted) {
                    context.read<ChatController>().setWebViewController(webController);
                  }
                },
                onConsoleMessage: (webController, consoleMessage) {
                  print('WebView Console: ${consoleMessage.message}');
                },
              ),
            ),
          ),
          
          // Dynamic Bottom Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildBottomPanel(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ChatController controller) {
    if (!controller.isWebReady) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat Model 3D AI...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    } else if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (controller.errorText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => controller.resetInput(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Coba Lagi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (controller.currentResponseText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 70),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    controller.currentResponseText!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              controller.resetInput();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Lanjutkan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      );
    }
  }
}
