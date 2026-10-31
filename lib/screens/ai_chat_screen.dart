import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import 'auth_screen.dart';
import 'marketplace_screen.dart';

/// Habesha AI: text, voice (recorded and understood by Gemini, also Tigrinya),
/// photos, and it can post a Market listing for the user.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final _rec = AudioRecorder();
  final List<_ChatMessage> _messages = [];
  /// Photos attached in this chat (JPEG). They go with every question so the
  /// assistant can still use them when it posts a listing.
  final List<Uint8List> _photos = [];
  bool _loading = false;
  bool _recording = false;
  int _recSeconds = 0;
  Timer? _recTimer;

  static const _maxPhotos = 4;
  static const _maxRecord = 30; // seconds

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _addWelcomeMessage();
  }

  String _l(String en, String ti, String am) {
    final l = languageNotifier.language;
    return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
  }

  /// Phones have no good Tigrinya / Amharic voice — the English voice reads
  /// Ge'ez script wrongly. So the assistant only speaks English answers.
  static final _geez = RegExp('[ሀ-᎟ⶀ-⷟꬀-꬯]');
  bool _canSpeak(String text) => languageNotifier.language == 'English' && !_geez.hasMatch(text);

  Future<void> _speak(String text) async {
    await _tts.stop();
    if (!_canSpeak(text)) return;
    await _tts.speak(text);
  }

  void _addWelcomeMessage() {
    _messages.add(_ChatMessage(
      isUser: false,
      text: _l(
        "Hello! I'm Habesha AI. Ask me anything about Habesha Hub, write or press 🎤 to speak. "
            "You can also send a photo 📷 — for example of a zuria you want to sell, and I'll post it in the Market for you.",
        'ሰላም! ኣነ ሓበሻ AI እየ። ብዛዕባ ሓበሻ ሃብ ዝኾነ ሕቶ ሕተተኒ፡ ጽሓፍ ወይ 🎤 ጠዊቕካ ተዛረብ። '
            'ስእሊ 📷 እውን ክትሰድድ ትኽእል — ንኣብነት ክትሸጣ እትደሊ ዙርያ፡ ኣነ ድማ ኣብ ዕዳጋ ክዝርግሓልካ እየ።',
        'ሰላም! እኔ ሐበሻ AI ነኝ። ስለ ሐበሻ ሀብ ማንኛውንም ይጠይቁኝ፣ ይጻፉ ወይም 🎤 ተጭነው ይናገሩ። '
            'ፎቶ 📷 መላክም ይችላሉ — ለምሳሌ ሊሸጡት የሚፈልጉትን ዙሪያ፣ እኔም በገበያው ላይ እለጥፍልዎታለሁ።',
      ),
    ));
  }

  static const _aiEndpoint = 'https://europe-west1-habesha-hub-7bd1d.cloudfunctions.net/aiChat';

  // ── voice: record, then Gemini understands it (works for Tigrinya too) ──
  Future<void> _toggleRecord() async {
    if (_loading) return;
    if (_recording) return _stopAndSend();
    await _tts.stop();
    if (!await _rec.hasPermission()) {
      _addError(_l('Please allow the microphone for Habesha Hub in the phone settings.',
          'በጃኻ ኣብ ቅጥዕታት ተሌፎን ንሓበሻ ሃብ ማይክሮፎን ፍቐደሉ።', 'እባክዎ በስልክ ቅንብሮች ለሐበሻ ሀብ ማይክሮፎን ይፍቀዱ።'));
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/habesha_ai_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
    setState(() { _recording = true; _recSeconds = 0; });
    _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recSeconds++);
      if (_recSeconds >= _maxRecord) _stopAndSend();
    });
  }

  Future<void> _stopAndSend() async {
    _recTimer?.cancel();
    if (!_recording) return;
    final path = await _rec.stop();
    setState(() => _recording = false);
    if (path == null) return;
    final file = File(path);
    final bytes = await file.readAsBytes();
    file.delete().catchError((_) => file);
    if (bytes.length < 16000) return; // under half a second: nothing said
    await _send(audio: bytes, label: '🎤 ${_l('Voice message', 'ድምጺ መልእኽቲ', 'የድምፅ መልእክት')} (${_recSeconds}s)');
  }

  Future<void> _cancelRecord() async {
    _recTimer?.cancel();
    await _rec.cancel();
    setState(() => _recording = false);
  }

  // ── photos: camera or gallery ──
  Future<void> _addPhoto() async {
    if (_loading || _recording) return;
    if (_photos.length >= _maxPhotos) {
      _addError(_l('You can attach up to $_maxPhotos photos in one chat. Press ↻ for a new chat.',
          'ኣብ ሓደ ዕላል ክሳብ $_maxPhotos ስእልታት ጥራይ። ንሓድሽ ዕላል ↻ ጠውቕ።',
          'በአንድ ውይይት እስከ $_maxPhotos ፎቶዎች ብቻ። ለአዲስ ውይይት ↻ ይንኩ።'));
      return;
    }
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: kText),
            title: Text(_l('Take a photo', 'ስእሊ ኣልዕል', 'ፎቶ አንሳ'), style: tsTitleMd()),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: kText),
            title: Text(_l('Choose from gallery', 'ካብ ጋለሪ ምረጽ', 'ከጋለሪ ምረጥ'), style: tsTitleMd()),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 70);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    // the photo goes with the text that is already written (if any)
    final typed = _msgCtrl.text.trim();
    await _send(text: typed.isEmpty ? null : typed, photo: bytes);
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    await _send(text: text);
  }

  Future<void> _send({String? text, Uint8List? audio, Uint8List? photo, String? label}) async {
    if (_loading) return;
    _msgCtrl.clear();
    if (photo != null) _photos.add(photo);
    final userMsg = _ChatMessage(isUser: true, text: label ?? text ?? '', photo: photo);
    setState(() { _messages.add(userMsg); _loading = true; });
    _scrollToBottom();

    try {
      final history = _messages
          .skip(1)
          .where((m) => !m.isError && m != userMsg && m.text.isNotEmpty)
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList();
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http
          .post(
            Uri.parse(_aiEndpoint),
            headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'lang': languageNotifier.language,
              'history': history,
              'text': text ?? '',
              if (audio != null) 'audio': base64Encode(audio),
              if (audio != null) 'audioMime': 'audio/wav',
              'photos': _photos.map(base64Encode).toList(),
              'newPhotos': photo != null ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 75));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || data['limited'] == true) {
        var reply = (data['reply'] ?? '').toString().trim();
        // voice: the first line is what the user said → show it in their bubble
        if (audio != null && reply.startsWith('🎤')) {
          final nl = reply.indexOf('\n');
          userMsg.text = (nl > 0 ? reply.substring(0, nl) : reply).trim();
          reply = nl > 0 ? reply.substring(nl).trim() : '';
        }
        setState(() => _messages.add(_ChatMessage(
              isUser: false,
              text: reply.isEmpty ? '…' : reply,
              action: data['action'] == 'login'
                  ? _ChatAction.login
                  : data['posted'] != null ? _ChatAction.market : null,
            )));
        if (data['posted'] != null) _photos.clear(); // the next listing starts fresh
        _speak(reply);
      } else {
        _addError(null);
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      _addError(null);
    }

    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _addError(String? text) {
    setState(() => _messages.add(_ChatMessage(
        isUser: false,
        isError: true,
        text: text ?? _l('Connection error. Please try again.', 'ይቕረ፡ ናይ ርክብ ጌጋ። ደሓር ፈትን።',
            'ይቅርታ፣ የግንኙነት ስህተት። እንደገና ይሞክሩ።'))));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        final lang = languageNotifier.language;
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kBg,
            iconTheme: IconThemeData(color: kText),
            title: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome_rounded, color: kOnAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Habesha AI', style: tsTitleMd(color: kText)),
                Text(_l('Digital assistant', 'ዲጂታል ሓጋዚ', 'ዲጂታል ረዳት'), style: tsBodySm(color: kTextSub)),
              ]),
            ]),
            actions: [
              IconButton(
                tooltip: _l('New chat', 'ሓድሽ ዕላል', 'አዲስ ውይይት'),
                icon: Icon(Icons.refresh_rounded, color: kText),
                onPressed: () {
                  _tts.stop();
                  setState(() { _messages.clear(); _photos.clear(); _addWelcomeMessage(); });
                },
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in _messages) _buildBubble(m),
                  if (_messages.length <= 1) _buildSuggestions(lang),
                  if (_loading) _buildTypingIndicator(),
                ],
              ),
            ),
            _buildInputBar(),
          ]),
        );
      },
    );
  }

  Widget _buildSuggestions(String lang) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final s in _suggestions(lang))
        ActionChip(
          label: Text(s, style: tsBodySm(color: kText)),
          backgroundColor: kTintGreen,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          onPressed: () => _send(text: s),
        ),
    ]);
  }

  Widget _buildInputBar() {
    return Container(
      // stays above the phone's navigation buttons (Android 15 draws edge to edge)
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.paddingOf(context).bottom),
      color: kCard,
      child: _recording
          ? Row(children: [
              IconButton(
                tooltip: _l('Cancel', 'ሰርዝ', 'ሰርዝ'),
                onPressed: _cancelRecord,
                icon: Icon(Icons.delete_outline_rounded, color: kTextSub),
              ),
              const SizedBox(width: 4),
              Container(width: 12, height: 12, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    '${_l('Recording', 'ይቕረጽ ኣሎ', 'እየተቀዳ ነው')}  0:${_recSeconds.toString().padLeft(2, '0')} / 0:$_maxRecord',
                    style: tsTitleMd(color: kText)),
              ),
              _roundButton(Icons.send_rounded, kSecondary, kOnAccent, _stopAndSend,
                  tooltip: _l('Send', 'ስደድ', 'ላክ')),
            ])
          : Row(children: [
              _roundButton(Icons.photo_camera_outlined, kCardHigh, kText, _addPhoto,
                  tooltip: _l('Photo', 'ስእሊ', 'ፎቶ')),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: kCardHighest, borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _msgCtrl,
                    style: tsBodyLg(color: kText),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _l('Ask a question...', 'ሕቶ ሕተት...', 'ጥያቄ ይጠይቁ...'),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // empty field → microphone; text written → send
              _msgCtrl.text.trim().isEmpty
                  ? _roundButton(Icons.mic_rounded, kTintYellow, kInkYellow, _toggleRecord,
                      tooltip: _l('Speak', 'ተዛረብ', 'ይናገሩ'))
                  : _roundButton(Icons.send_rounded, _loading ? kCardHigh : kSecondary,
                      _loading ? kTextSub : kOnAccent, _sendText,
                      tooltip: _l('Send', 'ስደድ', 'ላክ')),
            ]),
    );
  }

  Widget _roundButton(IconData icon, Color bg, Color fg, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 48, height: 48, child: Icon(icon, color: fg, size: 22)),
        ),
      ),
    );
  }

  List<String> _suggestions(String lang) {
    if (lang == 'Tigrinya') {
      return ['ዙርያ ክሸይጥ እደሊ', 'ኣብ ካምፓላ ፎቶግራፈር ርኸበለይ', 'ናይ ሓበሻ ቤት መግቢ ኣበይ ኣሎ?', 'ኣፕ ከመይ ይሰርሕ?'];
    }
    if (lang == 'Amharic') {
      return ['ዙሪያ መሸጥ እፈልጋለሁ', 'በካምፓላ ፎቶግራፈር ፈልግ', 'የሃበሻ ምግብ ቤት የት አለ?', 'አፑ እንዴት ይሰራል?'];
    }
    return ['I want to sell a zuria', 'Find a photographer in Kampala', 'Best Habesha restaurant', 'How does the app work?'];
  }

  Widget _buildBubble(_ChatMessage msg) {
    final mine = msg.isUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: mine ? null : () => _speak(msg.text),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: msg.isError ? kTintRed : mine ? kSecondary : kCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded, color: kSecondary, size: 12),
                  const SizedBox(width: 4),
                  Text('Habesha AI', style: tsLabel(color: kSecondary).copyWith(fontSize: 10)),
                ]),
              ),
            if (msg.photo != null)
              Padding(
                padding: EdgeInsets.only(bottom: msg.text.isEmpty ? 0 : 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(msg.photo!, width: 200, fit: BoxFit.cover),
                ),
              ),
            if (msg.text.isNotEmpty)
              SelectableText(msg.text, style: tsBodyLg(color: mine ? kOnAccent : kText)),
            if (msg.action != null) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
                icon: Icon(msg.action == _ChatAction.login ? Icons.login_rounded : Icons.shopping_bag_outlined),
                label: Text(msg.action == _ChatAction.login
                    ? _l('Log in', 'እቶ', 'ግባ')
                    : _l('Open the Market', 'ዕዳጋ ክፈት', 'ገበያውን ክፈት')),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => msg.action == _ChatAction.login
                            ? const AuthScreen(returnOnLogin: true)
                            : const MarketplaceScreen())),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [_dot(0), _dot(1), _dot(2)]),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8, height: 8,
        decoration: BoxDecoration(color: kSecondary.withOpacity(0.4 + v * 0.6), shape: BoxShape.circle),
      ),
    );
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _rec.dispose();
    _tts.stop();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

enum _ChatAction { login, market }

class _ChatMessage {
  String text;
  final bool isUser;
  final bool isError;
  final Uint8List? photo;
  final _ChatAction? action;
  _ChatMessage({required this.text, required this.isUser, this.isError = false, this.photo, this.action});
}
