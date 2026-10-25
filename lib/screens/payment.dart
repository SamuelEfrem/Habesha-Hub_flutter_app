import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/translations.dart';
import 'services_screen.dart';
import 'provider_extras.dart';

// ═══════════════════════════════════════════════════════════
// PAYMENT — one payment method per country the customer pays from.
// Admin edits the numbers in Firestore:  settings/payment
//   { methods: { NO: {method:'Vipps', number:'+47…', name:'Habesha Hub'}, … } }
// ═══════════════════════════════════════════════════════════
class PayCountry {
  final String code, name, flag, method, currency;
  const PayCountry(this.code, this.name, this.flag, this.method, this.currency);
}

const kPayCountries = [
  PayCountry('NO', 'Norway',         '🇳🇴', 'Vipps',                'NOK'),
  PayCountry('SE', 'Sweden',         '🇸🇪', 'Swish',                'SEK'),
  PayCountry('DK', 'Denmark',        '🇩🇰', 'MobilePay',            'DKK'),
  PayCountry('GB', 'United Kingdom', '🇬🇧', 'Bank transfer',        'GBP'),
  PayCountry('DE', 'Germany',        '🇩🇪', 'PayPal',               'EUR'),
  PayCountry('NL', 'Netherlands',    '🇳🇱', 'PayPal',               'EUR'),
  PayCountry('FR', 'France',         '🇫🇷', 'PayPal',               'EUR'),
  PayCountry('BE', 'Belgium',        '🇧🇪', 'PayPal',               'EUR'),
  PayCountry('IT', 'Italy',          '🇮🇹', 'PayPal',               'EUR'),
  PayCountry('CH', 'Switzerland',    '🇨🇭', 'TWINT',                'CHF'),
  PayCountry('US', 'United States',  '🇺🇸', 'Zelle',                'USD'),
  PayCountry('CA', 'Canada',         '🇨🇦', 'Interac e-Transfer',   'CAD'),
  PayCountry('ET', 'Ethiopia',       '🇪🇹', 'telebirr',             'ETB'),
  PayCountry('ER', 'Eritrea',        '🇪🇷', 'Hawala',               'ERN'),
  PayCountry('UG', 'Uganda',         '🇺🇬', 'MTN Mobile Money',     'UGX'),
  PayCountry('KE', 'Kenya',          '🇰🇪', 'M-Pesa',               'KES'),
  PayCountry('SS', 'South Sudan',    '🇸🇸', 'MTN Mobile Money',     'SSP'),
  PayCountry('OTHER', 'Other country', '🌍', 'PayPal',              'USD'),
];

PayCountry payCountry(String? code) =>
    kPayCountries.firstWhere((c) => c.code == code, orElse: () => kPayCountries.last);

/// Guess where the customer pays from using the phone's region (e.g. nb_NO → NO).
String guessPayCountry() {
  try {
    final parts = Platform.localeName.split(RegExp('[_-]'));
    final region = parts.length > 1 ? parts.last.toUpperCase() : '';
    if (kPayCountries.any((c) => c.code == region)) return region;
  } catch (_) {}
  return 'NO';
}

class PaymentInfo {
  final String method, number, name;
  const PaymentInfo(this.method, this.number, this.name);
  bool get hasNumber => number.trim().isNotEmpty;
}

/// Default payment methods — numbers are filled in by admin (settings/payment).
const _defaultNumbers = {'NO': '+47 973 74 482'};

Future<Map<String, PaymentInfo>> loadPaymentMethods() async {
  Map<String, dynamic> stored = {};
  try {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('payment').get();
    stored = Map<String, dynamic>.from((doc.data()?['methods'] as Map?) ?? {});
  } catch (_) {}
  final out = <String, PaymentInfo>{};
  for (final c in kPayCountries) {
    final m = stored[c.code] is Map ? Map<String, dynamic>.from(stored[c.code]) : <String, dynamic>{};
    out[c.code] = PaymentInfo(
      serviceStr(m['method']).isNotEmpty ? serviceStr(m['method']) : c.method,
      serviceStr(m['number']).isNotEmpty ? serviceStr(m['number']) : (_defaultNumbers[c.code] ?? ''),
      serviceStr(m['name']).isNotEmpty ? serviceStr(m['name']) : 'Habesha Hub',
    );
  }
  return out;
}

/// Short booking reference shown on receipt and used as payment message, e.g. HH-4F7K2Q
String bookingCode(String docId) =>
    'HH-${docId.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase().padRight(6, 'X').substring(0, 6)}';

