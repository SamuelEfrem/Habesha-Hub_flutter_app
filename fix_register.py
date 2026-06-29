with open('lib/screens/auth_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _register method after _login method
old_login_end = "  Future<void> _signInWithGoogle() async {"
new_login_end = """  Future<void> _registerWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
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

  Future<void> _signInWithGoogle() async {"""

if old_login_end in content:
    content = content.replace(old_login_end, new_login_end)
    print("✅ _registerWithEmail added")
else:
    print("❌ Pattern not found")

# 2. Add register button after login button
old_btn = "        primaryButton(_loading ? '' : 'Logg inn', _loading ? null : _login, loading: _loading, icon: Icons.login_rounded),"
new_btn = """        primaryButton(_loading ? '' : 'Logg inn', _loading ? null : _login, loading: _loading, icon: Icons.login_rounded),
        const SizedBox(height: 8),
        Center(child: TextButton(
          onPressed: _loading ? null : _registerWithEmail,
          child: RichText(text: TextSpan(children: [
            TextSpan(text: 'New user? ', style: tsBodySm(color: kOnSurfaceVariant)),
            TextSpan(text: 'Register', style: tsBodySm(color: kSecondary)),
          ])),
        )),"""

if old_btn in content:
    content = content.replace(old_btn, new_btn)
    print("✅ Register button added")
else:
    print("❌ Button pattern not found")

with open('lib/screens/auth_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone!")
