with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    } catch (_) {\n      setState(() => _isSearching = false);\n    }\n  }"
new = """    } catch (e) {
      print('GPS Error: ' + e.toString());
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Location error: ' + e.toString()),
          backgroundColor: kRed,
        ));
      }
    }
  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Debug added")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
