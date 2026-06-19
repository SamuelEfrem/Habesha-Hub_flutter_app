import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  /// If true, after login return to caller. If false, navigate to home.
  final bool returnOnLogin;
  const AuthScreen({super.key, this.returnOnLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
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
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // Email verification disabled for demo/review
      // if (cred.user != null && !cred.user!.emailVerified) {
      //   await FirebaseAuth.instance.signOut();
      //   setState(() {
      //     _loading = false;
      //     _error = 'E-posten er ikke bekreftet. Sjekk innboksen din.';
      //   });
      //   if (mounted) _showResendDialog(cred.user!.email ?? '');
      //   return;
      // }
      if (mounted) {
        if (widget.returnOnLogin) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _authError(e.code);
        _loading = false;
      });
    }
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.lock_reset_rounded, color: kSecondary),
          const SizedBox(width: 10),
          Text('Tilbakestill passord', style: tsHeadlineSm(color: kSecondary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Skriv inn e-postadressen din så sender vi en lenke for å tilbakestille passordet.',
              style: tsBodyLg()),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            style: tsBodyLg(color: kOnSurface),
            decoration: const InputDecoration(
              hintText: 'din@epost.no',
              prefixIcon: Icon(Icons.email_outlined, color: kSecondary),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Avbryt', style: tsBodySm()),
          ),
          TextButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Tilbakestillingslenke sendt til $email'),
                    backgroundColor: kGreen,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Feil: sjekk e-postadressen'),
                    backgroundColor: kRed,
                  ));
                }
              }
            },
            child: Text('Send lenke', style: tsTitleMd(color: kSecondary)),
          ),
        ],
      ),
    );
  }

  void _showResendDialog(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.mark_email_unread_rounded, color: kSecondary),
          const SizedBox(width: 10),
          Text('Bekreft e-post', style: tsHeadlineSm(color: kSecondary)),
        ]),
        content: Text(
            'E-posten $email er ikke bekreftet.\n\nSjekk innboksen din og klikk på bekreftelseslenken.',
            style: tsBodyLg()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Lukk', style: tsBodySm())),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final cred2 = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                          email: _emailCtrl.text.trim(),
                          password: _passwordCtrl.text.trim());
                  await cred2.user?.sendEmailVerification();
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Ny bekreftelseslenke sendt!')));
                  }
                } catch (_) {}
              },
              child: Text('Send på nytt', style: tsTitleMd(color: kSecondary))),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Skriv inn navn');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // Save display name
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      // Send email verification
      await cred.user?.sendEmailVerification();
      // Save nickname to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', _nameCtrl.text.trim());
      if (mounted) {
        // Show verification notice
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: kSurfaceContainerHigh,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.mark_email_unread_rounded, color: kSecondary),
              const SizedBox(width: 10),
              Text('Bekreft e-post', style: tsHeadlineSm(color: kSecondary)),
            ]),
            content: Text(
                'Vi har sendt en bekreftelseslenke til\n${_emailCtrl.text.trim()}\n\nVennligst sjekk e-posten din og klikk på lenken for å bekrefte kontoen din.',
                style: tsBodyLg()),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.returnOnLogin) {
                      Navigator.pop(context, true);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('OK, forstått',
                      style: tsTitleMd(color: kSecondary))),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _authError(e.code);
        _loading = false;
      });
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Ingen bruker med denne e-posten.';
      case 'wrong-password':
        return 'Feil passord. Prøv igjen.';
      case 'email-already-in-use':
        return 'E-posten er allerede i bruk.';
      case 'weak-password':
        return 'Passordet er for svakt (min. 6 tegn).';
      case 'invalid-email':
        return 'Ugyldig e-postadresse.';
      case 'too-many-requests':
        return 'For mange forsøk. Vent litt.';
      default:
        return 'Noe gikk galt. Prøv igjen.';
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '308436707340-5f7ns8b9mf594d9mkuc10ops4geuc77n.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        if (widget.returnOnLogin) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Google innlogging feilet. Prøv igjen.';
        _loading = false;
      });
      setState(() {
        _error = 'Feil: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: kSecondary),
        title: const Text('Habesha Hub',
            style: TextStyle(
              fontFamily: kFontHeadline,
              color: kSecondary,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            )),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kSecondary,
          labelColor: kSecondary,
          unselectedLabelColor: kOnSurfaceVariant,
          labelStyle: const TextStyle(
              fontFamily: kFontBody,
              fontWeight: FontWeight.w700,
              letterSpacing: 1),
          tabs: const [Tab(text: 'LOGG INN'), Tab(text: 'REGISTRER')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildLogin(), _buildRegister()],
      ),
    );
  }

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Velkommen tilbake', style: tsHeadlineMd(color: kSecondary)),
          const SizedBox(height: 6),
          Text('Logg inn for å administrere bedriften din.', style: tsBodySm()),
          const SizedBox(height: 32),
          Text('E-POST', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: tsBodyLg(color: kOnSurface),
            decoration: const InputDecoration(
              hintText: 'din@epost.no',
              prefixIcon: Icon(Icons.email_outlined, color: kSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Text('PASSORD', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            style: tsBodyLg(color: kOnSurface),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, color: kSecondary),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: kOnSurfaceVariant),
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kRed.withOpacity(0.3), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: tsBodySm(color: kRed))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPassword(),
              child: Text('Glemt passord?', style: tsBodySm(color: kSecondary)),
            ),
          ),
          const SizedBox(height: 12),
          primaryButton(_loading ? '' : 'Logg inn', _loading ? null : _login,
              loading: _loading, icon: Icons.login_rounded),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Divider(color: kOutlineVariant.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('eller', style: tsBodySm(color: kOnSurfaceVariant)),
            ),
            Expanded(child: Divider(color: kOutlineVariant.withOpacity(0.3))),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _signInWithGoogle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: kOutlineVariant.withOpacity(0.3), width: 0.5),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata_rounded,
                      color: kSecondary,
                      size: 24),
                ),
                const SizedBox(width: 10),
                Text('Fortsett med Google', style: tsTitleMd()),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Center(
              child: TextButton(
            onPressed: () => _tab.animateTo(1),
            child: Text('Har du ikke konto? Registrer deg',
                style: tsBodySm(color: kSecondary)),
          )),
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Opprett konto', style: tsHeadlineMd(color: kSecondary)),
          const SizedBox(height: 6),
          Text('Gratis for alle. Premium tilgjengelig for bedriftseiere.',
              style: tsBodySm()),
          const SizedBox(height: 32),
          Text('NAVN', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: tsBodyLg(color: kOnSurface),
            decoration: const InputDecoration(
              hintText: 'Fullt navn',
              prefixIcon: Icon(Icons.person_outline_rounded, color: kSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Text('E-POST', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: tsBodyLg(color: kOnSurface),
            decoration: const InputDecoration(
              hintText: 'din@epost.no',
              prefixIcon: Icon(Icons.email_outlined, color: kSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Text('PASSORD', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            style: tsBodyLg(color: kOnSurface),
            decoration: InputDecoration(
              hintText: 'Minst 6 tegn',
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, color: kSecondary),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: kOnSurfaceVariant),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kRed.withOpacity(0.3), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: tsBodySm(color: kRed))),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          goldButton(
              _loading ? '' : 'Opprett konto', _loading ? null : _register,
              loading: _loading, icon: Icons.person_add_rounded),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
            onPressed: () => _tab.animateTo(0),
            child: Text('Har du allerede konto? Logg inn',
                style: tsBodySm(color: kSecondary)),
          )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kSecondary.withOpacity(0.15), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: kSecondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                'Appen er gratis å bruke. Innlogging kreves kun for å registrere bedrift.',
                style: tsBodySm(),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
