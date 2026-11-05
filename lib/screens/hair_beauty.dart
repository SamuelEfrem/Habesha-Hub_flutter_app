import 'package:flutter/material.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

// "Hair & beauty": the business category that used to be called "Barber".
// The stored category value stays 'Barber' so older app versions keep showing these places;
// only the name on screen changed. Sub-category and extras are extra fields on the business.

const kHairCategory = 'Barber';

/// key, English label, emoji
const kHairSubs = [
  ('barber', 'Barbershop', '💈'),
  ('salon', 'Hair salon', '💇‍♀️'),
  ('braiding', 'Braiding', '🪢'),
  ('makeup', 'Makeup', '💄'),
  ('nails', 'Nails', '💅'),
  ('henna', 'Henna', '🌿'),
  ('other', 'Other beauty', '✨'),
];
/// shown in Weddings & celebrations
const kHairWeddingSubs = {'makeup', 'braiding', 'henna'};
const kHairFor = [('all', 'Everyone'), ('women', 'Women'), ('men', 'Men'), ('kids', 'Kids')];

String hairSubLabel(String key) {
  for (final s in kHairSubs) {
    if (s.$1 == key) return tr(s.$2);
  }
  return '';
}

String hairSubEmoji(String key) {
  for (final s in kHairSubs) {
    if (s.$1 == key) return s.$3;
  }
  return '💇';
}

String hairForLabel(String key) {
  for (final f in kHairFor) {
    if (f.$1 == key) return tr(f.$2);
  }
  return '';
}

/// The extras for a Hair & beauty business
class HairInfo {
  String sub, forWho, priceFrom;
  bool fromHome, comesToYou;
  HairInfo({this.sub = '', this.forWho = 'all', this.priceFrom = '', this.fromHome = false, this.comesToYou = false});

  factory HairInfo.of(Business b) => HairInfo(
      sub: b.subcategory, forWho: b.forWho.isEmpty ? 'all' : b.forWho, priceFrom: b.priceFrom,
      fromHome: b.worksFromHome, comesToYou: b.comesToYou);

  Map<String, dynamic> toMap() => {
    'subcategory': sub, 'forWho': forWho, 'priceFrom': priceFrom.trim(),
    'worksFromHome': fromHome, 'comesToYou': comesToYou,
  };
}

/// Old listings without a sub-category were barbers
String hairSubOf(Business b) => b.subcategory.isEmpty ? 'barber' : b.subcategory;

/// [sub]: '' = all, 'wedding' = makeup, braiding and henna. [forWho]: '' = all
bool hairMatches(Business b, String sub, String forWho) {
  if (b.category != kHairCategory) return sub.isEmpty && forWho.isEmpty;
  final s = hairSubOf(b);
  if (sub == 'wedding' ? !kHairWeddingSubs.contains(s) : sub.isNotEmpty && s != sub) return false;
  if (forWho.isNotEmpty && b.forWho.isNotEmpty && b.forWho != 'all' && b.forWho != forWho) return false;
  return true;
}

/// Words a search can match: the sub-category in every app language
String hairSearchText(Business b) {
  if (b.category != kHairCategory) return '';
  final s = kHairSubs.where((x) => x.$1 == hairSubOf(b));
  final words = <String>[...AppTranslations.allLanguages('Hair & beauty')];
  if (s.isNotEmpty) words.addAll(AppTranslations.allLanguages(s.first.$2));
  if (hairSubOf(b) == 'barber') words.addAll(['barber', 'frisør']);
  if (hairSubOf(b) == 'salon') words.addAll(['frisør', 'hairdresser']);
  return words.join(' ').toLowerCase();
}

// ── Create / edit form ──

