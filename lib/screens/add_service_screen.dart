import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/theme_notifier.dart';
import '../utils/language_notifier.dart';
import 'services_screen.dart';
import 'payment.dart';
import 'provider_extras.dart';

// ═══════════════════════════════════════════════════════════
// ADD / EDIT SERVICE PROVIDER  (only admin adds — anonymous)
// ═══════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════
// READABLE DOCUMENT IDs  —  e.g. "Cameraman 1 (Hane Photografi)"
//   public name + real name (realName is admin-only info)
// ═══════════════════════════════════════════════════════════
String serviceDocName(String publicName, String realName) {
  String clean(String v) => v.replaceAll('/', '-').replaceAll(RegExp(r'\s+'), ' ').trim();
  final p = clean(publicName).isEmpty ? 'Provider' : clean(publicName);
  final r = clean(realName);
  return r.isEmpty ? p : '$p ($r)';
}

/// Finds a free ID in anonymous_services (adds " 2", " 3" … if taken).
Future<String> freeServiceId(String publicName, String realName, {String? ignoreId}) async {
  final col  = FirebaseFirestore.instance.collection('anonymous_services');
  final base = serviceDocName(publicName, realName);
  var id = base;
  var i = 2;
  while (id != ignoreId && (await col.doc(id).get()).exists) {
    id = '$base $i';
    i++;
  }
  return id;
}

/// Moves a provider document to a new ID (copy → fix bookings → delete old).
Future<void> moveServiceDoc(String oldId, String newId, Map<String, dynamic> data) async {
  if (oldId == newId) return;
  final db  = FirebaseFirestore.instance;
  final col = db.collection('anonymous_services');
  final batch = db.batch();
  batch.set(col.doc(newId), data);
  final bookings = await db.collection('service_bookings')
      .where('serviceId', isEqualTo: oldId).get();
  for (final b in bookings.docs) {
    batch.update(b.reference, {'serviceId': newId});
  }
  // move reviews too (sub-collection)
  final reviews = await col.doc(oldId).collection('reviews').get();
  for (final r in reviews.docs) {
    batch.set(col.doc(newId).collection('reviews').doc(r.id), r.data());
    batch.delete(r.reference);
  }
  batch.delete(col.doc(oldId));
  await batch.commit();
}

class AddServiceScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;
  const AddServiceScreen({super.key, this.docId, this.existing});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _db = FirebaseFirestore.instance;
  final _nameCtrl   = TextEditingController();
  final _realCtrl   = TextEditingController(); // real name — admin only
  // translations shown when the user picks Tigrinya / Amharic
  final _nameTiCtrl = TextEditingController();
  final _descTiCtrl = TextEditingController();
  final _nameAmCtrl = TextEditingController();
  final _descAmCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _cityCtrl   = TextEditingController();
  final _imgsCtrl   = TextEditingController(); // one image URL per line
  final _videoCtrl  = TextEditingController(); // one video URL per line

  String _country  = 'UG';
  String _category = 'photographer';
  bool   _available = true;
  bool   _saving    = false;
  bool   _done      = false;
  String? _uploadStatus;           // e.g. "Uploading 2 / 5…"

  // ── current image URLs from the text field ────────────────
  List<String> get _imageList => _imgsCtrl.text
      .split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  void _setImageList(List<String> list) => setState(() => _imgsCtrl.text = list.join('\n'));

  // ── pick several photos from phone and upload to Firebase Storage ──
  Future<void> _uploadPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600);
    if (picked.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final folder = serviceDocName(_nameCtrl.text, _realCtrl.text)
        .toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final urls = <String>[];
    try {
      for (var i = 0; i < picked.length; i++) {
        setState(() => _uploadStatus = 'Uploading ${i + 1} / ${picked.length}…');
        final file = File(picked[i].path);
        final name = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final meta = SettableMetadata(contentType: 'image/jpeg');
        Reference ref = FirebaseStorage.instance.ref('services/$folder/$name');
        try {
          await ref.putFile(file, meta);
        } on FirebaseException catch (e) {
          // Storage rules may only allow the marketplace path → fall back to it
          if (e.code != 'unauthorized') rethrow;
          ref = FirebaseStorage.instance.ref('marketplace/$uid/$name');
          await ref.putFile(file, meta);
        }
        urls.add(await ref.getDownloadURL());
      }
      _setImageList([..._imageList, ...urls]);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${urls.length} photos added — remember to SAVE')));
    } catch (e) {
      if (urls.isNotEmpty) _setImageList([..._imageList, ...urls]);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')));
    }
    if (mounted) setState(() => _uploadStatus = null);
  }

  @override
  void initState() {
    super.initState();
    _imgsCtrl.addListener(() { if (mounted) setState(() {}); });
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text  = serviceStr(e['publicName']);
      _realCtrl.text  = serviceStr(e['realName']);
      final t9n = e['translations'];
      String tv(String lang, String f) =>
          (t9n is Map && t9n[lang] is Map) ? serviceStr((t9n[lang] as Map)[f]) : '';
      _nameTiCtrl.text = tv('Tigrinya', 'publicName');
      _descTiCtrl.text = tv('Tigrinya', 'description');
      _nameAmCtrl.text = tv('Amharic', 'publicName');
      _descAmCtrl.text = tv('Amharic', 'description');
      _descCtrl.text  = serviceStr(e['description']);
      _priceCtrl.text = serviceStr(e['price']);
      _cityCtrl.text  = serviceStr(e['city']);
      _videoCtrl.text = serviceVideos(Map<String, dynamic>.from(e)).join('\n');
      _country        = serviceStr(e['country']).isEmpty ? 'UG' : serviceStr(e['country']);
      _category       = serviceStr(e['category']).isEmpty ? 'photographer' : serviceStr(e['category']);
      _available      = e['available'] is bool ? e['available'] as bool : true;
      _imgsCtrl.text  = serviceImages(Map<String, dynamic>.from(e)).join('\n');
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);

    List<String> lines(TextEditingController c) => c.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final images = lines(_imgsCtrl);
    final videos = lines(_videoCtrl);

    final data = <String, dynamic>{
      'publicName':     _nameCtrl.text.trim(),
      'realName':       _realCtrl.text.trim(),
      'translations': {
        'Tigrinya': {'publicName': _nameTiCtrl.text.trim(), 'description': _descTiCtrl.text.trim()},
        'Amharic':  {'publicName': _nameAmCtrl.text.trim(), 'description': _descAmCtrl.text.trim()},
      },
      'description':    _descCtrl.text.trim(),
      'price':          _priceCtrl.text.trim(),
      'city':           _cityCtrl.text.trim(),
      'country':        _country,
      'category':       _category,
      'available':      _available,
      'sampleImages':    images,
      'sampleVideoUrls': videos,
      'updatedAt':      FieldValue.serverTimestamp(),
    };

    try {
      final col = _db.collection('anonymous_services');
      final wantedId = await freeServiceId(
          _nameCtrl.text.trim(), _realCtrl.text.trim(), ignoreId: widget.docId);
      if (widget.docId != null) {
        // remove the old single-string field so only the array is used
        data['sampleVideoUrl'] = FieldValue.delete();
        await col.doc(widget.docId).update(data);
        // rename the Firestore document if name / real name changed
        if (wantedId != widget.docId) {
          final fresh = (await col.doc(widget.docId).get()).data() ?? {};
          await moveServiceDoc(widget.docId!, wantedId, fresh);
        }
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.doc(wantedId).set(data);
      }
      setState(() { _saving = false; _done = true; });
    } catch (err) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (_, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          iconTheme: IconThemeData(color: kSecondary),
          title: Text(
            widget.docId != null ? 'Edit Provider' : 'Add Provider',
            style: tsTitleMd(color: kSecondary),
          ),
          actions: [
            if (!_done)
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text('SAVE', style: tsTitleMd(color: kSecondary)),
              ),
          ],
        ),
        body: _done ? _successWidget() : _form(),
      ),
    );
  }

  Widget _successWidget() => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen.withOpacity(0.15)),
        child: Icon(Icons.check_circle_rounded, color: kGreen, size: 48),
      ),
      const SizedBox(height: 24),
      Text(
        widget.docId != null ? 'Provider Updated!' : 'Provider Added!',
        style: tsHeadlineSm(color: kText),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text('It is now live in the services section.',
          style: tsBodySm(color: kTextSub), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () {
          if (widget.docId != null) {
            Navigator.pop(context);
          } else {
            setState(() { _done = false; _nameCtrl.clear(); _realCtrl.clear(); _nameTiCtrl.clear(); _descTiCtrl.clear(); _nameAmCtrl.clear(); _descAmCtrl.clear(); _descCtrl.clear();
              _priceCtrl.clear(); _cityCtrl.clear(); _imgsCtrl.clear();
              _videoCtrl.clear();
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
        child: Text(
          widget.docId != null ? 'Back' : 'Add Another',
          style: tsTitleMd(color: kOnAccent),
        ),
      ),
    ]),
  ));

  Widget _form() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── COUNTRY ──────────────────────────────────────────
      _sectionLabel('COUNTRY'),
      _dropdown<String>(
        value: _country,
        items: kServiceCountries.map((c) => DropdownMenuItem(
          value: c.code,
          child: Text('${c.flag} ${c.name}'),
        )).toList(),
        onChanged: (v) => setState(() => _country = v!),
      ),
      const SizedBox(height: 16),

      // ── CATEGORY ─────────────────────────────────────────
      _sectionLabel('CATEGORY'),
      _dropdown<String>(
        value: _category,
        items: kServiceCategories.map((c) => DropdownMenuItem(
          value: c.key,
          child: Text('${c.emoji} ${c.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _category = v!),
      ),
      const SizedBox(height: 16),

      // ── PUBLIC NAME ──────────────────────────────────────
      _sectionLabel('PUBLIC NAME  (no real name — keep anonymous!)'),
      _field(_nameCtrl, hint: 'e.g.  Photographer UG · Cameraman 1'),
      const SizedBox(height: 16),

      // ── REAL NAME (admin only) ───────────────────────────
      _sectionLabel('REAL NAME  (only for you — used as Firestore ID)'),
      _field(_realCtrl, hint: 'e.g.  Hane Photografi'),
      const SizedBox(height: 16),

      // ── CITY ─────────────────────────────────────────────
      _sectionLabel('CITY'),
      _field(_cityCtrl, hint: 'e.g. Kampala'),
      const SizedBox(height: 16),

      // ── PRICE ────────────────────────────────────────────
      _sectionLabel('PRICE'),
      _field(_priceCtrl, hint: 'e.g. \$150 / day'),
      const SizedBox(height: 16),

      // ── DESCRIPTION ──────────────────────────────────────
      _sectionLabel('DESCRIPTION'),
      _field(_descCtrl,
          hint: 'What they offer, years of experience, style, equipment…',
          maxLines: 5),
      const SizedBox(height: 16),

      // ── TRANSLATIONS ─────────────────────────────────────
      _sectionLabel('TIGRINYA  (shown when the user picks ትግርኛ)'),
      _field(_nameTiCtrl, hint: 'Name in Tigrinya, e.g. ካሜራማን 1'),
      const SizedBox(height: 8),
      _field(_descTiCtrl, hint: 'Description in Tigrinya…', maxLines: 4),
      const SizedBox(height: 16),
      _sectionLabel('AMHARIC  (shown when the user picks አማርኛ)'),
      _field(_nameAmCtrl, hint: 'Name in Amharic, e.g. ካሜራማን 1'),
      const SizedBox(height: 8),
      _field(_descAmCtrl, hint: 'Description in Amharic…', maxLines: 4),
      const SizedBox(height: 16),

      // ── IMAGES ───────────────────────────────────────────
      _sectionLabel('SAMPLE IMAGES'),
      // upload button
      SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _uploadStatus != null ? null : _uploadPhotos,
          icon: _uploadStatus != null
              ? SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kSecondary))
              : Icon(Icons.add_photo_alternate_rounded, color: kSecondary),
          label: Text(_uploadStatus ?? 'Upload photos from phone',
              style: tsTitleMd(color: kSecondary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: kSecondary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      // preview with remove buttons
      if (_imageList.isNotEmpty) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _imageList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final url = _imageList[i];
              return Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(url, width: 84, height: 84, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 84, height: 84, color: kCardHigh,
                      child: Icon(Icons.broken_image_rounded, color: kTextSub))),
                ),
                Positioned(top: 2, right: 2,
                  child: GestureDetector(
                    onTap: () => _setImageList(List.of(_imageList)..removeAt(i)),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  )),
              ]);
            },
          ),
        ),
      ],
      const SizedBox(height: 8),
      Text('…or paste image URLs, one per line:', style: tsBodySm(color: kTextSub)),
      const SizedBox(height: 6),
      _field(_imgsCtrl, hint: 'https://firebasestorage…/img1.jpg\nhttps://firebasestorage…/img2.jpg', maxLines: 4),
      const SizedBox(height: 16),

      // ── VIDEO ────────────────────────────────────────────
      _sectionLabel('VIDEO URLS  (Bunny.net .m3u8 — one per line)'),
      _field(_videoCtrl, hint: 'https://vz-xxxx.b-cdn.net/…/playlist.m3u8\nhttps://vz-xxxx.b-cdn.net/…/playlist.m3u8', maxLines: 4),
      const SizedBox(height: 20),

      // ── AVAILABLE toggle ─────────────────────────────────
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Available for booking', style: tsTitleMd(color: kText)),
            Text('Turn off to hide from customers', style: tsBodySm(color: kTextSub)),
          ])),
          Switch(
            value: _available,
            onChanged: (v) => setState(() => _available = v),
            activeColor: kSecondary,
          ),
        ]),
      ),
      const SizedBox(height: 28),

      // ── SAVE BUTTON ──────────────────────────────────────
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kOnAccent))
              : Icon(Icons.save_rounded, color: kOnAccent),
          label: Text(_saving ? 'Saving…' : 'Save Provider',
              style: tsTitleMd(color: kOnAccent)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: tsLabel(color: kTextSub)),
  );

  Widget _field(TextEditingController ctrl, {String hint = '', int maxLines = 1}) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: tsBodyLg(color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tsBodySm(color: kTextSub),
        filled: true,
        fillColor: kCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kSecondary.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kSecondary.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kSecondary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      ),
    child: DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      underline: const SizedBox(),
      dropdownColor: kCard,
      style: tsBodyLg(color: kText),
      iconEnabledColor: kSecondary,
    ),
  );

  @override
  void dispose() {
    _nameCtrl.dispose(); _realCtrl.dispose(); _nameTiCtrl.dispose(); _descTiCtrl.dispose(); _nameAmCtrl.dispose(); _descAmCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _cityCtrl.dispose(); _imgsCtrl.dispose(); _videoCtrl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// MANAGE SERVICES LIST  — used inside admin tab
// ═══════════════════════════════════════════════════════════
class ManageServicesTab extends StatefulWidget {
  const ManageServicesTab({super.key});
  @override
  State<ManageServicesTab> createState() => _ManageServicesTabState();
}

class _ManageServicesTabState extends State<ManageServicesTab> {
  String _filterCountry = 'ALL';
  String _filterCat     = 'ALL';
  bool   _renaming      = false;

  void _confirmRename(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: kCard,
      title: Text('Readable IDs', style: tsTitleMd(color: kSecondary)),
      content: Text(
        'All providers get a readable ID in Firestore: public name + real name, '
        'e.g. "Cameraman 1 (Hane Photografi)". Bookings are updated. Continue?',
        style: tsBodySm(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: tsBodySm(color: kTextSub))),
        TextButton(
          onPressed: () { Navigator.pop(ctx); _renameAll(); },
          child: Text('Rename', style: tsBodySm(color: kSecondary)),
        ),
      ],
    ));
  }

  Future<void> _renameAll() async {
    setState(() => _renaming = true);
    final col = FirebaseFirestore.instance.collection('anonymous_services');
    int changed = 0;
    try {
      final snap = await col.get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final pub  = serviceStr(data['publicName']);
        final real = serviceStr(data['realName']);
        final want = serviceDocName(pub, real);
        if (doc.id == want || doc.id.startsWith('$want ')) continue;
        final newId = await freeServiceId(pub, real, ignoreId: doc.id);
        if (newId == doc.id) continue;
        await moveServiceDoc(doc.id, newId, data);
        changed++;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Done — $changed providers renamed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _renaming = false);
  }


  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── filter row ──────────────────────────────────────
      Container(
        color: kCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Expanded(child: _dd<String>(
            value: _filterCountry,
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('All countries')),
              ...kServiceCountries.map((c) => DropdownMenuItem(
                  value: c.code, child: Text('${c.flag} ${c.name}'))),
            ],
            onChanged: (v) => setState(() => _filterCountry = v!),
          )),
          const SizedBox(width: 8),
          Expanded(child: _dd<String>(
            value: _filterCat,
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('All categories')),
              ...kServiceCategories.map((c) => DropdownMenuItem(
                  value: c.key, child: Text('${c.emoji} ${c.label}'))),
            ],
            onChanged: (v) => setState(() => _filterCat = v!),
          )),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Give readable IDs',
            icon: _renaming
                ? SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kSecondary))
                : Icon(Icons.drive_file_rename_outline_rounded, color: kSecondary),
            onPressed: _renaming ? null : () => _confirmRename(context),
          ),
        ]),
      ),

      // ── list ────────────────────────────────────────────
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anonymous_services')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));

          var docs = snap.data!.docs;
          if (_filterCountry != 'ALL') docs = docs.where((d) => (d.data() as Map)['country'] == _filterCountry).toList();
          if (_filterCat     != 'ALL') docs = docs.where((d) => (d.data() as Map)['category'] == _filterCat).toList();

          if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.work_outline_rounded, color: kTextSub, size: 56),
            const SizedBox(height: 16),
            Text('No providers', style: tsTitleLg(color: kText)),
            const SizedBox(height: 8),
            Text('Tap + in the top-right to add one', style: tsBodySm(color: kTextSub)),
          ]));

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final cat  = kServiceCategories.firstWhere((c) => c.key == data['category'], orElse: () => kServiceCategories.first);
              final cty  = kServiceCountries.firstWhere((c) => c.code == data['country'],  orElse: () => kServiceCountries.first);
              final avail = data['available'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (avail ? kSecondary : kTextSub).withOpacity(0.15)),
                ),
                child: Row(children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(serviceStr(data['publicName']), style: tsTitleMd(color: kText)),
                    Text('${cty.flag} ${cty.name} · ${cat.label}', style: tsBodySm(color: kTextSub)),
                    Text('ID: ${doc.id}', style: tsBodySm(color: kTextSub).copyWith(fontSize: 10)),
                    if (serviceStr(data['price']).isNotEmpty)
                      Text(serviceStr(data['price']), style: tsBodySm(color: kSecondary)),
                  ])),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    // available badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (avail ? kGreen : kRed).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(avail ? 'Live' : 'Hidden',
                          style: tsLabel(color: avail ? kGreen : kRed).copyWith(fontSize: 10)),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddServiceScreen(docId: doc.id, existing: data))),
                        child: Icon(Icons.edit_rounded, color: kSecondary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _delete(context, doc.id, data['publicName'] ?? '?'),
                        child: Icon(Icons.delete_rounded, color: kRed, size: 20),
                      ),
                    ]),
                  ]),
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _dd<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(8),
        ),
      child: DropdownButton<T>(
        value: value, items: items, onChanged: onChanged,
        isExpanded: true, underline: const SizedBox(),
        dropdownColor: kCard, style: tsBodySm(color: kText),
        iconEnabledColor: kSecondary,
      ),
    );

  void _delete(BuildContext ctx, String docId, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: kCard,
      title: Text('Delete Provider', style: tsTitleMd(color: kSecondary)),
      content: Text('Delete "$name"? Cannot be undone.', style: tsBodySm(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: tsBodySm(color: kTextSub))),
        TextButton(
          onPressed: () {
            FirebaseFirestore.instance.collection('anonymous_services').doc(docId).delete();
            Navigator.pop(ctx);
          },
          child: Text('Delete', style: tsBodySm(color: kRed)),
        ),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// MANAGE BOOKINGS TAB  — used inside admin tab
// ═══════════════════════════════════════════════════════════
class ManageBookingsTab extends StatefulWidget {
  const ManageBookingsTab({super.key});
  @override
  State<ManageBookingsTab> createState() => _ManageBookingsTabState();
}

class _ManageBookingsTabState extends State<ManageBookingsTab> {
  String _filter = 'created'; // created | confirmed | completed | cancelled

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── status filter chips ──────────────────────────────
      Container(
        color: kCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('created',   'New',       kSecondary),
            _chip('confirmed', 'Confirmed', kGreen),
            _chip('completed', 'Done',      kTextSub),
            _chip('cancelled', 'Cancelled', kRed),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Statistics',
              icon: Icon(Icons.bar_chart_rounded, color: kSecondary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminStatsScreen())),
            ),
            IconButton(
              tooltip: 'Payment methods',
              icon: Icon(Icons.payments_rounded, color: kSecondary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PaymentSettingsScreen())),
            ),
          ]),
        ),
      ),

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_bookings')
            .where('status', isEqualTo: _filter)
            .snapshots(),   // no orderBy → no composite index needed; sorted below
        builder: (_, snap) {
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: ${snap.error}', style: tsBodySm(color: kRed), textAlign: TextAlign.center),
            ));
          }
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ta = (a.data() as Map)['createdAt'];
              final tb = (b.data() as Map)['createdAt'];
              if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
              return 0;
            });
          if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_rounded, color: kTextSub, size: 48),
            const SizedBox(height: 16),
            Text('No $_filter bookings', style: tsTitleLg(color: kText)),
          ]));

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'created';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _statusColor(status).withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(data['serviceName'] ?? '(no name)', style: tsTitleMd(color: kText))),
                    _badge(status),
                  ]),
                  const SizedBox(height: 6),
                  Text('👤 ${serviceStr(data['userEmail'])}', style: tsBodySm(color: kTextSub)),
                  if (serviceStr(data['whatsapp']).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        final num = serviceStr(data['whatsapp']).replaceAll(RegExp(r'[^0-9]'), '');
                        final code = serviceStr(data['bookingCode']).isNotEmpty ? data['bookingCode'] : bookingCode(doc.id);
                        final msg = 'Hi! This is Habesha Hub about your booking $code – ${serviceStr(data['serviceName'])}.';
                        launchUrl(Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(msg)}'),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100)),
                        child: Text('💬 WhatsApp ${serviceStr(data['whatsapp'])}',
                            style: tsBodySm(color: const Color(0xFF25D366))),
                      ),
                    ),
                  ],
                  if (serviceStr(data['date']) != '') ...[
                    const SizedBox(height: 2),
                    Text('📅 ${data['date'].toString().substring(0, 10)}', style: tsBodySm(color: kTextSub)),
                  ],
                  if (serviceStr(data['notes']).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('📝 ${data['notes']}', style: tsBodySm(color: kTextSub)),
                  ],
                  Text('🔖 ${serviceStr(data['bookingCode']).isNotEmpty ? data['bookingCode'] : bookingCode(doc.id)}'
                      '   ${payCountry(serviceStr(data['payCountry'])).flag} pays from ${payCountry(serviceStr(data['payCountry'])).name}',
                      style: tsBodySm(color: kTextSub)),
                  if (serviceStr(data['amount']).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('💰 ${data['amount']} ${serviceStr(data['currency'])}'
                        '  ·  ${serviceStr(data['paymentMethod'])}'
                        '${data['paid'] == true ? '  ·  ✅ PAID' : '  ·  ⏳ unpaid'}',
                        style: tsTitleMd(color: kSecondary)),
                  ],

                  // ── action buttons ───────────────────────
                  if (status == 'created') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _actionBtn('✅ Confirm', kGreen, Colors.white,
                          () => _confirmDialog(context, doc.id, data))),
                      const SizedBox(width: 10),
                      Expanded(child: _actionBtn('❌ Cancel', kRed.withOpacity(0.12), kRed,
                          () => _setStatus(doc.id, 'cancelled'))),
                    ]),
                  ],
                  if (status == 'confirmed' || status == 'completed') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      if (data['paid'] != true)
                        Expanded(child: _actionBtn('💵 Mark as Paid', kGreen, Colors.white,
                            () => FirebaseFirestore.instance.collection('service_bookings').doc(doc.id).update({
                                  'paid': true, 'paidAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp()}))),
                      if (data['paid'] != true && status == 'confirmed') const SizedBox(width: 10),
                      if (status == 'confirmed')
                        Expanded(child: _actionBtn('✓ Completed', kSecondary, kOnAccent,
                            () => _setStatus(doc.id, 'completed'))),
                    ]),
                  ],
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _chip(String value, String label, Color color) => GestureDetector(
    onTap: () => setState(() => _filter = value),
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _filter == value ? color.withOpacity(0.2) : kBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(_filter == value ? 0.6 : 0.2)),
      ),
      child: Text(label, style: tsLabel(color: color).copyWith(fontSize: 11)),
    ),
  );

  Widget _badge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: _statusColor(status).withOpacity(0.12),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(status.toUpperCase(), style: tsLabel(color: _statusColor(status)).copyWith(fontSize: 9)),
  );

  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: tsTitleMd(color: fg).copyWith(fontSize: 13))),
      ),
    );

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return kGreen;
      case 'completed': return kSecondary;
      case 'cancelled': return kRed;
      default:          return kTextSub;
    }
  }

  /// Confirm: admin sets the amount; the payment method for the customer's
  /// country is copied onto the booking so the receipt never changes later.
  Future<void> _confirmDialog(BuildContext ctx, String docId, Map<String, dynamic> data) async {
    final pc = payCountry(serviceStr(data['payCountry']));
    final methods = await loadPaymentMethods();
    final pm = methods[pc.code]!;
    final amountCtrl = TextEditingController(text: serviceStr(data['amount']));
    final curCtrl    = TextEditingController(text: serviceStr(data['currency']).isNotEmpty
        ? serviceStr(data['currency']) : pc.currency);
    if (!ctx.mounted) return;
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: kCard,
      title: Text('Confirm booking', style: tsTitleMd(color: kSecondary)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${pc.flag} Customer pays from ${pc.name}', style: tsBodySm(color: kText)),
        Text('Method: ${pm.method}${pm.hasNumber ? ' → ${pm.number}' : '  (no number set!)'}',
            style: tsBodySm(color: pm.hasNumber ? kTextSub : kRed)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(flex: 2, child: TextField(controller: amountCtrl, keyboardType: TextInputType.number,
            style: tsBodyLg(color: kText), decoration: const InputDecoration(labelText: 'Amount'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: curCtrl, style: tsBodyLg(color: kText),
            decoration: const InputDecoration(labelText: 'Currency'))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: tsBodySm(color: kTextSub))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirm', style: tsTitleMd(color: kGreen))),
      ],
    ));
    if (ok != true) return;
    await FirebaseFirestore.instance.collection('service_bookings').doc(docId).update({
      'status':        'confirmed',
      'amount':        amountCtrl.text.trim(),
      'currency':      curCtrl.text.trim().toUpperCase(),
      'paymentMethod': pm.method,
      'paymentNumber': pm.number,
      'paymentName':   pm.name,
      'bookingCode':   serviceStr(data['bookingCode']).isNotEmpty ? data['bookingCode'] : bookingCode(docId),
      'paid':          false,
      'confirmedAt':   FieldValue.serverTimestamp(),
      'updatedAt':     FieldValue.serverTimestamp(),
    });
    // Cloud Function 'notifyCustomer' sends the push + the customer sees the receipt in the app
  }

  void _setStatus(String docId, String status) {
    FirebaseFirestore.instance.collection('service_bookings').doc(docId).update({
      'status':    status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
