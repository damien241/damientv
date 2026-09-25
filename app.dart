import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await WakelockPlus.enable();
  runApp(const DamienApp());
}

const kTestBanner = 'ca-app-pub-3940256099942544/6300978111';
const kTestInterstitial = 'ca-app-pub-3940256099942544/1033173712';

class C {
  static const bg = Color(0xFF0B0F1A);
  static const card = Color(0xFF151B2B);
  static const accent = Color(0xFFE50914);
  static const gold = Color(0xFFFBBF24);
  static const muted = Color(0xFF8B96B8);
  static const green = Color(0xFF22C55E);
  static const blue = Color(0xFF3A75C4);
}

/* ===== PLAYLISTS PRÉ-CONFIGURÉES ===== */
class PlaylistPreset {
  final String name, url;
  final IconData icon;
  final Color color;
  const PlaylistPreset({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}

const List<PlaylistPreset> kPresets = [
  PlaylistPreset(
    name: 'France',
    url: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
    icon: Icons.flag,
    color: C.blue,
  ),
  PlaylistPreset(
    name: 'Belgique',
    url: 'https://iptv-org.github.io/iptv/countries/be.m3u',
    icon: Icons.flag_circle,
    color: C.gold,
  ),
  PlaylistPreset(
    name: 'Free-TV',
    url: 'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8',
    icon: Icons.public,
    color: C.green,
  ),
  PlaylistPreset(
    name: 'Monde',
    url: 'https://iptv-org.github.io/iptv/index.m3u',
    icon: Icons.language,
    color: C.accent,
  ),
  PlaylistPreset(
    name: 'TVradioZap',
    url: 'https://tvradiozap.eu/live/x/vlc/d/tvzeu.m3u',
    icon: Icons.live_tv,
    color: C.muted,
  ),
];

/* ===== ABONNEMENTS IPTV (gratuit + payant, 100% légaux) ===== */
class Subscription {
  final String name, description, url, badge;
  final Color color;
  final IconData icon;
  const Subscription({
    required this.name,
    required this.description,
    required this.url,
    required this.badge,
    required this.color,
    required this.icon,
  });
}

const List<Subscription> kFreeSubscriptions = [
  Subscription(
    name: 'Molotov',
    description: 'Plus de 40 chaînes françaises en direct et replay.',
    url: 'https://www.molotov.tv',
    badge: 'GRATUIT',
    color: C.green,
    icon: Icons.live_tv,
  ),
  Subscription(
    name: 'France.tv',
    description: 'Direct et replay des chaînes France Télévisions.',
    url: 'https://www.france.tv',
    badge: 'GRATUIT',
    color: C.blue,
    icon: Icons.play_circle,
  ),
  Subscription(
    name: 'Arte.tv',
    description: 'Documentaires, films et concerts en accès libre.',
    url: 'https://www.arte.tv/fr/',
    badge: 'GRATUIT',
    color: Color(0xFFFF6600),
    icon: Icons.movie,
  ),
  Subscription(
    name: 'TF1+',
    description: 'Direct TF1/TMC/TFX + replays et programmes exclusifs.',
    url: 'https://www.tf1.fr',
    badge: 'GRATUIT',
    color: Color(0xFF0046BE),
    icon: Icons.play_arrow,
  ),
  Subscription(
    name: 'Pluto TV',
    description: 'Chaînes thématiques + films et séries en libre accès.',
    url: 'https://pluto.tv',
    badge: 'GRATUIT',
    color: Color(0xFFFFCC00),
    icon: Icons.tv,
  ),
  Subscription(
    name: 'Rakuten TV',
    description: 'Films gratuits et chaînes TV sans inscription.',
    url: 'https://www.rakuten.tv',
    badge: 'GRATUIT',
    color: Color(0xFFBF0000),
    icon: Icons.movie_filter,
  ),
];

const List<Subscription> kPaidSubscriptions = [
  Subscription(
    name: 'Molotov Extra',
    description: 'Enregistrement cloud + 100 chaînes supplémentaires.',
    url: 'https://www.molotov.tv',
    badge: '6,99 €/mois',
    color: C.green,
    icon: Icons.live_tv,
  ),
  Subscription(
    name: 'myCANAL',
    description: 'Canal+ en direct, sport, cinéma et séries.',
    url: 'https://www.canalplus.com',
    badge: 'À partir de 22,99 €',
    color: Color(0xFF000000),
    icon: Icons.star,
  ),
  Subscription(
    name: 'Netflix',
    description: 'Films, séries, documentaires en illimité.',
    url: 'https://www.netflix.com',
    badge: 'À partir de 7,99 €',
    color: Color(0xFFE50914),
    icon: Icons.movie,
  ),
  Subscription(
    name: 'Disney+',
    description: 'Disney, Pixar, Marvel, Star Wars, National Geographic.',
    url: 'https://www.disneyplus.com',
    badge: 'À partir de 5,99 €',
    color: Color(0xFF113CCF),
    icon: Icons.auto_awesome,
  ),
  Subscription(
    name: 'Prime Video',
    description: 'Films et séries Amazon Originals + catalogue.',
    url: 'https://www.primevideo.com',
    badge: 'Inclus avec Prime',
    color: Color(0xFF00A8E1),
    icon: Icons.play_circle,
  ),
];

class Flag extends StatelessWidget {
  final double w, h;
  const Flag({super.key, this.w = 22, this.h = 14});
  @override
  Widget build(BuildContext context) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Colors.white24, width: 0.5),
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF009E60), Color(0xFF009E60),
          Color(0xFFFCD116), Color(0xFFFCD116),
          Color(0xFF3A75C4), Color(0xFF3A75C4)],
        stops: [0.0, 0.333, 0.333, 0.666, 0.666, 1.0])),
  );
}

