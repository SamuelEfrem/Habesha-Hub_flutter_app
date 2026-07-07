with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace AuthScreen redirect with SnackBar
content = content.replace(
    "Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('login_register')), backgroundColor: kSecondary.withOpacity(0.9), behavior: SnackBarBehavior.floating));"
)
print("✅ Replaced AuthScreen with SnackBar")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
