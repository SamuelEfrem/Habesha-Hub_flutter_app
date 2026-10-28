import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import 'purchase_service.dart';
import 'unlock_service.dart';

/// Opens a web game or tool (hosted on Firebase Hosting) full screen inside the app.
/// The page can ask for a purchase with:  HabeshaApp.postMessage('{"type":"buy","product":"theory_pro"}')
/// After a successful purchase the app calls window.habeshaUnlock('<product>') in the page.
class GameWebViewScreen extends StatefulWidget {
  final String title;
  final Uri url;
  const GameWebViewScreen({super.key, required this.title, required this.url});

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  final _purchases = PurchaseService.instance;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
              )
            : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1118))
      ..addJavaScriptChannel('HabeshaApp', onMessageReceived: _onPageMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (_) => _sendUnlocked(),
      ))
      ..loadRequest(widget.url);

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    // After a confirmed purchase: send the paid questions + unlock to the page
    _purchases.onUnlocked = (id) => _sendUnlocked();
    _purchases.onError = (msg) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    };
  }

  void _onPageMessage(JavaScriptMessage m) {
    try {
      final data = jsonDecode(m.message) as Map<String, dynamic>;
      final product = data['product'];
      final type = data['type'];
      if (type == 'buy' && product is String && PurchaseService.productIds.contains(product)) {
        _buy(product);
      } else if (type == 'open' && data['url'] is String) {
        _openExternal(data['url'] as String);
      } else if (type == 'redeem' && data['code'] is String) {
        _redeem(data['code'] as String);
      }
    } catch (_) {
      // ignore messages we don't understand
    }
  }

  // A purchase is tied to an account, so log in first
  Future<void> _buy(String product) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return;
    }
    await _purchases.buy(product);
  }

  // Only WhatsApp links leave the app (the page asks to contact the admin)
  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.host == 'wa.me' || uri.host == 'api.whatsapp.com')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _redeem(String code) async {
    final error = await UnlockService.instance.redeem(context, code);
    final msg = error ?? '✓';
    await _controller.runJavaScript(
        'window.habeshaRedeemResult && window.habeshaRedeemResult(${jsonEncode({'ok': error == null, 'message': msg})})');
    if (error == null) await _sendUnlocked();
  }

  // Give the page everything this user has unlocked (paid questions come from Firestore)
  Future<void> _sendUnlocked() async {
    try {
      final owned = await UnlockService.instance.unlocked();
      for (final p in owned) {
        if (p == 'theory_pro') {
          final qs = await UnlockService.instance.theoryQuestions();
          await _controller.runJavaScript(
              'window.habeshaAddQuestions && window.habeshaAddQuestions(${jsonEncode(qs)})');
        }
        await _controller.runJavaScript(
            "window.habeshaUnlock && window.habeshaUnlock(${jsonEncode(p)})");
      }
    } catch (_) {
      // offline or not logged in: free content still works
    }
  }

  @override
  void dispose() {
    _purchases.onUnlocked = null;
    _purchases.onError = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1118),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