/* ===== MODEL ===== */
class Channel {
  final String name, logo, group, url;
  Channel({required this.name, this.logo = '',
    this.group = 'Général', required this.url});
  Map<String, dynamic> toJson() =>
    {'name': name, 'logo': logo, 'group': group, 'url': url};
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    name: j['name'] ?? '', logo: j['logo'] ?? '',
    group: j['group'] ?? 'Général', url: j['url'] ?? '');
}

List<Channel> parseM3U(String c) {
  final list = <Channel>[];
  Map<String, String>? a; String? n;
  for (var raw in c.split(RegExp(r'\r?\n'))) {
    final l = raw.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('#EXTINF:')) {
      final info = l.substring(8);
      a = {};
      for (final m in RegExp(r'([\w-]+)="([^"]*)"').allMatches(info))
        a[m.group(1)!] = m.group(2)!;
      final p = info.split(',');
      n = p.length > 1 ? p.last.trim() : 'Sans nom';
    } else if (!l.startsWith('#') && a != null) {
      list.add(Channel(name: n ?? 'Sans nom', logo: a['tvg-logo'] ?? '',
        group: a['group-title'] ?? 'Général', url: l));
      a = null; n = null;
    }
  }
  return list;
}

/* ===== STORAGE ===== */
class Storage {
  static const _f = 'dtv_favs', _u = 'dtv_url';
  static Future<List<Channel>> loadFavs() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(_f);
    if (r == null) return [];
    return (jsonDecode(r) as List).map((e) => Channel.fromJson(e)).toList();
  }
  static Future<void> saveFavs(List<Channel> f) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_f, jsonEncode(f.map((c) => c.toJson()).toList()));
  }
  static Future<String?> loadUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_u);
  }
  static Future<void> saveUrl(String u) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_u, u);
  }
}

/* ===== VLC ===== */
Future<void> openInVlc(String url) async {
  try {
    final iu = 'intent://${url.replaceFirst(RegExp(r'^https?://'), '')}'
        '#Intent;scheme=${url.startsWith('https') ? 'https' : 'http'};'
        'package=org.videolan.vlc;type=video/*;end';
    final u = Uri.parse(iu);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  try {
    final u = Uri.parse('vlc://$url');
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/* ===== BANNIÈRE ===== */
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: kTestBanner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) { ad.dispose(); _ad = null; }),
    )..load();
  }
  @override
  void dispose() { _ad?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox(height: 50);
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!));
  }
}

