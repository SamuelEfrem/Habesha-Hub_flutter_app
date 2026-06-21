import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../models/business.dart';
//import '../config/secrets.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _db = FirebaseFirestore.instance;
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final lang = languageNotifier.language;
    String welcome;
    if (lang == 'Tigrinya') {
      welcome =
          'ሰላም! ኣነ ናይ ሓበሻ ሃብ AI ሓጋዚ እየ። ብዛዕባ ትካላት፡ ቡኪንግ፡ ወይ ናይ ሓበሻ ሕብረተሰብ ዝኾነ ሕቶ ሕተተኒ!';
    } else if (lang == 'English') {
      welcome =
          'Hello! I\'m the Habesha Hub AI assistant. Ask me anything about businesses, bookings, or the Habesha community!';
    } else if (lang == 'Amharic') {
      welcome =
          'ሰላም! እኔ የሃበሻ ሃብ AI ረዳት ነኝ። ስለ ድርጅቶች፣ ቀጠሮ፣ ወይም ስለ ሃበሻ ማህበረሰብ ይጠይቁኝ!';
    } else {
      welcome =
          'Hei! Jeg er Habesha Hub AI-assistent. Spør meg om bedrifter, booking, eller alt om Habesha-fellesskapet!';
    }
    setState(() => _messages.add(_ChatMessage(text: welcome, isUser: false)));
  }

  Future<List<Business>> _getBusinesses() async {
    final snap = await _db
        .collection('businesses')
        .where('status', isEqualTo: 'approved')
        .get();
    return snap.docs
        .map((d) => Business.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });

    _scrollToBottom();
    print('Starting AI request...');

    try {
      // Get businesses from Firestore
      final businesses = await _getBusinesses();
      print('Got ${businesses.length} businesses');
      final businessContext = businesses
          .map((b) =>
              'Navn: ${b.name}, Kategori: ${b.category}, Adresse: ${b.address}, Beskrivelse: ${b.description}, Telefon: ${b.phone}')
          .join('\n');

      final lang = languageNotifier.language;
      final langInstruction = lang == 'Tigrinya'
          ? 'You MUST respond in Tigrinya (ትግርኛ). Keep responses very short - maximum 2 sentences. Use simple, common Tigrinya words. Do not translate from Norwegian.'
          : lang == 'English'
              ? 'Always respond in English. Keep responses concise.'
              : lang == 'Amharic'
                  ? 'Always respond in Amharic (አማርኛ). Keep responses very short - maximum 2 sentences.'
                  : 'Svar alltid på norsk. Hold svarene korte og tydelige.';

      final systemPrompt = '''$langInstruction

You are a helpful AI assistant for Habesha Hub — an app for finding Ethiopian and Eritrean businesses and services worldwide, especially in Kampala, Addis Ababa, and Norway.

Here are all available businesses in the system:
$businessContext

Help users find businesses, give recommendations, answer questions about Habesha culture, weddings, food, and everything related to the community.
Be friendly, specific and helpful. If you recommend businesses, mention their name and contact info.
Keep responses short and clear — max 3-4 sentences unless the user asks for more details.

IMPORTANT: $langInstruction''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': const String.fromEnvironment('ANTHROPIC_KEY', defaultValue: ''),
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 500,
          'system': systemPrompt,
          'messages': [
            ..._messages
                .where((m) => m.isUser || _messages.indexOf(m) > 0)
                .map((m) => {
                      'role': m.isUser ? 'user' : 'assistant',
                      'content': m.text,
                    }),
            {'role': 'user', 'content': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        print('API Status: ${response.statusCode}');
        print('API Body: ${response.body}');
        final data = jsonDecode(response.body);
        final reply = data['content'][0]['text'] as String;
        setState(() => _messages.add(_ChatMessage(text: reply, isUser: false)));
      } else {
        setState(() => _messages.add(_ChatMessage(
              text: lang == 'Tigrinya'
                  ? 'ይቕረ፡ ሕጂ ምርካብ ኣይከኣልኩን። ደሓር ፈትን።'
                  : lang == 'English'
                      ? 'Sorry, I couldn\'t connect. Please try again.'
                      : 'Beklager, kunne ikke koble til. Prøv igjen.',
              isUser: false,
              isError: true,
            )));
      }
    } catch (e) {
      print('AI Error: $e');
      final lang = languageNotifier.language;
      setState(() => _messages.add(_ChatMessage(
            text: lang == 'English'
                ? 'Connection error. Please try again.'
                : 'Tilkoblingsfeil. Prøv igjen.',
            isUser: false,
            isError: true,
          )));
    }

    setState(() => _loading = false);
    _scrollToBottom();
    ;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.language;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                const BoxDecoration(color: kSecondary, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF1A1200), size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Habesha AI', style: tsTitleMd(color: kSecondary)),
            Text(
              lang == 'Tigrinya'
                  ? 'ዲጂታል ሓጋዚ'
                  : lang == 'English'
                      ? 'Digital Assistant'
                      : lang == 'Amharic'
                          ? 'ዲጂታል ረዳት'
                          : 'Digital assistent',
              style: tsBodySm(color: kOnSurfaceVariant),
            ),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kSecondary),
            onPressed: () => setState(() {
              _messages.clear();
              _addWelcomeMessage();
            }),
          ),
        ],
      ),
      body: Column(children: [
        // Quick suggestions
        if (_messages.length <= 1)
          Container(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                lang == 'Tigrinya'
                    ? 'ናይ ቅልጡፍ ሕቶታት'
                    : lang == 'English'
                        ? 'Quick questions'
                        : lang == 'Amharic'
                            ? 'ፈጣን ጥያቄዎች'
                            : 'Raske spørsmål',
                style: tsLabel(color: kOnSurfaceVariant),
              ),
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
                              border: Border.all(
                                  color: kSecondary.withOpacity(0.3),
                                  width: 0.5),
                            ),
                            child: Text(s, style: tsBodySm(color: kSecondary)),
                          ),
                        ))
                    .toList(),
              ),
            ]),
          ),

        // Messages
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

        // Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kSurfaceContainer,
            border: Border(
                top:
                    BorderSide(color: kSecondary.withOpacity(0.1), width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kSurfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: InputDecoration(
                    hintText: lang == 'Tigrinya'
                        ? 'ሕቶ ሕተት...'
                        : lang == 'English'
                            ? 'Ask a question...'
                            : lang == 'Amharic'
                                ? 'ጥያቄ ይጠይቁ...'
                                : 'Still et spørsmål...',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _loading ? kSurfaceContainerHigh : kSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _loading ? kOnSurfaceVariant : const Color(0xFF1A1200),
                  size: 20,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  List<String> _suggestions(String lang) {
    if (lang == 'Tigrinya') {
      return [
        'ኣብ ካምፓላ ፎቶግራፈር ርኸበለይ',
        'ናይ ሓበሻ ቤት መግቢ ኣበይ ኣሎ?',
        'ናይ መርዓ ቦታ ኣርእዮኒ',
        'ናይ ጸጉሪ ሳሎን ኣበይ ኣሎ?',
      ];
    }
    if (lang == 'Amharic') {
      return [
        'በካምፓላ ፎቶግራፈር ፈልግ',
        'የሃበሻ ምግብ ቤት የት አለ?',
        'የሰርግ ቦታ ምክር',
        'የፀጉር ሳሎን ፈልግ',
      ];
    }
    if (lang == 'English') {
      return [
        'Find photographer in Kampala',
        'Best Habesha restaurant',
        'Wedding venue recommendations',
        'Hair salon near me',
      ];
    }
    return [
      'Finn kameraman i Kampala',
      'Beste etiopiske restaurant',
      'Bryllupshall anbefalinger',
      'Frisør i nærheten',
    ];
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isError
              ? kRed.withOpacity(0.1)
              : msg.isUser
                  ? kSecondary
                  : kSurfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!msg.isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: kSecondary, size: 12),
                const SizedBox(width: 4),
                Text('Habesha AI',
                    style: tsLabel(color: kSecondary).copyWith(fontSize: 10)),
              ]),
            ),
          Text(
            msg.text,
            style: tsBodyLg(
                color: msg.isUser ? const Color(0xFF1A1200) : kOnSurface),
          ),
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0),
          _dot(1),
          _dot(2),
        ]),
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
