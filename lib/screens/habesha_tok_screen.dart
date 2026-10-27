import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../utils/theme_notifier.dart';
import '../utils/language_notifier.dart';
import 'services_screen.dart';
import '../utils/translations.dart';

// ═══════════════════════════════════════════════════════════
// HAB TOK  — TikTok-style vertical video feed
//
//  Videos hosted on Bunny.net Stream (HLS .m3u8).
//  Each provider can have MANY videos (`sampleVideoUrls` array).
//
//   • Swipe UP / DOWN    → next / previous provider
//   • Swipe LEFT / RIGHT → next / previous video of same provider
//   • When a video ends (and the user was watching), the feed
//     moves on to that provider's next video automatically.
//
//  URL is NEVER shown to users — played inside video_player.
//  Nothing autoplays when opened — user taps play.
// ═══════════════════════════════════════════════════════════

class HabeshaTokScreen extends StatefulWidget {
  /// false when another bottom tab is selected → videos pause
  final bool visible;
  const HabeshaTokScreen({super.key, this.visible = true});

  @override
  State<HabeshaTokScreen> createState() => _HabeshaTokScreenState();
}

class _HabeshaTokScreenState extends State<HabeshaTokScreen> with WidgetsBindingObserver {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _appActive = true;   // false when the app goes to the background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _appActive && mounted) setState(() => _appActive = active);
  }
  final Set<String> _hidden = {};   // providers whose videos all failed to load

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (_, __) => Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('anonymous_services')
              .where('available', isEqualTo: true)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            }

            final docs = snap.data!.docs.where((d) =>
                !_hidden.contains(d.id) &&
                serviceVideos(d.data() as Map<String, dynamic>).isNotEmpty).toList();

            if (docs.isEmpty) return _emptyState();

            return PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              allowImplicitScrolling: true,   // preload the next provider's video
              itemCount: docs.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final id = docs[i].id;
                return _ProviderTok(
                  key: ValueKey(id),
                  serviceId: id,
                  data: data,
                  isActive: widget.visible && _appActive && _currentPage == i,
                  onAllFailed: () { if (mounted) setState(() => _hidden.add(id)); },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('🎬', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Text(
          tr('Provider videos will appear here.\nStay tuned!'),
          style: tsBodySm(color: kOnSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  ));
}

// ═══════════════════════════════════════════════════════════
// PROVIDER TOK — one provider, horizontal pager of its videos
// ═══════════════════════════════════════════════════════════
class _ProviderTok extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> data;
  final bool isActive;
  final VoidCallback onAllFailed;
  const _ProviderTok({super.key, required this.serviceId, required this.data, required this.isActive, required this.onAllFailed});

  @override
  State<_ProviderTok> createState() => _ProviderTokState();
}

class _ProviderTokState extends State<_ProviderTok> {
  final PageController _subCtrl = PageController();
  int  _sub = 0;
  bool _continuePlaying = false; // true after a video finished while watching

  final Set<String> _bad = {};   // videos that could not be played (e.g. deleted in Bunny)
  List<String> get _videos => serviceVideos(widget.data).where((u) => !_bad.contains(u)).toList();