/* ===== INTERSTITIEL ===== */
class AdHelper {
  static InterstitialAd? _interstitial;
  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: kTestInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null),
    );
  }
  static void showInterstitial({VoidCallback? onDone}) {
    if (_interstitial != null) {
      _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose(); _interstitial = null;
          loadInterstitial(); onDone?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose(); _interstitial = null; onDone?.call();
        });
      _interstitial!.show();
    } else { onDone?.call(); loadInterstitial(); }
  }
}

/* ===== APP ===== */
class DamienApp extends StatelessWidget {
  const DamienApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Damien TV 241',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.accent, secondary: C.gold)),
    home: const RootScreen());
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _idx = 0;
  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitial();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: const [
      M3UScreen(), DirectScreen(), SubscriptionScreen(), FavoritesScreen(),
    ]),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx,
      onTap: (i) => setState(() => _idx = i),
      backgroundColor: C.card,
      selectedItemColor: C.accent,
      unselectedItemColor: C.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'M3U'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Direct'),
        BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Abonnement'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
      ]));
}

class AppHeader extends StatelessWidget {
  final String subtitle;
  const AppHeader({super.key, this.subtitle = 'PROTOTYPE NEYLA 241'});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8,
      bottom: 8, left: 12, right: 12),
    color: C.bg,
    child: Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.accent, Color(0xFFFF2D3F)]),
            borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('D',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 16)))),
        const Positioned(right: -3, bottom: -3, child: Flag(w: 14, h: 9)),
      ]),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Damien TV 241', style: TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6), const Flag(w: 18, h: 11),
        ]),
        Text(subtitle, style: const TextStyle(color: C.gold, fontSize: 9,
          letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      ])),
    ]));
}

class CreditBar extends StatelessWidget {
  const CreditBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flag(w: 14, h: 9), SizedBox(width: 6),
      Text('Conçu par Damien (Starly Koumba)',
        style: TextStyle(color: C.muted, fontSize: 10)),
      SizedBox(width: 6), Flag(w: 14, h: 9),
    ]));
}

/* ===== M3U ===== */
class M3UScreen extends StatefulWidget {
  const M3UScreen({super.key});
  @override
  State<M3UScreen> createState() => _M3UScreenState();
}

