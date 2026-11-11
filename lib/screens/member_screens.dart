import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'auth_screen.dart';

// Browsing is open to all. To book, sell or contact a seller you need a real
// account: confirmed email + name, phone, city and address (members/{uid},
// private: only the member and the admin can read it) + the admin's approval.
// Accounts older than the moment the admin turned approval on pass automatically
// (Cloud Function onMemberCreated).

final _members = FirebaseFirestore.instance.collection('members');
const kWhatsAppSupport = '4797374482';

String _l(String en, String ti, String am) {
  final l = languageNotifier.language;
  return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
}

Future<void> _notice(BuildContext context, String title, String body) => showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: kCard,
    title: Text(title, style: tsTitleMd(color: kText)),
    content: Text(body, style: tsBodyLg(color: kText)),
    actions: [
      TextButton(
        onPressed: () => launchUrl(Uri.parse('https://wa.me/$kWhatsAppSupport'), mode: LaunchMode.externalApplication),
        child: Text('WhatsApp', style: tsBodySm(color: kTextSub))),
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: tsTitleMd(color: kSecondary))),
    ],
  ),
);

/// True when this person may book / sell / contact. Asks for whatever is missing.
Future<bool> ensureMember(BuildContext context) async {
  var u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
    u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous || !context.mounted) return false;
  }
  if (u.email == 'samuelefriem@gmail.com') return true;
  try { await u.reload(); } catch (_) {}
  u = FirebaseAuth.instance.currentUser;
  if (u == null || !context.mounted) return false;

  if (!u.emailVerified) {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ConfirmEmailScreen()));
    if (ok != true || !context.mounted) return false;
  }

  // the database rules read the login token, which can be older than the confirmation
  if ((await u.getIdTokenResult()).claims?['email_verified'] != true) await u.getIdToken(true);
  if (!context.mounted) return false;
  var doc = await _members.doc(u.uid).get();
  if (!context.mounted) return false;
  if (!doc.exists) {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const MemberFormScreen()));
    if (ok != true || !context.mounted) return false;
    // the Cloud Function passes existing accounts; it can need some seconds to wake up
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(seconds: 2));
      doc = await _members.doc(u.uid).get();
      if (!context.mounted) return false;
      if (doc.data()?['status'] != 'pending') break;
    }
  }
  final status = doc.data()?['status'];
  if (status == 'approved') return true;
  if (status == 'rejected') {
    await _notice(context, _l('Not approved', 'ኣይጸደቐን', 'አልጸደቀም'),
        _l('Your account was not approved. Contact us on WhatsApp.',
           'ሕሳብኩም ኣይጸደቐን። ብዋትስኣፕ ተወከሱና።', 'መለያዎ አልጸደቀም። በዋትስአፕ ያግኙን።'));
    return false;
  }
  await _notice(context, _l('Waiting for approval', 'ፍቓድ ይጽበ ኣሎ', 'ማረጋገጫ በመጠባበቅ ላይ'),
      _l('Thank you! We check your details and approve your account soon. You can look around in the app until then.',
         'የቐንየልና! ዝርዝርኩም ተመልኪትና ቀልጢፍና ነጽድቖ። ክሳብ ሽዑ ኣብ ኣፕ ክትርእዩ ትኽእሉ ኢኹም።',
         'እናመሰግናለን! ዝርዝርዎን አይተን በቅርቡ እናጸድቃለን። እስከዚያ በመተግበሪያው ማየት ይችላሉ።'));
  return false;
}