// ═══════════════════════════════════════════════════════════
// PAY-FROM PICKER  (used in the booking form)
// ═══════════════════════════════════════════════════════════
class PayFromPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const PayFromPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: kCard, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kSecondary.withOpacity(0.3))),
    child: DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: const SizedBox(),
      dropdownColor: kCard,
      iconEnabledColor: kSecondary,
      style: tsBodyLg(color: kText),
      items: kPayCountries.map((c) => DropdownMenuItem(
        value: c.code,
        child: Text('${c.flag}  ${tr(c.name)}  ·  ${c.method}', overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// MY BOOKINGS (customer)
// ═══════════════════════════════════════════════════════════
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          iconTheme: const IconThemeData(color: kSecondary),
          title: Text(tr('My bookings'), style: tsTitleMd(color: kSecondary)),
        ),
        body: user == null
            ? Center(child: Text(tr('Log in to see your bookings'), style: tsBodyLg()))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('service_bookings')
                    .where('userId', isEqualTo: user.uid).snapshots(),
                builder: (_, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('${tr('Error')}: ${snap.error}', style: tsBodySm(color: kRed)));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                  }
                  final docs = snap.data!.docs.toList()
                    ..sort((a, b) {
                      final ta = (a.data() as Map)['createdAt'];
                      final tb = (b.data() as Map)['createdAt'];
                      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                      return 0;
                    });
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_rounded, color: kTextSub, size: 56),
                      const SizedBox(height: 12),
                      Text(tr('No bookings yet'), style: tsTitleLg()),
                    ]));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final status = serviceStr(d['status']).isEmpty ? 'created' : serviceStr(d['status']);
                      final paid = d['paid'] == true;
                      return GestureDetector(
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => ReceiptScreen(bookingId: docs[i].id))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kCard, borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: statusColor(status).withOpacity(0.3))),
                          child: Row(children: [
                            Icon(status == 'confirmed' || status == 'completed'
                                ? Icons.receipt_long_rounded : Icons.schedule_rounded,
                                color: statusColor(status)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(serviceStr(d['serviceName']), style: tsTitleMd()),
                              Text('${bookingCode(docs[i].id)} · ${_dateStr(d['date'])}',
                                  style: tsBodySm(color: kTextSub)),
                            ])),
                            statusBadge(paid ? 'paid' : status),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

String _dateStr(dynamic iso) {
  final s = serviceStr(iso);
  final d = DateTime.tryParse(s);
  return d == null ? s : '${d.day}/${d.month}/${d.year}';
}

Color statusColor(String s) {
  switch (s) {
    case 'confirmed': return kGreen;
    case 'completed': return kSecondary;
    case 'paid':      return kGreen;
    case 'cancelled': return kRed;
    default:          return kTextSub;
  }
}

String statusLabel(String s) {
  switch (s) {
    case 'confirmed': return tr('Confirmed');
    case 'completed': return tr('Completed');
    case 'paid':      return tr('Paid');
    case 'cancelled': return tr('Cancelled');
    default:          return tr('Waiting for confirmation');
  }
}

Widget statusBadge(String s) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: statusColor(s).withOpacity(0.14), borderRadius: BorderRadius.circular(100)),
  child: Text(statusLabel(s), style: tsLabel(color: statusColor(s)).copyWith(fontSize: 10)),
);

