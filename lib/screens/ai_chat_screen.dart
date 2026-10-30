import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../models/business.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _db = FirebaseFirestore.instance;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  bool _listening = false;
  bool _sttAvailable = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initStt();
    _addWelcomeMessage();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize();
    if (mounted) setState(() {});
  }

  String _ttsLang(String lang) {
    if (lang == 'Tigrinya') return 'ti-ET';
    if (lang == 'Amharic') return 'am-ET';
    return 'en-US';
  }

  /// Phones have no good Tigrinya / Amharic voice — the English voice reads
  /// Ge'ez script wrongly. So the assistant only speaks English answers.
  static final _geez = RegExp('[\u1200-\u139F\u2D80-\u2DDF\uAB00-\uAB2F]');
  bool _canSpeak(String text) =>
      languageNotifier.language == 'English' && !_geez.hasMatch(text);

  Future<void> _speak(String text) async {
    await _tts.stop();
    if (!_canSpeak(text)) return;
    await _tts.setLanguage(_ttsLang('English'));
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    if (!_sttAvailable) return;
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final lang = languageNotifier.language;
    final locale = lang == 'Tigrinya'
        ? 'ti_ET'
        : lang == 'Amharic'
            ? 'am_ET'
            : 'en_US';
    setState(() => _listening = true);
    await _stt.listen(
      localeId: locale,
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _listening = false;
            _msgCtrl.text = result.recognizedWords;
          });
          if (result.recognizedWords.isNotEmpty) _sendMessage();
        }
      },
    );
  }

  void _addWelcomeMessage() {
    final lang = languageNotifier.language;
    String welcome;
    if (lang == 'Tigrinya') {
      welcome =
          'ሰላም! ኣነ ናይ ሓበሻ ሃብ AI ሓጋዚ እየ። ብዛዕባ ትካላት፡ ቡኪንግ፡ ወይ ናይ ሓበሻ ሕብረተሰብ ዝኾነ ሕቶ ሕተተኒ!';
    } else if (lang == 'Amharic') {
      welcome =
          'ሰላም! እኔ የሃበሻ ሃብ AI ረዳት ነኝ። ስለ ድርጅቶች፣ ቀጠሮ፣ ወይም ስለ ሃበሻ ማህበረሰብ ይጠይቁኝ!';
    } else {
      welcome =
          'Hello! I\'m the Habesha Hub AI assistant. Ask me anything about businesses, bookings, or the Habesha community!';
    }
    setState(() => _messages.add(_ChatMessage(text: welcome, isUser: false)));
  }

  Future<List<Business>> _getBusinesses() async {
    try {
      final snap = await _db
          .collection('businesses')
          .where('status', isEqualTo: 'approved')
          .get();
      return snap.docs
          .map((d) => Business.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static const _aiEndpoint =
      'https://europe-west1-habesha-hub-7bd1d.cloudfunctions.net/aiChat';

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      // Gemini is called through our Cloud Function — the API key stays on the server.
      final history = _messages
          .skip(1)
          .where((m) => !m.isError)
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList();
      if (history.isNotEmpty) history.removeLast(); // last one is the question itself

      final response = await http
          .post(
            Uri.parse(_aiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lang': languageNotifier.language,
              'history': history,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final reply = (jsonDecode(response.body)['reply'] ?? '') as String;
        setState(() => _messages.add(_ChatMessage(text: reply, isUser: false)));
        _speak(reply);
      } else {
        _addError(languageNotifier.language);
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      _addError(languageNotifier.language);
    }

    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _addError(String lang) {
    final msg = lang == 'Tigrinya'
        ? 'ይቕረ፡ ናይ ርክብ ጌጋ። ደሓር ፈትን።'
        : lang == 'Amharic'
            ? 'ይቅርታ፣ የግንኙነት ስህተት። እንደገና ይሞክሩ።'
            : 'Connection error. Please try again.';
    setState(() =>
        _messages.add(_ChatMessage(text: msg, isUser: false, isError: true)));
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
            backgroundColor: kCard,
            iconTheme: IconThemeData(color: kSecondary),
            title: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome_rounded,
                    color: kOnAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Habesha AI', style: tsTitleMd(color: kSecondary)),
                Text(
                    lang == 'Tigrinya'
                        ? 'ዲጂታል ሓጋዚ'
                        : lang == 'Amharic'
                            ? 'ዲጂታል ረዳት'
                            : 'Digital Assistant',
                    style: tsBodySm(color: kTextSub)),
              ]),
            ]),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: kSecondary),
                onPressed: () {
                  _tts.stop();
                  setState(() {
                    _messages.clear();
                    _addWelcomeMessage();
                  });
                },
              ),
            ],
          ),
          body: Column(children: [
            if (_messages.length <= 1)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          lang == 'Tigrinya'
                              ? 'ናይ ቅልጡፍ ሕቶታት'
                              : lang == 'Amharic'
                                  ? 'ፈጣን ጥያቄዎች'
                                  : 'Quick questions',
                          style: tsLabel(color: kTextSub)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestions(lang)
                            .map((s) => GestureDetector(
                                  onTap: () {
                                    _msgCtrl.text = s;
                                    _sendMessage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: kPrimaryContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(100),
                                      ),
                                    child: Text(s,
                                        style: tsBodySm(color: kSecondary)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ]),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _buildTypingIndicator();
                  return _buildBubble(_messages[i]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kCard,
                ),
              child: Row(children: [
                if (_sttAvailable)
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _listening ? kRed.withOpacity(0.15) : kCardHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _listening
                                ? kRed
                                : kSecondary.withOpacity(0.3)),
                      ),
                      child: Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _listening ? kRed : kSecondary,
                          size: 20),
                    ),
                  ),
                if (_sttAvailable) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: kCardHighest,
                        borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _msgCtrl,
                      style: tsBodyLg(color: kText),
                      decoration: InputDecoration(
                        hintText: lang == 'Tigrinya'
                            ? 'ሕቶ ሕተት...'
                            : lang == 'Amharic'
                                ? 'ጥያቄ ይጠይቁ...'
                                : 'Ask a question...',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _loading ? kCardHigh : kSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send_rounded,
                        color: _loading ? kTextSub : kOnAccent,
                        size: 20),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  List<String> _suggestions(String lang) {
    if (lang == 'Tigrinya')
      return [
        'ኣብ ካምፓላ ፎቶግራፈር ርኸበለይ',
        'ናይ ሓበሻ ቤት መግቢ ኣበይ ኣሎ?',
        'ናይ መርዓ ቦታ ኣርእዮኒ',
        'ናይ ጸጉሪ ሳሎን'
      ];
    if (lang == 'Amharic')
      return [
        'በካምፓላ ፎቶግራፈር ፈልግ',
        'የሃበሻ ምግብ ቤት የት አለ?',
        'የሰርግ ቦታ ምክር',
        'የፀጉር ሳሎን'
      ];
    return [
      'Find photographer in Kampala',
      'Best Habesha restaurant',
      'Wedding venue',
      'Hair salon near me'
    ];
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: msg.isUser ? null : () => _speak(msg.text),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: msg.isError
                ? kRed.withOpacity(0.1)
                : msg.isUser
                    ? kSecondary
                    : kCardHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
            ),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!msg.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: kSecondary, size: 12),
                  const SizedBox(width: 4),
                  Text('Habesha AI',
                      style: tsLabel(color: kSecondary).copyWith(fontSize: 10)),
                  const Spacer(),
                  Icon(Icons.volume_up_rounded,
                      color: kSecondary.withOpacity(0.6), size: 12),
                ]),
              ),
            Text(msg.text,
                style: tsBodyLg(
                    color: msg.isUser ? kOnAccent : kText)),
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
          color: kCardHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [_dot(0), _dot(1), _dot(2)]),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: kSecondary.withOpacity(0.4 + v * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  _ChatMessage(
      {required this.text, required this.isUser, this.isError = false});
}