class _M3UScreenState extends State<M3UScreen> {
  final _urlCtrl = TextEditingController(text: kPresets.first.url);
  final _searchCtrl = TextEditingController();
  List<Channel> _all = [];
  List<Channel> _favs = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  String _category = 'TOUTES';

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(() =>
      setState(() => _search = _searchCtrl.text.toLowerCase().trim()));
  }

  Future<void> _init() async {
    _favs = await Storage.loadFavs();
    final u = await Storage.loadUrl();
    if (u != null) _urlCtrl.text = u;
    if (mounted) setState(() {});
    if (_urlCtrl.text.isNotEmpty) await _load();
  }

  Future<void> _loadUrl(String url) async {
    _urlCtrl.text = url;
    setState(() { _all = []; _category = 'TOUTES'; });
    await _load();
  }

  Future<void> _load() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _error = null; _all = []; });
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final ch = parseM3U(res.body);
      if (ch.isEmpty) throw Exception('Aucune chaîne');
      await Storage.saveUrl(url);
      setState(() { _all = ch; _loading = false; });
      _snack('✅ ${ch.length} chaînes chargées');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
      _snack('❌ Erreur : $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: C.card));
  }

  List<String> get _cats {
    final s = <String>{};
    for (final c in _all) s.add(c.group);
    return ['TOUTES', ...s.toList()..sort()];
  }

  List<Channel> get _vis {
    var l = _all;
    if (_category != 'TOUTES') l = l.where((c) => c.group == _category).toList();
    if (_search.isNotEmpty) l = l.where((c) =>
      c.name.toLowerCase().contains(_search) ||
      c.group.toLowerCase().contains(_search)).toList();
    return l;
  }

  Map<String, List<Channel>> get _grouped {
    final m = <String, List<Channel>>{};
    for (final c in _vis) m.putIfAbsent(c.group, () => []).add(c);
    return m;
  }

  bool _isFav(Channel c) => _favs.any((f) => f.url == c.url);
  Future<void> _toggleFav(Channel c) async {
    setState(() {
      final i = _favs.indexWhere((f) => f.url == c.url);
      if (i >= 0) _favs.removeAt(i); else _favs.add(c);
    });
    await Storage.saveFavs(_favs);
  }

  void _openChannel(Channel c) {
    AdHelper.showInterstitial(onDone: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(title: c.name, url: c.url)));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • IPTV'),
      SizedBox(height: 44,
        child: ListView.builder(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: kPresets.length,
          itemBuilder: (_, i) {
            final p = kPresets[i];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: _loading ? null : () => _loadUrl(p.url),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: C.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.color.withOpacity(0.5))),
                  child: Row(children: [
                    Icon(p.icon, color: p.color, size: 14),
                    const SizedBox(width: 6),
                    Text(p.name, style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w600)),
                  ])));
          })),
      Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Row(children: [
          Expanded(child: TextField(controller: _urlCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: _deco('URL M3U personnalisée'))),
          const SizedBox(width: 6),
          ElevatedButton(onPressed: _loading ? null : _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent, foregroundColor: Colors.white),
            child: const Text('Charger', style: TextStyle(fontSize: 12))),
        ])),
      Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: TextField(controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Rechercher...', hintStyle: const TextStyle(color: C.muted),
            prefixIcon: const Icon(Icons.search, color: C.muted, size: 18),
            filled: true, fillColor: const Color(0xFF0D1220),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF232B42)))))),
      if (_all.isNotEmpty) SizedBox(height: 36,
        child: ListView.builder(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final cat = _cats[i];
            final a = _category == cat;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(onTap: () => setState(() => _category = cat),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: a ? C.accent : C.card,
                    borderRadius: BorderRadius.circular(20)),
                  child: Center(child: Text(cat,
                    style: TextStyle(color: a ? Colors.white : C.muted,
                      fontSize: 11, fontWeight: FontWeight.w600))))));
          })),
      const SizedBox(height: 6),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.accent))
        : _error != null ? _err() : _list()),
      const BannerAdWidget(),
      const CreditBar(),
    ]));

  InputDecoration _deco(String h) => InputDecoration(
    hintText: h, hintStyle: const TextStyle(color: C.muted, fontSize: 11),
    filled: true, fillColor: const Color(0xFF0D1220),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF232B42))));

  Widget _list() {
    if (_vis.isEmpty) return Center(child: Text(
      _all.isEmpty ? 'Choisis une playlist ci-dessus' : 'Aucun résultat',
      style: const TextStyle(color: C.muted)));
    return ListView(children: _grouped.entries.expand((e) => [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text('${e.key.toUpperCase()} (${e.value.length})',
          style: const TextStyle(color: C.muted, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ...e.value.map((c) {
        final fav = _isFav(c);
        return ListTile(
          dense: true,
          leading: c.logo.isEmpty ? _fb()
            : ClipRRect(borderRadius: BorderRadius.circular(6),
                child: Image.network(c.logo, width: 36, height: 36,
                  fit: BoxFit.contain, errorBuilder: (_, __, ___) => _fb())),
          title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w600)),
          subtitle: Text(c.group, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: C.muted, fontSize: 10)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: Icon(fav ? Icons.star : Icons.star_border,
              color: fav ? C.gold : C.muted, size: 20),
              onPressed: () => _toggleFav(c)),
            IconButton(icon: const Icon(Icons.play_circle_outline, color: C.accent, size: 22),
              tooltip: 'VLC', onPressed: () => openInVlc(c.url)),
          ]),
          onTap: () => _openChannel(c),
        );
      }),
    ]).toList());
  }

  Widget _fb() => Container(width: 36, height: 36,
    decoration: BoxDecoration(color: const Color(0xFF0D1220),
      borderRadius: BorderRadius.circular(6)),
    child: const Icon(Icons.tv, color: C.muted, size: 16));

  Widget _err() => Center(child: Padding(padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: C.accent, size: 44),
      const SizedBox(height: 10),
      const Text('Erreur', style: TextStyle(color: Colors.white, fontSize: 15)),
      const SizedBox(height: 6),
      Text(_error ?? '', textAlign: TextAlign.center,
        style: const TextStyle(color: C.muted, fontSize: 12)),
      const SizedBox(height: 14),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(backgroundColor: C.accent)),
    ])));
}

