import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

/// Unlock paid game content with a code the admin sends on WhatsApp.
/// The code is checked on the server (Cloud Function "redeemCode") and only
/// works for the phone number it was made for, so the user must verify their
/// phone number by SMS first.
class UnlockService {
  UnlockService._();
  static final instance = UnlockService._();

  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<Set<String>> unlocked() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return {};
    final d = await _db.collection('users').doc(u.uid).get();
    final m = (d.data()?['unlocks'] as Map?) ?? {};
    return {for (final e in m.entries) if (e.value == true) e.key.toString()};
  }

  /// The 450 paid driving theory questions (readable only after unlock)
  Future<List<Map<String, dynamic>>> theoryQuestions() async {
    final snap = await _db.collection('theory_pro').orderBy('order').get();
    return [
      for (final d in snap.docs)
        for (final q in (d.data()['questions'] as List? ?? const []))
          Map<String, dynamic>.from(q as Map),
    ];
  }

  /// Returns null on success, otherwise a message for the user.
  Future<String?> redeem(BuildContext context, String code) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return tr('Please log in first');
    }
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      if (!context.mounted) return null;
      final ok = await _verifyPhone(context);
      if (!ok) return tr('Phone number not verified');
    }
    try {
      // New token so the server sees the verified phone number
      await FirebaseAuth.instance.currentUser!.getIdToken(true);
      await _functions.httpsCallable('redeemCode').call({'code': code});
      return null;
    } on FirebaseFunctionsException catch (e) {
      switch (e.message) {
        case 'other-phone': return tr('This code belongs to another phone number');
        case 'used': return tr('This code has already been used');
        case 'code': return tr('Wrong code');
        case 'phone': return tr('Phone number not verified');
        default: return '${tr('Error')}: ${e.message}';
      }
    } catch (e) {
      return '${tr('Error')}: $e';
    }
  }

  /// Ask for the phone number, send an SMS code and link the number to the account.
  Future<bool> _verifyPhone(BuildContext context) async {
    final phoneCtrl = TextEditingController(text: '+47');
    final smsCtrl = TextEditingController();
    String? verificationId;
    String? error;
    bool busy = false, done = false;

    Future<void> link(PhoneAuthCredential cred, void Function(void Function()) set) async {
      try {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
        done = true;
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      } on FirebaseAuthException catch (e) {
        set(() {
          busy = false;
          error = e.code == 'credential-already-in-use' || e.code == 'provider-already-linked'
              ? tr('This phone number is already used by another account')
              : e.code == 'invalid-verification-code' ? tr('Wrong SMS code') : e.message;
        });
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Verify your phone number'), style: tsHeadlineSm(color: kText)),
          const SizedBox(height: 6),
          Text(tr('The code only works for the phone number you gave on WhatsApp.'),
              style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 16),
          TextField(
            controller: verificationId == null ? phoneCtrl : smsCtrl,
            keyboardType: TextInputType.phone,
            style: tsBodyLg(color: kText),
            decoration: InputDecoration(
              labelText: verificationId == null ? tr('Phone number') : tr('SMS code'),
              filled: true, fillColor: kCardHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: tsBodySm(color: kRed)),
          ],
          const SizedBox(height: 14),
          goldButton(verificationId == null ? tr('Send SMS') : tr('Confirm'), busy ? null : () async {
            set(() { busy = true; error = null; });
            if (verificationId == null) {
              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: phoneCtrl.text.replaceAll(' ', ''),
                verificationCompleted: (cred) => link(cred, set),       // Android auto-read
                verificationFailed: (e) => set(() { busy = false; error = e.message; }),
                codeSent: (id, _) => set(() { verificationId = id; busy = false; }),
                codeAutoRetrievalTimeout: (_) {},
              );
            } else {
              await link(PhoneAuthProvider.credential(
                  verificationId: verificationId!, smsCode: smsCtrl.text.trim()), set);
            }
          }, loading: busy),
        ]),
      )),
    );
    return done;
  }
}