// ═══════════════════════════════════════════════════════════
// RECEIPT (customer) — live, updates when admin confirms / marks paid
// ═══════════════════════════════════════════════════════════
class ReceiptScreen extends StatelessWidget {
  final String bookingId;
  const ReceiptScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          iconTheme: const IconThemeData(color: kSecondary),
          title: Text(tr('Receipt'), style: tsTitleMd(color: kSecondary)),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('service_bookings').doc(bookingId).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            }
            final d = (snap.data!.data() as Map<String, dynamic>?) ?? {};
            final status  = serviceStr(d['status']).isEmpty ? 'created' : serviceStr(d['status']);
            final paid    = d['paid'] == true;
            final code    = bookingCode(bookingId);
            final amount  = serviceStr(d['amount']);
            final cur     = serviceStr(d['currency']);
            final method  = serviceStr(d['paymentMethod']);
            final number  = serviceStr(d['paymentNumber']);
            final payName = serviceStr(d['paymentName']);
            final confirmed = status == 'confirmed' || status == 'completed';

            final receiptText = [
              'Habesha Hub — ${tr('Receipt')}',
              '${tr('Booking no.')}: $code',
              '${tr('Service')}: ${serviceStr(d['serviceName'])}',
              '${tr('Date')}: ${_dateStr(d['date'])}',
              if (amount.isNotEmpty) '${tr('Amount')}: $amount $cur',
              if (method.isNotEmpty) '${tr('Payment')}: $method${number.isNotEmpty ? ' → $number' : ''}${payName.isNotEmpty ? ' ($payName)' : ''}',
              '${tr('Reference')}: $code',
              '${tr('Status')}: ${statusLabel(paid ? 'paid' : status)}',
            ].join('\n');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ── header ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kSecondary.withOpacity(0.3))),
                  child: Column(children: [
                    Icon(paid ? Icons.verified_rounded
                        : confirmed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        color: statusColor(paid ? 'paid' : status), size: 56),
                    const SizedBox(height: 10),
                    Text(paid ? tr('Payment received — thank you!')
                        : confirmed ? tr('Your booking is confirmed!')
                        : status == 'cancelled' ? tr('This booking was cancelled')
                        : tr('Waiting for Habesha Hub to confirm'),
                        style: tsHeadlineSm(), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    statusBadge(paid ? 'paid' : status),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── details ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    _row(tr('Booking no.'), code, bold: true),
                    _row(tr('Service'), serviceStr(d['serviceName'])),
                    _row(tr('Date'), _dateStr(d['date'])),
                    if (serviceStr(d['notes']).isNotEmpty) _row(tr('Notes'), serviceStr(d['notes'])),
                    if (amount.isNotEmpty) ...[
                      const Divider(height: 24),
                      _row(tr('Amount'), '$amount $cur', bold: true, big: true),
                    ],
                  ]),
                ),

                // ── how to pay ───────────────────────────
                if (confirmed && !paid && method.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kSecondary.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kSecondary.withOpacity(0.4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.payments_rounded, color: kSecondary),
                        const SizedBox(width: 8),
                        Text(tr('How to pay'), style: tsTitleMd(color: kSecondary)),
                      ]),
                      const SizedBox(height: 12),
                      Text('${tr('Pay with')} $method', style: tsTitleLg()),
                      if (number.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _copyRow(ctx, number),
                      ],
                      if (payName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${tr('Recipient')}: $payName', style: tsBodySm()),
                      ],
                      const SizedBox(height: 10),
                      Text('${tr('Write this in the payment message')}:', style: tsBodySm()),
                      const SizedBox(height: 4),
                      _copyRow(ctx, code),
                    ]),
                  ),
                ],

                // ── review after the service is done / paid ──
                if (status == 'completed' || paid) ...[
                  const SizedBox(height: 16),
                  WriteReviewCard(bookingId: bookingId, booking: d),
                ],

                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Share.share(receiptText),
                  icon: const Icon(Icons.share_rounded, color: kSecondary),
                  label: Text(tr('Share receipt'), style: tsTitleMd(color: kSecondary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kSecondary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, bool big = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(k, style: tsBodySm(color: kTextSub))),
      Expanded(child: Text(v, textAlign: TextAlign.right,
          style: (big ? tsTitleLg() : bold ? tsTitleMd() : tsBodyLg()))),
    ]),
  );

  Widget _copyRow(BuildContext ctx, String value) => GestureDetector(
    onTap: () {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${tr('Copied')}: $value')));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Text(value, style: tsTitleMd())),
        const Icon(Icons.copy_rounded, color: kSecondary, size: 18),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// ADMIN — edit payment numbers per country (settings/payment)
// ═══════════════════════════════════════════════════════════
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});
  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _method = <String, TextEditingController>{};
  final _number = <String, TextEditingController>{};
  final _name   = <String, TextEditingController>{};
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    loadPaymentMethods().then((m) {
      for (final c in kPayCountries) {
        _method[c.code] = TextEditingController(text: m[c.code]!.method);
        _number[c.code] = TextEditingController(text: m[c.code]!.number);
        _name[c.code]   = TextEditingController(text: m[c.code]!.name);
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    for (final c in [..._method.values, ..._number.values, ..._name.values]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final methods = <String, dynamic>{};
    for (final c in kPayCountries) {
      methods[c.code] = {
        'method': _method[c.code]!.text.trim(),
        'number': _number[c.code]!.text.trim(),
        'name':   _name[c.code]!.text.trim(),
      };
    }
    await FirebaseFirestore.instance.collection('settings').doc('payment')
        .set({'methods': methods, 'updatedAt': FieldValue.serverTimestamp()});
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment settings saved')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kCard,
      iconTheme: const IconThemeData(color: kSecondary),
      title: Text('Payment methods', style: tsTitleMd(color: kSecondary)),
      actions: [
        TextButton(onPressed: _saving || _loading ? null : _save,
            child: Text('SAVE', style: tsTitleMd(color: kSecondary))),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Customers see the method for the country they pay from. '
                  'Leave the number empty if you do not accept payments from that country yet.',
                  style: tsBodySm(color: kTextSub)),
              const SizedBox(height: 16),
              ...kPayCountries.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c.flag}  ${c.name}  (${c.currency})', style: tsTitleMd()),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _tf(_method[c.code]!, 'Method')),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _tf(_number[c.code]!, 'Number / account / email')),
                  ]),
                  const SizedBox(height: 8),
                  _tf(_name[c.code]!, 'Recipient name'),
                ]),
              )),
            ],
          ),
  );

  Widget _tf(TextEditingController c, String label) => TextField(
    controller: c,
    style: tsBodyLg(color: kText),
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: kBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