// ── Confirm email ───────────────────────────────────────────
class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key});
  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _newEmail = TextEditingController();
  String _msg = '';
  bool _busy = false;

  @override
  void dispose() { _newEmail.dispose(); super.dispose(); }

  Future<void> _run(Future<void> Function() job) async {
    setState(() { _busy = true; _msg = ''; });
    try {
      await job();
    } on FirebaseAuthException catch (e) {
      _msg = e.code == 'requires-recent-login'
          ? _l('Please log out and log in again first.', 'በጃኹም መጀመርታ ወጺእኩም ደጊምኩም እተዉ።', 'እባክዎ መጀመሪያ ወጥተው እንደገና ይግቡ።')
          : e.code == 'invalid-email'
              ? _l('This email is not valid.', 'እዚ ኢመይል ቅኑዕ ኣይኮነን።', 'ይህ ኢሜይል ትክክል አይደለም።')
              : _l('Please try again in a moment.', 'በጃኹም ድሕሪ ቁሩብ ደጊምኩም ፈትኑ።', 'እባክዎ ከትንሽ ቆይታ በኋላ እንደገና ይሞክሩ።');
    } catch (_) {
      _msg = _l('Please try again in a moment.', 'በጃኹም ድሕሪ ቁሩብ ደጊምኩም ፈትኑ።', 'እባክዎ ከትንሽ ቆይታ በኋላ እንደገና ይሞክሩ።');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _check() => _run(() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
      await FirebaseAuth.instance.currentUser?.getIdToken(true); // the database rules read this
      if (mounted) Navigator.pop(context, true);
    } else {
      _msg = _l('Not confirmed yet. Open the email and press the link. If nothing came, use a real email address below.',
                'ገና ኣይተረጋገጸን። ነቲ ኢመይል ከፊትኩም ነቲ መላግቦ ጠውቑ። እንተዘይመጺኡ ኣብ ታሕቲ ሓቀኛ ኢመይል ተጠቐሙ።',
                'ገና አልተረጋገጠም። ኢሜይሉን ከፍተው ሊንኩን ይጫኑ። ካልደረሰ ከታች እውነተኛ ኢሜይል ይጠቀሙ።');
    }
  });

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(_l('Confirm your email', 'ኢመይልኩም ኣረጋግጹ', 'ኢሜይልዎን ያረጋግጡ'), style: tsTitleMd(color: kText))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(_l('To book, sell or contact sellers you need a real email address. We sent a link to:',
                'ንምሓዝ፡ ንምሻጥ ወይ ሸያጢ ንምርካብ ሓቀኛ ኢመይል የድሊ። መላግቦ ናብዚ ሰዲድና፦',
                'ለማስያዝ፣ ለመሸጥ ወይም ሻጮችን ለማግኘት እውነተኛ ኢሜይል ያስፈልጋል። ሊንክ ወደዚህ ልከናል፦'), style: tsBodyLg(color: kText)),
        const SizedBox(height: 8),
        Text(email.isEmpty ? '–' : email, style: tsTitleMd(color: kText)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _check,
          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
          child: Text(_l('I have confirmed', 'ኣረጋጊጸ ኣለኹ', 'አረጋግጫለሁ')),
        ),
        const SizedBox(height: 8),
        if (email.isNotEmpty) OutlinedButton(
          onPressed: _busy ? null : () => _run(() async {
            await FirebaseAuth.instance.currentUser?.sendEmailVerification();
            _msg = _l('Sent again. Check spam too.', 'ደጊምና ሰዲድናዮ። ኣብ spam እውን ርኣዩ።', 'እንደገና ተልኳል። spam ውስጥም ይመልከቱ።');
          }),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          child: Text(_l('Send the email again', 'ኢመይል ደጊምካ ስደድ', 'ኢሜይሉን እንደገና ላክ'), style: tsBodySm(color: kText)),
        ),
        if (_msg.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(_msg, style: tsBodySm(color: kRed)),
        ),
        const SizedBox(height: 28),
        Text(_l('Wrong or fake email? Use a real one:', 'ጌጋ ወይ ሓሶት ኢመይል? ሓቀኛ ተጠቐሙ፦', 'የተሳሳተ ወይም ሐሰተኛ ኢሜይል? እውነተኛ ይጠቀሙ፦'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 8),
        TextField(
          controller: _newEmail,
          keyboardType: TextInputType.emailAddress,
          style: tsBodyLg(color: kText),
          decoration: const InputDecoration(hintText: 'name@gmail.com'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(() async {
            final e = _newEmail.text.trim();
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(e)) {
              _msg = _l('This email is not valid.', 'እዚ ኢመይል ቅኑዕ ኣይኮነን።', 'ይህ ኢሜይል ትክክል አይደለም።');
              return;
            }
            await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(e);
            _msg = _l('We sent a link to $e. Press it, log in again and continue.',
                      'ናብ $e መላግቦ ሰዲድና። ጠዊቕኩም ደጊምኩም እተዉ።', 'ወደ $e ሊንክ ልከናል። ተጭነው እንደገና ይግቡ።');
          }),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          child: Text(_l('Change email', 'ኢመይል ቀይር', 'ኢሜይል ቀይር'), style: tsBodySm(color: kText)),
        ),
      ]),
    );
  }
}