class HairBeautyFields extends StatelessWidget {
  final HairInfo info;
  final VoidCallback onChanged;
  final bool showError;
  const HairBeautyFields({super.key, required this.info, required this.onChanged, this.showError = false});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback tap) => ChoiceChip(
      label: Text(label), selected: on, onSelected: (_) { tap(); onChanged(); },
      selectedColor: kHabGreen, showCheckmark: false, backgroundColor: kCard,
      labelStyle: TextStyle(color: on ? Colors.white : kText, fontWeight: FontWeight.w600));
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kTintGreen.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('What do you offer?'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in kHairSubs) chip('${s.$3} ${tr(s.$2)}', info.sub == s.$1, () => info.sub = s.$1),
        ]),
        if (showError && info.sub.isEmpty) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(tr('Please choose what you offer'), style: tsBodySm(color: kRed)),
        ),
        const SizedBox(height: 14),
        Text(tr('For'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in kHairFor) chip(tr(f.$2), info.forWho == f.$1, () => info.forWho = f.$1),
        ]),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero, activeThumbColor: kHabGreen,
          value: info.fromHome,
          onChanged: (v) { info.fromHome = v; onChanged(); },
          title: Text(tr('Works from home'), style: tsBodyLg(color: kText)),
          subtitle: Text(tr('Then only the area is shown, never your address'), style: tsBodySm(color: kTextSub)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero, activeThumbColor: kHabGreen,
          value: info.comesToYou,
          onChanged: (v) { info.comesToYou = v; onChanged(); },
          title: Text(tr('Comes to you'), style: tsBodyLg(color: kText)),
          subtitle: Text(tr('You visit the customer, e.g. for weddings'), style: tsBodySm(color: kTextSub)),
        ),
        TextFormField(
          initialValue: info.priceFrom,
          maxLength: 40,
          onChanged: (v) => info.priceFrom = v,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(labelText: tr('Price from (optional)'), hintText: tr('e.g. 300 kr'), counterText: ''),
        ),
      ]),
    );
  }
}

/// Approximate spot (about 1 km) for people who work from home: never their exact home
double roughCoord(double v) => (v * 100).roundToDouble() / 100;

// ── Filters for list screens ──

class HairFilterRows extends StatelessWidget {
  final String sub, forWho;
  final ValueChanged<String> onSub, onFor;
  const HairFilterRows({super.key, required this.sub, required this.forWho, required this.onSub, required this.onFor});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback tap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap(),
          selectedColor: kHabGreen, showCheckmark: false, backgroundColor: kCard,
          labelStyle: TextStyle(color: on ? Colors.white : kText, fontWeight: FontWeight.w600, fontSize: 13)),
    );
    return Column(children: [
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
        chip(tr('All'), sub.isEmpty, () => onSub('')),
        chip('💍 ${tr('For weddings')}', sub == 'wedding', () => onSub(sub == 'wedding' ? '' : 'wedding')),
        for (final s in kHairSubs) chip('${s.$3} ${tr(s.$2)}', sub == s.$1, () => onSub(sub == s.$1 ? '' : s.$1)),
      ])),
      const SizedBox(height: 6),
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
        for (final f in kHairFor) chip(tr(f.$2), (forWho.isEmpty ? 'all' : forWho) == f.$1, () => onFor(f.$1 == 'all' ? '' : f.$1)),
      ])),
    ]);
  }
}

// ── On the business page ──

class HairInfoCard extends StatelessWidget {
  final Business business;
  const HairInfoCard({super.key, required this.business});
  @override
  Widget build(BuildContext context) {
    final b = business;
    final items = <(IconData, String)>[
      (Icons.content_cut_rounded, '${hairSubEmoji(hairSubOf(b))} ${hairSubLabel(hairSubOf(b))}'),
      if (b.forWho.isNotEmpty) (Icons.people_outline_rounded, '${tr('For')}: ${hairForLabel(b.forWho)}'),
      if (b.worksFromHome) (Icons.home_outlined, tr('Works from home')),
      if (b.comesToYou) (Icons.directions_car_outlined, tr('Comes to you')),
      if (b.priceFrom.trim().isNotEmpty) (Icons.sell_outlined, '${tr('from')} ${b.priceFrom.trim()}'),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (icon, text) in items) Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: kTintGreen, borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: kInkGreen),
          const SizedBox(width: 6),
          Text(text, style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }
}
