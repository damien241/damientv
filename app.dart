import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  runApp(const App());
}

class C {
  static const bg = Color(0xFF0B0F1A);
  static const card = Color(0xFF151B2B);
  static const accent = Color(0xFFE50914);
  static const gold = Color(0xFFFBBF24);
  static const muted = Color(0xFF8B96B8);
  static const green = Color(0xFF22C55E);
  static const blue = Color(0xFF3A75C4);
}

class PlaylistPreset {
  final String name, url;
  final IconData icon;
  final Color color;
  const PlaylistPreset({
    required this.name, required this.url,
    required this.icon, required this.color,
  });
}

const kPresets = [
  PlaylistPreset(name: 'France',
    url: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
    icon: Icons.flag, color: C.blue),
  PlaylistPreset(name: 'Belgique',
    url: 'https://iptv-org.github.io/iptv/countries/be.m3u',
    icon: Icons.flag_circle, color: C.gold),
  PlaylistPreset(name: 'Free-TV',
    url: 'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8',
    icon: Icons.public, color: C.green),
  PlaylistPreset(name: 'Monde',
    url: 'https://iptv-org.github.io/iptv/index.m3u',
    icon: Icons.language, color: C.accent),
  PlaylistPreset(name: 'TVradioZap',
    url: 'https://tvradiozap.eu/live/x/vlc/d/tvzeu.m3u',
    icon: Icons.live_tv, color: C.muted),
];

class Flag extends StatelessWidget {
  final double w, h;
  const Flag({super.key, this.w = 22, this.h = 14});
  @override
  Widget build(BuildContext c) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Colors.white24, width: 0.5),
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF009E60), Color(0xFF009E60),
          Color(0xFFFCD116), Color(0xFFFCD116),
          Color(0xFF3A75C4), Color(0xFF3A75C4)],
        stops: [0.0, 0.333, 0.333, 0.666, 0.666, 1.0])));
}

class Channel {
  final String name, logo, group, url;
  Channel({required this.name, this.logo = '',
    this.group = 'Général', required this.url});
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

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Damien TV 241',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.accent, secondary: C.gold)),
    home: const Home());
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _ctrl = TextEditingController(text: kPresets.first.url);
  final _searchCtrl = TextEditingController();
  List<Channel> _all = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  String _category = 'TOUTES';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() =>
      setState(() => _search = _searchCtrl.text.toLowerCase().trim()));
  }

  Future<void> _loadUrl(String url) async {
    _ctrl.text = url;
    setState(() { _all = []; _category = 'TOUTES'; });
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _all = []; });
    try {
      final res = await http.get(Uri.parse(_ctrl.text.trim()));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final ch = parseM3U(res.body);
      if (ch.isEmpty) throw Exception('Aucune chaîne');
      setState(() { _all = ch; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: C.bg,
    body: SafeArea(child: Column(children: [
      _header(),
      // Presets
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
      // URL field
      Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: _deco('URL M3U'))),
          const SizedBox(width: 6),
          ElevatedButton(onPressed: _loading ? null : _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent, foregroundColor: Colors.white),
            child: const Text('Charger', style: TextStyle(fontSize: 12))),
        ])),
      // Search
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
      // Categories
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
      // List
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.accent))
        : _error != null ? _err()
        : _list()),
      _credit(),
    ])));

  InputDecoration _deco(String h) => InputDecoration(
    hintText: h, hintStyle: const TextStyle(color: C.muted, fontSize: 11),
    filled: true, fillColor: const Color(0xFF0D1220),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF232B42))));

  Widget _header() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Damien TV 241', style: TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(width: 6), Flag(w: 18, h: 11),
        ]),
        Text('PROTOTYPE NEYLA 241', style: TextStyle(color: C.gold, fontSize: 9,
          letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      ])),
    ]));

  Widget _credit() => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flag(w: 14, h: 9), SizedBox(width: 6),
      Text('Conçu par Damien (Starly Koumba)',
        style: TextStyle(color: C.muted, fontSize: 10)),
      SizedBox(width: 6), Flag(w: 14, h: 9),
    ]));

  Widget _list() {
    if (_vis.isEmpty) return Center(child: Text(
      _all.isEmpty ? 'Choisis une playlist' : 'Aucun résultat',
      style: const TextStyle(color: C.muted)));
    return ListView(children: _grouped.entries.expand((e) => [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text('${e.key.toUpperCase()} (${e.value.length})',
          style: const TextStyle(color: C.muted, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ...e.value.map((ch) => ListTile(
        dense: true,
        leading: ch.logo.isEmpty ? _fb()
          : ClipRRect(borderRadius: BorderRadius.circular(6),
              child: Image.network(ch.logo, width: 36, height: 36,
                fit: BoxFit.contain, errorBuilder: (_, __, ___) => _fb())),
        title: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w600)),
        subtitle: Text(ch.group, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: C.muted, fontSize: 10)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => Player(title: ch.name, url: ch.url))),
      )),
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

class Player extends StatefulWidget {
  final String title, url;
  const Player({super.key, required this.title, required this.url});
  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  VideoPlayerController? _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _start();
  }

  Future<void> _start() async {
    try {
      setState(() => _error = null);
      await _ctrl?.dispose();
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _ctrl!.initialize();
      await _ctrl!.play();
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      backgroundColor: C.card,
      title: Row(children: [
        const Flag(w: 20, h: 12), const SizedBox(width: 8),
        Expanded(child: Text(widget.title,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          overflow: TextOverflow.ellipsis)),
      ]),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _start)],
    ),
    backgroundColor: Colors.black,
    body: Center(
      child: _error != null
        ? Padding(padding: const EdgeInsets.all(20),
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
              ElevatedButton.icon(onPressed: _start,
                icon: const Icon(Icons.refresh), label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: C.accent)),
            ]))
        : _ctrl != null && _ctrl!.value.isInitialized
          ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!))
          : const CircularProgressIndicator(color: C.accent),
    ));
}