  void _onVideoError(String url) {
    if (!mounted || _bad.contains(url)) return;
    setState(() {
      _bad.add(url);
      if (_sub >= _videos.length && _sub > 0) _sub = _videos.length - 1;
    });
    if (_videos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onAllFailed());
    } else if (_subCtrl.hasClients) {
      _subCtrl.jumpToPage(_sub);
    }
  }

  @override
  void didUpdateWidget(_ProviderTok old) {
    super.didUpdateWidget(old);
    // Leaving this provider → stop "continue" mode
    if (old.isActive && !widget.isActive) _continuePlaying = false;
  }

  @override
  void dispose() {
    _subCtrl.dispose();
    super.dispose();
  }

  void _onVideoFinished() {
    final count = _videos.length;
    if (count <= 1 || !_subCtrl.hasClients) return;
    final next = (_sub + 1) % count;
    setState(() => _continuePlaying = true);
    _subCtrl.animateToPage(next,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    if (videos.isEmpty) return const ColoredBox(color: Colors.black);
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _subCtrl,
        allowImplicitScrolling: true,         // preload the next video
        itemCount: videos.length,
        onPageChanged: (i) => setState(() => _sub = i),
        itemBuilder: (_, i) => _TokCard(
          key: ValueKey('$i-${videos[i]}'),
          serviceId: widget.serviceId,
          data: widget.data,
          videoUrl: videos[i],
          videoCount: videos.length,
          isActive: widget.isActive && _sub == i,
          autoStart: _continuePlaying,
          onFinished: _onVideoFinished,
          onError: () => _onVideoError(videos[i]),
        ),
      ),

      // ── VIDEO INDICATOR (bars + 1/3) — only if >1 video ──
      if (videos.length > 1)
        Positioned(
          top: 0, left: 0, right: 0,
          child: IgnorePointer(
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 64, 0),
              child: Row(children: [
                Expanded(child: Row(
                  children: List.generate(videos.length, (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == _sub ? kSecondary : Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                )),
                const SizedBox(width: 8),
                Text('${_sub + 1}/${videos.length}',
                    style: tsBodySm(color: Colors.white70).copyWith(fontSize: 11)),
              ]),
            )),
          ),
        ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// TOK CARD — a single video
// ═══════════════════════════════════════════════════════════
class _TokCard extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> data;
  final String videoUrl;
  final int videoCount;
  final bool isActive;
  final bool autoStart;
  final VoidCallback onFinished;
  final VoidCallback onError;
  const _TokCard({
    super.key,
    required this.serviceId,
    required this.data,
    required this.videoUrl,
    required this.videoCount,
    required this.isActive,
    required this.autoStart,
    required this.onFinished,
    required this.onError,
  });
  @override
  State<_TokCard> createState() => _TokCardState();
}

class _TokCardState extends State<_TokCard> {
  VideoPlayerController? _vpc;
  ChewieController?      _chc;
  bool _loading = true;
  bool _error   = false;
  bool _liked   = false;
  int  _likes   = 0;
  bool _wasPlaying = false;
  bool _finishedFired = false;

  bool   get _multi    => widget.videoCount > 1;
  String get _name     => (serviceText(widget.data, 'publicName').isEmpty ? 'Provider' : serviceText(widget.data, 'publicName'));
  String get _desc     => serviceText(widget.data, 'description');
  String get _catKey   => serviceStr(widget.data['category']);
  String get _country  => serviceStr(widget.data['country']);
  String get _city     => serviceStr(widget.data['city']);
  List<String> get _images => serviceImages(widget.data);