/* ===== DIRECT ===== */
class DirectScreen extends StatefulWidget {
  const DirectScreen({super.key});
  @override
  State<DirectScreen> createState() => _DirectScreenState();
}

class _DirectScreenState extends State<DirectScreen> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • DIRECT'),
      Expanded(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.link, color: C.accent, size: 60),
          const SizedBox(height: 16),
          const Text('Lien direct', style: TextStyle(color: Colors.white,
            fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Colle ton lien m3u8, rtsp, rtmp, mp4...',
            style: TextStyle(color: C.muted, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://exemple.com/stream.m3u8',
              hintStyle: const TextStyle(color: C.muted, fontSize: 12),
              filled: true, fillColor: const Color(0xFF0D1220),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF232B42))))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () {
              final u = _ctrl.text.trim();
              if (u.isEmpty) return;
              AdHelper.showInterstitial(onDone: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PlayerScreen(title: 'Flux direct', url: u)));
              });
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lire dans l\'app', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: C.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () {
              final u = _ctrl.text.trim();
              if (u.isEmpty) return;
              openInVlc(u);
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Ouvrir dans VLC', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: C.accent,
              side: const BorderSide(color: C.accent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14)))),
        ]))),
      const BannerAdWidget(),
      const CreditBar(),
    ]));
}

/* ===== ABONNEMENT (Gratuit + Payant) ===== */
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • ABONNEMENT'),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        // Bannière
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [C.accent.withOpacity(0.9), C.gold.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Flag(w: 22, h: 14), SizedBox(width: 8),
              Text('STREAMING & IPTV', style: TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
            const SizedBox(height: 8),
            const Text('Tous les services légaux — gratuit et payant',
              style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(4)),
              child: const Text('100% LÉGAL',
                style: TextStyle(color: Colors.black, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1))),
          ])),
        const SizedBox(height: 20),

        // SECTION GRATUIT
        Row(children: [
          Container(width: 4, height: 20, color: C.green),
          const SizedBox(width: 8),
          const Text('🆓 GRATUIT', style: TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        ...kFreeSubscriptions.map((s) => _subCard(context, s)),
        const SizedBox(height: 20),

        // SECTION PAYANT
        Row(children: [
          Container(width: 4, height: 20, color: C.gold),
          const SizedBox(width: 8),
          const Text('💰 PAYANT', style: TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        ...kPaidSubscriptions.map((s) => _subCard(context, s)),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💳 Paiement sécurisé', style: TextStyle(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Mobile Money • Carte bancaire • PayPal',
              style: TextStyle(color: C.muted, fontSize: 11)),
          ])),
        const SizedBox(height: 20),
        const CreditBar(),
      ])),
      const BannerAdWidget(),
    ]));

  Widget _subCard(BuildContext context, Subscription s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: C.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: s.color.withOpacity(0.5), width: 1.5)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openExternal(s.url),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: s.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, color: s.color, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(s.name, style: const TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(s.description, style: const TextStyle(color: C.muted,
              fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: s.color,
                borderRadius: BorderRadius.circular(4)),
              child: Text(s.badge, style: const TextStyle(
                color: Colors.white, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 0.5))),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
          ]),
        ]))));
}