// ── Name, phone, city, address ──────────────────────────────
class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  late final _name = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  String _error = '';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _city.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (_name.text.trim().length < 2 || digits.length < 8 || _city.text.trim().isEmpty) {
      setState(() => _error = _l('Please fill in name, WhatsApp (with country code, e.g. +47…) and city.',
          'በጃኹም ስም፡ ዋትስኣፕ (ምስ ኮድ ሃገር፡ ን.ኣ. +47…) ከተማን ምልኡ።', 'እባክዎ ስም፣ ዋትስአፕ (ከአገር ኮድ ጋር፣ ለምሳሌ +47…) እና ከተማ ይሙሉ።'));
      return;
    }
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() { _saving = true; _error = ''; });
    try {
      await u.getIdToken(true);
      await _members.doc(u.uid).set({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'email': u.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() {
        _saving = false;
        _error = _l('Could not save. Check your internet and try again.', 'ክዕቀብ ኣይከኣለን። ኢንተርነትኩም ኣረጋግጹ።', 'ማስቀመጥ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።');
      });
    }
  }

  Widget _field(TextEditingController c, String label, {TextInputType? type, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      keyboardType: type,
      style: tsBodyLg(color: kText),
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(backgroundColor: kBg, title: Text(_l('Your details', 'ዝርዝርኩም', 'ዝርዝርዎ'), style: tsTitleMd(color: kText))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(_l('We keep Habesha Hub safe by checking everyone who books or sells. Only Habesha Hub sees these details. They are never shown to others.',
              'ንኹሉ ዝሕዝን ዝሸጥን ብምምርማር ንሃበሻ ሃብ ውሑስ ንገብሮ። እዚ ዝርዝር ሃበሻ ሃብ ጥራይ እዩ ዝርእዮ። ንኻልኦት ፈጺሙ ኣይርአን።',
              'የሚያስይዙና የሚሸጡትን ሁሉ በማረጋገጥ ሀበሻ ሀብን ደህንነቱ የተጠበቀ እናደርጋለን። ይህን ዝርዝር የሚያየው ሀበሻ ሀብ ብቻ ነው። ለሌሎች በፍጹም አይታይም።'),
          style: tsBodySm(color: kTextSub)),
      const SizedBox(height: 18),
      _field(_name, _l('Full name', 'ምሉእ ስም', 'ሙሉ ስም')),
      _field(_phone, _l('Phone (WhatsApp)', 'ቴሌፎን (ዋትስኣፕ)', 'ስልክ (ዋትስአፕ)'), type: TextInputType.phone, hint: '+47…'),
      _field(_city, _l('City', 'ከተማ', 'ከተማ')),
      _field(_address, _l('Address (optional)', 'ኣድራሻ (ኣማራጺ)', 'አድራሻ (አማራጭ)'), type: TextInputType.streetAddress),
      if (_error.isNotEmpty) Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(_error, style: tsBodySm(color: kRed)),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
        child: Text(_saving ? '…' : _l('Send', 'ስደድ', 'ላክ')),
      ),
    ]),
  );
}

