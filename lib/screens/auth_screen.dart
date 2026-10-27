import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/translations.dart';

class AuthScreen extends StatefulWidget {
  final bool returnOnLogin;
  const AuthScreen({super.key, this.returnOnLogin = true});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted) {
        if (widget.returnOnLogin) { Navigator.pop(context, true); } else { Navigator.pop(context); }
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _authError(e.code); _loading = false; });
    }
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _error = tr('Enter your name')); return; }
    setState(() { _loading = true; _error = ''; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await cred.user?.sendEmailVerification();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', _nameCtrl.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: kCardHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.mark_email_unread_rounded, color: kSecondary),
              const SizedBox(width: 10),
              Text(tr('Confirm your email'), style: tsHeadlineSm(color: kSecondary)),
            ]),
            content: Text('${tr('We have sent a confirmation link to')}\n${_emailCtrl.text.trim()}\n\n${tr('Please confirm your email.')}', style: tsBodyLg()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.returnOnLogin) { Navigator.pop(context, true); } else { Navigator.pop(context); }
                },
                child: Text(tr('OK, got it'), style: tsTitleMd(color: kSecondary)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _authError(e.code); _loading = false; });
    }
  }

  Future<void> _registerWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = tr('Please enter email and password.'));
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      if (mounted) {
        if (widget.returnOnLogin) { Navigator.pop(context, true); } else { Navigator.pop(context); }
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final googleSignIn = GoogleSignIn(serverClientId: '308436707340-5f7ns8b9mf594d9mkuc10ops4geuc77n.apps.googleusercontent.com');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) { setState(() => _loading = false); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        if (widget.returnOnLogin) { Navigator.pop(context, true); } else { Navigator.pop(context); }
      }
    } catch (e) {
      setState(() { _error = tr('Google sign-in failed. Please try again.'); _loading = false; });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      if (mounted) {
        if (widget.returnOnLogin) { Navigator.pop(context, true); } else { Navigator.pop(context); }
      }
    } catch (e) {
      setState(() { _error = tr('Apple sign-in failed. Please try again.'); _loading = false; });
    }
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.lock_reset_rounded, color: kSecondary),
          const SizedBox(width: 10),
          Text(tr('Reset password'), style: tsHeadlineSm(color: kSecondary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('Enter your email address and we will send you a link to reset your password.'), style: tsBodyLg()),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: TextInputType.emailAddress, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('your@email.com'), prefixIcon: Icon(Icons.email_outlined, color: kSecondary))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Cancel'), style: tsBodySm())),
          TextButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Reset link sent to')} $email'), backgroundColor: kGreen));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Error: check the email address')), backgroundColor: kRed));
              }
            },
            child: Text(tr('Send link'), style: tsTitleMd(color: kSecondary)),
          ),
        ],
      ),
    );
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return tr('No user with this email.');
      case 'wrong-password': return tr('Wrong password. Please try again.');
      case 'email-already-in-use': return tr('This email is already in use.');
      case 'weak-password': return tr('Password is too weak (min. 6 characters).');
      case 'invalid-email': return tr('Invalid email address.');
      case 'too-many-requests': return tr('Too many attempts. Please wait a moment.');
      default: return tr('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kSecondary),
        title: const Text('Habesha Hub', style: TextStyle(fontFamily: kFontHeadline, color: kSecondary, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kSecondary,
          labelColor: kSecondary,
          unselectedLabelColor: kTextSub,
          labelStyle: const TextStyle(fontFamily: kFontBody, fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: [Tab(text: tr('LOG IN')), Tab(text: tr('SIGN UP'))],
        ),
      ),
      body: TabBarView(controller: _tab, children: [_buildLogin(), _buildRegister()]),
    );
  }

  Widget _buildLogin() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Text(tr('Welcome back'), style: tsHeadlineMd(color: kSecondary)),
        const SizedBox(height: 6),
        Text(tr('Log in to manage your business.'), style: tsBodySm()),
        const SizedBox(height: 32),
        Text(tr('EMAIL'), style: tsLabel()),
        const SizedBox(height: 8),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('your@email.com'), prefixIcon: Icon(Icons.email_outlined, color: kSecondary))),
        const SizedBox(height: 16),
        Text(tr('PASSWORD'), style: tsLabel()),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: tr('password'),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: kSecondary),
            suffixIcon: GestureDetector(onTap: () => setState(() => _obscure = !_obscure), child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kTextSub)),
          ),
          onSubmitted: (_) => _login(),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.3), width: 0.5)),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: kRed, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error, style: tsBodySm(color: kRed)))]),
          ),
        ],
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPassword, child: Text(tr('Forgot password?'), style: tsBodySm(color: kSecondary)))),
        const SizedBox(height: 12),
        primaryButton(_loading ? '' : tr('Log in'), _loading ? null : _login, loading: _loading, icon: Icons.login_rounded),
        const SizedBox(height: 8),
        Center(child: TextButton(
          onPressed: _loading ? null : _registerWithEmail,
          child: RichText(text: TextSpan(children: [
            TextSpan(text: tr('New user? '), style: tsBodySm(color: kTextSub)),
            TextSpan(text: 'Register', style: tsBodySm(color: kSecondary)),
          ])),
        )),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Divider(color: kOutlineVariant.withOpacity(0.3))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(tr('or'), style: tsBodySm(color: kTextSub))),
          Expanded(child: Divider(color: kOutlineVariant.withOpacity(0.3))),
        ]),
        const SizedBox(height: 12),
        if (Theme.of(context).platform != TargetPlatform.iOS)
        GestureDetector(
          onTap: _signInWithGoogle,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: kOutlineVariant.withOpacity(0.3), width: 0.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.network('https://www.google.com/favicon.ico', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: kSecondary, size: 24)),
              const SizedBox(width: 10),
              Text(tr('Continue with Google'), style: tsTitleMd()),
            ]),
          ),
        ),
        if (isIOS) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _signInWithApple,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.apple_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(tr('Continue with Apple'), style: tsTitleMd(color: Colors.white)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: () => _tab.animateTo(1), child: Text(tr('Don\'t have an account? Sign up'), style: tsBodySm(color: kSecondary)))),
      ]),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Text(tr('Create account'), style: tsHeadlineMd(color: kSecondary)),
        const SizedBox(height: 6),
        Text(tr('Free for everyone. Premium available for business owners.'), style: tsBodySm()),
        const SizedBox(height: 32),
        Text(tr('NAME'), style: tsLabel()),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('Full name'), prefixIcon: Icon(Icons.person_outline_rounded, color: kSecondary))),
        const SizedBox(height: 16),
        Text(tr('EMAIL'), style: tsLabel()),
        const SizedBox(height: 8),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('your@email.com'), prefixIcon: Icon(Icons.email_outlined, color: kSecondary))),
        const SizedBox(height: 16),
        Text(tr('PASSWORD'), style: tsLabel()),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: tr('At least 6 characters'),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: kSecondary),
            suffixIcon: GestureDetector(onTap: () => setState(() => _obscure = !_obscure), child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kTextSub)),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.3), width: 0.5)),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: kRed, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error, style: tsBodySm(color: kRed)))]),
          ),
        ],
        const SizedBox(height: 28),
        goldButton(_loading ? '' : tr('Create account'), _loading ? null : _register, loading: _loading, icon: Icons.person_add_rounded),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => _tab.animateTo(0), child: Text(tr('Already have an account? Log in'), style: tsBodySm(color: kSecondary)))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.15), width: 0.5)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: kSecondary, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('The app is free to use. Login is only required to register a business.'), style: tsBodySm())),
          ]),
        ),
      ]),
    );
  }
}