/* ===== FAVORIS ===== */
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Channel> _favs = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final f = await Storage.loadFavs();
    if (mounted) setState(() => _favs = f);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • FAVORIS'),
      Expanded(child: _favs.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite, color: C.muted, size: 60),
            SizedBox(height: 12),
            Text('Aucun favori', style: TextStyle(color: C.muted, fontSize: 14)),
            SizedBox(height: 6),
            Text('Ajoute tes chaînes avec l\'étoile ⭐',
              style: TextStyle(color: C.muted, fontSize: 11)),
          ]))
        : ListView.builder(itemCount: _favs.length, itemBuilder: (_, i) {
            final c = _favs[i];
            return ListTile(
              leading: c.logo.isEmpty
                ? const Icon(Icons.tv, color: C.muted)
                : Image.network(c.logo, width: 36, height: 36,
                    errorBuilder: (_, __, ___) =>
                      const Icon(Icons.tv, color: C.muted)),
              title: Text(c.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(c.group,
                style: const TextStyle(color: C.muted, fontSize: 11)),
              trailing: IconButton(icon: const Icon(Icons.delete, color: C.muted),
                onPressed: () async {
                  setState(() => _favs.removeAt(i));
                  await Storage.saveFavs(_favs);
                }),
              onTap: () => AdHelper.showInterstitial(onDone: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PlayerScreen(title: c.name, url: c.url)));
              }),
            );
          })),
      const BannerAdWidget(),
      const CreditBar(),
    ]));
}

/* ===== PLAYER (sans pub) ===== */
class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  const PlayerScreen({super.key, required this.title, required this.url});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _loading = true;
  String? _error;
  bool _controlsVisible = true;
  bool _fullscreen = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _start();
  }

  Future<void> _start() async {
    try {
      setState(() { _loading = true; _error = null; });
      await _ctrl?.dispose();
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _ctrl!.initialize();
      await _ctrl!.setPlaybackSpeed(_speed);
      await _ctrl!.play();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  Future<void> _seek(int s) async {
    if (_ctrl == null) return;
    final pos = await _ctrl!.position;
    final np = pos + Duration(seconds: s);
    await _ctrl!.seekTo(np.isNegative ? Duration.zero : np);
  }

  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    setState(() => _speed = speeds[(idx + 1) % speeds.length]);
    _ctrl?.setPlaybackSpeed(_speed);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: () => setState(() => _controlsVisible = !_controlsVisible),
      child: Stack(children: [
        Center(child: _ctrl != null && _ctrl!.value.isInitialized
          ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!))
          : const SizedBox.shrink()),
        if (_controlsVisible) Positioned(top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8, right: 8, bottom: 8),
            decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent])),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
              const Flag(w: 20, h: 12), const SizedBox(width: 8),
              Expanded(child: Text(widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.speed, color: Colors.white),
                tooltip: '${_speed}x', onPressed: _cycleSpeed),
              IconButton(icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                tooltip: 'VLC', onPressed: () => openInVlc(widget.url)),
              IconButton(icon: Icon(_fullscreen
                ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                onPressed: _toggleFullscreen),
            ]))),
        if (_controlsVisible && _ctrl != null &&
            _ctrl!.value.isInitialized && _ctrl!.value.duration.inSeconds > 0)
          Positioned(bottom: 100, left: 12, right: 12,
            child: VideoProgressIndicator(_ctrl!, allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: C.accent, bufferedColor: Colors.white30,
                backgroundColor: Colors.white12))),
        if (_controlsVisible) Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent])),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                onPressed: () => _seek(-10)),
              IconButton(iconSize: 54,
                icon: Icon(_ctrl?.value.isPlaying == true
                  ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white),
                onPressed: () {
                  if (_ctrl == null) return;
                  setState(() => _ctrl!.value.isPlaying
                    ? _ctrl!.pause() : _ctrl!.play());
                }),
              IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                onPressed: () => _seek(10)),
            ]))),
        if (_loading) const Center(child: CircularProgressIndicator(color: C.accent)),
        if (_error != null) Center(child: Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.accent)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: C.accent, size: 44),
            const SizedBox(height: 12),
            const Text('Lecture impossible',
              style: TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 11)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: _start,
                icon: const Icon(Icons.refresh), label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: C.accent)),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () => openInVlc(widget.url),
                icon: const Icon(Icons.play_circle_outline), label: const Text('VLC'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
            ]),
          ]))),
      ])));
}
