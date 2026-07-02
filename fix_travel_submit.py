with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Future<void> _submit() async {
    if (_selectedService.isEmpty || _nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) return;
    setState(() => _sending = true);

    await _db.collection('travel_requests').add({"""

new = """  Future<void> _submit() async {
    if (_selectedService.isEmpty || _nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in name and email'), backgroundColor: kRed));
      return;
    }
    setState(() => _sending = true);
    try {
    await _db.collection('travel_requests').add({"""

if old in content:
    content = content.replace(old, new)
    print("✅ Validation added")

old2 = """    setState(() { _sending = false; _sent = true; });
  }"""

new2 = """    setState(() { _sending = false; _sent = true; });
    } catch (e) {
      print('Travel request error: ' + e.toString());
      setState(() => _sending = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: kRed));
    }
  }"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Error handling added")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