  ServiceCategory get _cat =>
      kServiceCategories.firstWhere((c) => c.key == _catKey, orElse: () => kServiceCategories.first);
  ServiceCountry get _cty =>
      kServiceCountries.firstWhere((c) => c.code == _country, orElse: () => kServiceCountries.first);

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadLikes();
  }

  // ── Likes, saved in Firestore per video ───────────────────
  //   video_likes/{videoKey}            { count }   ← kept up to date by a Cloud Function
  //   video_likes/{videoKey}/users/{uid}            ← one doc per user who liked
  String get _videoKey {
    final m = RegExp(r'/([0-9a-fA-F-]{20,})/playlist\.m3u8$').firstMatch(widget.videoUrl);
    if (m != null) return m.group(1)!;                                   // Bunny video id
    final k = widget.videoUrl.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    return k.length > 140 ? k.substring(k.length - 140) : k;
  }
  DocumentReference<Map<String, dynamic>> get _likeDoc =>
      FirebaseFirestore.instance.collection('video_likes').doc(_videoKey);

  Future<void> _loadLikes() async {
    try {
      final doc = await _likeDoc.get();
      final c = doc.data()?['count'];
      final uid = FirebaseAuth.instance.currentUser?.uid;
      bool liked = false;
      if (uid != null) liked = (await _likeDoc.collection('users').doc(uid).get()).exists;
      if (mounted) setState(() { _likes = c is int && c > 0 ? c : 0; _liked = liked; });
    } catch (_) {}
  }

  static int _bump(int v, int d) => v + d < 0 ? 0 : v + d;

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final nowLiked = !_liked;
    setState(() { _liked = nowLiked; _likes = _bump(_likes, nowLiked ? 1 : -1); });
    final mine = _likeDoc.collection('users').doc(uid);
    try {
      if (nowLiked) {
        await mine.set({'serviceId': widget.serviceId, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await mine.delete();
      }
    } catch (_) {
      if (mounted) setState(() { _liked = !nowLiked; _likes = _bump(_likes, nowLiked ? -1 : 1); });
    }
  }

  Future<void> _initPlayer() async {
    try {
      _vpc = await openVideo(widget.videoUrl);
      // Single video → loop. Several videos → move on to the next one.
      await _vpc!.setLooping(!_multi);
      _vpc!.addListener(_onTick);

      _chc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: false,
        looping: !_multi,
        showControls: false,
        aspectRatio: _vpc!.value.aspectRatio,
        allowFullScreen: false,
        allowPlaybackSpeedChanging: false,
        showOptions: false,
        // black behind the video — the provider photo looked odd above/below wide videos
        placeholder: const ColoredBox(color: Colors.black),
      );

      if (mounted) setState(() => _loading = false);
      // Auto-continue only when the user was already watching the previous video
      if (mounted && widget.isActive && widget.autoStart) _vpc!.play();
    } catch (e, st) {
      debugPrint('🔴 Hab Tok video error: $e');
      debugPrint('$st');
      if (mounted) setState(() { _loading = false; _error = true; });
      widget.onError();   // let the feed skip this video
    }
  }

  void _onTick() {
    final v = _vpc?.value;
    if (v == null || !mounted) return;
    if (v.isPlaying != _wasPlaying) {
      _wasPlaying = v.isPlaying;
      setState(() {});
    }
    // Detect end of video (only when several videos)
    if (_multi && widget.isActive && !_finishedFired && v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 300) && !v.isPlaying) {
      _finishedFired = true;
      widget.onFinished();
    }
  }

  @override
  void didUpdateWidget(_TokCard old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      if (!widget.isActive) {
        _vpc?.pause();
      } else {
        _finishedFired = false;
        if (widget.autoStart && _vpc != null && _vpc!.value.isInitialized) {
          _vpc!.seekTo(Duration.zero);
          _vpc!.play();
        }
      }
    }
  }

  @override
  void dispose() {
    _vpc?.removeListener(_onTick);
    _chc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  Widget _bgWidget() {
    // While the video loads: its small Bunny thumbnail + spinner (fast),
    // instead of a large provider photo.
    final thumb = videoThumb(widget.videoUrl);
    if (thumb != null) {
      return Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Colors.black),
        CachedNetworkImage(imageUrl: thumb, fit: BoxFit.contain,
            errorWidget: (_, __, ___) => _fallbackBg()),
        const Center(child: SizedBox(width: 36, height: 36,
            child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))),
      ]);
    }
    if (_images.isNotEmpty) {
      return CachedNetworkImage(imageUrl: _images.first, fit: BoxFit.cover, memCacheWidth: 1080,
          errorWidget: (_, __, ___) => _fallbackBg());
    }
    return _fallbackBg();
  }

  Widget _fallbackBg() => Container(
    color: const Color(0xFF0A0800),
    child: Center(child: Text(_cat.emoji, style: const TextStyle(fontSize: 100))),
  );

  void _togglePlay() {
    if (_vpc == null) return;
    if (_vpc!.value.isPlaying) {
      _vpc!.pause();
    } else {
      // Restart if at the end
      if (_vpc!.value.position >= _vpc!.value.duration) _vpc!.seekTo(Duration.zero);
      _finishedFired = false;
      _vpc!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loading && !_error && _vpc != null;
    final playing = ready && _vpc!.value.isPlaying;

    return Stack(fit: StackFit.expand, children: [

      // ── VIDEO ─────────────────────────────────────────────
      if (_loading)
        _bgWidget()
      else if (_error || _chc == null)
        _errorLayer()
      else
        ColoredBox(color: Colors.black, child: Chewie(controller: _chc!)),

      // ── GRADIENT ──────────────────────────────────────────
      const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
              stops: [0, 0.25, 0.55, 1.0],
            ),
          ),
        ),
      ),

      // ── TAP ANYWHERE TO PLAY/PAUSE (under the buttons) ────
      Positioned.fill(child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlay,
        child: const SizedBox.expand(),
      )),

      // ── PLAY KNAPP I SENTRUM (vises når pauset) ──────────
      if (ready && !playing)
        Center(
          child: GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
            ),
          ),
        ),

      // ── TOP RIGHT PLAY/PAUSE ──────────────────────────────
      if (ready)
        Positioned(
          top: 0, right: 0,
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 16, 0),
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 22,
                ),
              ),
            ),
          )),
        ),

      // ── BOTTOM INFO ───────────────────────────────────────
      Positioned(
        left: 0, right: 68, bottom: 0,
        child: IgnorePointer(
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_cat.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(child: Text(
                  '${_cty.flag}  $_city${_city.isNotEmpty ? ", " : ""}${tr(_cty.name)}',
                  style: tsBodySm(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
              const SizedBox(height: 6),
              Text(_name,
                  style: tsTitleLg(color: Colors.white)
                      .copyWith(shadows: [const Shadow(blurRadius: 10, color: Colors.black87)])),
              const SizedBox(height: 4),
              if (_desc.isNotEmpty)
                Text(_desc, style: tsBodySm(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (_vpc != null) ...[
                const SizedBox(height: 12),
                _ProgressBar(controller: _vpc!),
              ],
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 18),
                const SizedBox(width: 4),
                Text(tr('Swipe'), style: tsBodySm(color: Colors.white38).copyWith(fontSize: 11)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 18),
                if (_multi) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.swipe_rounded, color: Colors.white38, size: 16),
                  const SizedBox(width: 4),
                  Text(tr('More videos'), style: tsBodySm(color: Colors.white38).copyWith(fontSize: 11)),
                ],
              ]),
            ]),
          )),
        ),
      ),

      // ── RIGHT SIDE CONTROLS ───────────────────────────────
      Positioned(
        right: 12, bottom: 80,
        child: SafeArea(child: Column(children: [
          _sideBtn(
            icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _liked ? kRed : Colors.white,
            label: _likes > 0 ? '$_likes' : '',
            onTap: _toggleLike,
          ),
          const SizedBox(height: 22),
          Column(children: [
            ProviderAvatar(data: widget.data, size: 50),
            const SizedBox(height: 4),
            Text(tr(_cat.label).split(' ').first,
                style: tsLabel(color: Colors.white70).copyWith(fontSize: 9)),
          ]),
        ])),
      ),
    ]);
  }

  Widget _errorLayer() => Stack(fit: StackFit.expand, children: [
    _bgWidget(),
    Container(color: Colors.black54),
    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
      const SizedBox(height: 8),
      Text(tr('Could not load video'), style: tsBodySm(color: Colors.white54)),
    ])),
  ]);

  Widget _sideBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Icon(icon, color: color, size: 32,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black87)]),
      if (label.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(label, style: tsLabel(color: Colors.white70).copyWith(fontSize: 10)),
      ],
    ]),
  );
}

// ═══════════════════════════════════════════════════════════
// THIN PROGRESS BAR  — time elapsed, no scrubbing
// ═══════════════════════════════════════════════════════════
class _ProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  const _ProgressBar({required this.controller});
  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  @override
  void initState()  { super.initState(); widget.controller.addListener(_rebuild); }
  void _rebuild()   { if (mounted) setState(() {}); }
  @override
  void dispose()    { widget.controller.removeListener(_rebuild); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dur = widget.controller.value.duration;
    final pos = widget.controller.value.position;
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 2,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(kSecondary),
      ),
    );
  }
}