// ── Admin: approve people ───────────────────────────────────
class MembersAdminTab extends StatefulWidget {
  const MembersAdminTab({super.key});
  @override
  State<MembersAdminTab> createState() => _MembersAdminTabState();
}

class _MembersAdminTabState extends State<MembersAdminTab> {
  String _filter = 'pending';
  final _config = FirebaseFirestore.instance.collection('app_config').doc('members');

  void _set(String id, String status) => _members.doc(id).update({'status': status, 'decidedAt': FieldValue.serverTimestamp()});

  Future<void> _toggle(bool on) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      title: Text(on ? 'Require approval for everyone?' : 'Turn approval off?', style: tsTitleMd(color: kText)),
      content: Text(on
          ? 'Only turn this on when most people have the new app version. People on old versions without approval can then no longer book or sell. Existing accounts are approved when they confirm their email and fill in the form.'
          : 'Everyone with an account can book and sell again.', style: tsBodySm(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: tsBodySm(color: kTextSub))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes', style: tsTitleMd(color: kSecondary))),
      ],
    ));
    if (ok != true) return;
    await _config.set({'enforce': on, if (on) 'enforcedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _config.snapshots(),
        builder: (_, snap) => SwitchListTile(
          title: Text('Approval required', style: tsTitleMd(color: kText)),
          subtitle: Text('Book, sell and contact only for approved people', style: tsBodySm(color: kTextSub)),
          value: snap.data?.data()?['enforce'] == true,
          activeThumbColor: kHabGreen,
          onChanged: _toggle,
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          for (final (k, label) in [('pending', 'New'), ('approved', 'Approved'), ('rejected', 'Rejected')])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(label), selected: _filter == k, onSelected: (_) => setState(() => _filter = k)),
            ),
        ]),
      ),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _members.where('status', isEqualTo: _filter).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: tsBodySm(color: kRed)));
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          final docs = snap.data!.docs.toList()..sort((a, b) {
            final x = a.data()['createdAt'], y = b.data()['createdAt'];
            return x is Timestamp && y is Timestamp ? y.compareTo(x) : 0;
          });
          if (docs.isEmpty) return Center(child: Text('Nobody here', style: tsTitleMd(color: kTextSub)));
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) => _card(docs[i]),
          );
        },
      )),
    ]);
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    String s(String k) => (d[k] ?? '').toString();
    final digits = s('phone').replaceAll(RegExp(r'[^0-9]'), '');
    final mail = Uri(scheme: 'mailto', path: s('email'), queryParameters: {
      'subject': 'Habesha Hub: your account is approved',
      'body': 'Hi ${s('name')},\n\nYour Habesha Hub account is approved. You can now book, sell and contact sellers in the app.\n\nHabesha Hub',
    });
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s('name'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 4),
        SelectableText('${s('email')}\n${s('phone')}\n${s('address')}, ${s('city')}', style: tsBodySm(color: kTextSub)),
        Row(children: [
          if (digits.isNotEmpty) IconButton(
            tooltip: 'WhatsApp',
            icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            onPressed: () => launchUrl(Uri.parse('https://wa.me/$digits'), mode: LaunchMode.externalApplication)),
          if (s('email').isNotEmpty) IconButton(
            tooltip: 'Email',
            icon: Icon(Icons.mail_outline_rounded, color: kInkBlue),
            onPressed: () => launchUrl(Uri.parse(mail.toString().replaceAll('+', '%20')))),
          const Spacer(),
          if (_filter != 'rejected') TextButton(onPressed: () => _set(doc.id, 'rejected'), child: Text('Reject', style: tsBodySm(color: kRed))),
          if (_filter != 'approved') FilledButton(
            onPressed: () => _set(doc.id, 'approved'),
            style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
            child: const Text('Approve')),
        ]),
      ]),
    );
  }
}
