import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DamienTvApp());
}

class DamienTvApp extends StatelessWidget {
  const DamienTvApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Damien TV 241',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE50914), secondary: Color(0xFFFBBF24)),
    ),
    home: const HomeScreen(),
  );
}

class GabonFlag extends StatelessWidget {
  final double w, h;
  const GabonFlag({super.key, this.w = 22, this.h = 14});
  @override
  Widget build(BuildContext context) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Colors.white24, width: 0.5),
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Color(0xFF009E60), Color(0xFF009E60),
          Color(0xFFFCD116), Color(0xFFFCD116),
          Color(0xFF3A75C4), Color(0xFF3A75C4),
        ],
        stops: [0.0, 0.333, 0.333, 0.666, 0.666, 1.0]),
    ),
  );
}

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
  Map<String, String>? a;
  String? n;
  for (var raw in c.split(RegExp(r'\r?\n'))) {
    final l = raw.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('#EXTINF:')) {
      final info = l.substring(8);
      a = {};
      for (final m in RegExp(r'([\w-]+)="([^"]*)"').allMatches(info)) {
        a[m.group(1)!] = m.group(2)!;
      }
      final p = info.split(',');
      n = p.length > 1 ? p.last.trim() : 'Sans nom';
    } else if (!l.startsWith('#') && a != null) {
      list.add(Channel(name: n ?? 'Sans nom',
        logo: a['tvg-logo'] ?? '',
        group: a['group-title'] ?? 'Général', url: l));
      a = null; n = null;
    }
  }
  return list;
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlCtrl = TextEditingController(
    text: 'https://tvradiozap.eu/live/x/vlc/d/tvzeu.m3u');
  final _directCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<Channel> _all = [], _favs = [];
  bool _loading = false;
  String? _error;
  int _tab = 0;
  String _search = '';

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

  Future<void> _load() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final ch = parseM3U(res.body);
      if (ch.isEmpty) throw Exception('Aucune chaîne');
      await Storage.saveUrl(url);
      setState(() { _all = ch; _loading = false; });
      _snack('OK : ${ch.length} chaînes chargées');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
      _snack('Erreur : $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFF1B2338)));
  }

  List<Channel> get _visible {
    List<Channel> base;
    if (_tab == 0) base = _all;
    else if (_tab == 1) base = _all.where((c) =>
      c.url.startsWith('rtsp') || c.url.startsWith('rtmp') ||
      c.url.contains('m3u8') || c.url.endsWith('.ts')).toList();
    else if (_tab == 2) base = _all.where((c) {
      final g = c.group.toLowerCase();
      return g.contains('vod') || g.contains('film') || g.contains('movie') ||
        g.contains('cinema') || g.contains('série') || g.contains('serie');
    }).toList();
    else base = _favs;
    if (_search.isEmpty) return base;
    return base.where((c) => c.name.toLowerCase().contains(_search) ||
      c.group.toLowerCase().contains(_search)).toList();
  }

  Map<String, List<Channel>> get _grouped {
    final m = <String, List<Channel>>{};
    for (final c in _visible) m.putIfAbsent(c.group, () => []).add(c);
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

  void _openPlayer(Channel c) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(channel: c)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFFF2D3F)]),
              borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('D',
              style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 16)))),
          const Positioned(right: -3, bottom: -3, child: GabonFlag(w: 14, h: 9)),
        ]),
        const SizedBox(width: 10),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Damien TV 241',
              style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.bold)),
            SizedBox(width: 6), GabonFlag(w: 18, h: 11),
          ]),
          Text('PROTOTYPE NEYLA 241',
            style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9,
              letterSpacing: 0.8, fontWeight: FontWeight.w600)),
        ])),
      ]),
    ),
    body: Column(children: [
      _banner(),
      _tabs(),
      if (_tab == 0) _urlRow(),
      if (_tab == 1) _directRow(),
      if (_tab != 1) _searchRow(),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
        : _error != null ? _errorView() : _list()),
      _creditBar(),
    ]),
  );

  Widget _banner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [
      Color(0xFF009E60), Color(0xFFFCD116), Color(0xFF3A75C4)])),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      GabonFlag(w: 16, h: 10), SizedBox(width: 8),
      Text('PROTOTYPE NEYLA 241',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,
          fontSize: 11, letterSpacing: 2)),
      SizedBox(width: 8), GabonFlag(w: 16, h: 10),
    ]),
  );

  Widget _tabs() => Container(
    color: const Color(0xFF111827),
    child: Row(children: [
      _tabBtn('M3U', 0),
      _tabBtn('Direct', 1),
      _tabBtn('VOD', 2),
      _tabBtn('Favoris', 3),
    ]),
  );

  Widget _tabBtn(String label, int i) {
    final active = _tab == i;
    return Expanded(child: InkWell(
      onTap: () => setState(() => _tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(
          color: active ? const Color(0xFFE50914) : Colors.transparent,
          width: 2))),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF8B96B8),
            fontSize: 11, fontWeight: FontWeight.w600)))));
  }

  Widget _urlRow() => Container(
    color: const Color(0xFF111827),
    padding: const EdgeInsets.all(8),
    child: Row(children: [
      Expanded(child: TextField(controller: _urlCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: _deco('URL M3U / M3U8 / VLC'))),
      const SizedBox(width: 6),
      ElevatedButton(onPressed: _loading ? null : _load,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white),
        child: const Text('Charger', style: TextStyle(fontSize: 12))),
    ]),
  );

  Widget _directRow() => Container(
    color: const Color(0xFF111827),
    padding: const EdgeInsets.all(8),
    child: Column(children: [
      TextField(controller: _directCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: _deco('Lien direct : m3u8, rtsp, rtmp, mp4...')),
      const SizedBox(height: 6),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () {
          final url = _directCtrl.text.trim();
          if (url.isEmpty) { _snack('Entre une URL'); return; }
          _openPlayer(Channel(name: 'Flux direct', url: url, group: 'Direct'));
        },
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Lire le lien', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white))),
    ]),
  );

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8B96B8), fontSize: 11),
    filled: true, fillColor: const Color(0xFF0D1220),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF232B42))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF232B42))),
  );

  Widget _searchRow() => Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(controller: _searchCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Rechercher une chaîne...',
        hintStyle: const TextStyle(color: Color(0xFF8B96B8)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF8B96B8), size: 18),
        filled: true, fillColor: const Color(0xFF0D1220),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF232B42))))),
  );

  Widget _list() {
    if (_visible.isEmpty) return Center(child: Text(
      _tab == 3 ? 'Aucun favori' : 'Aucune chaîne',
      style: const TextStyle(color: Color(0xFF8B96B8))));
    return ListView(children: _grouped.entries.expand((e) => [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text('${e.key.toUpperCase()} (${e.value.length})',
          style: const TextStyle(color: Color(0xFF8B96B8), fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ...e.value.map(_tile),
    ]).toList());
  }

  Widget _tile(Channel c) {
    final fav = _isFav(c);
    return ListTile(
      dense: true,
      leading: c.logo.isEmpty
        ? Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF0D1220),
              borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.tv, color: Color(0xFF8B96B8), size: 16))
        : ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Image.network(c.logo, width: 36, height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFF0D1220),
                  borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.tv,
                  color: Color(0xFF8B96B8), size: 16)))),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 13,
          fontWeight: FontWeight.w600)),
      subtitle: Text(c.group, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF8B96B8), fontSize: 10)),
      onTap: () => _openPlayer(c),
      trailing: IconButton(
        icon: Icon(fav ? Icons.star : Icons.star_border,
          color: fav ? const Color(0xFFFBBF24) : const Color(0xFF8B96B8),
          size: 20),
        onPressed: () => _toggleFav(c)),
    );
  }

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 44),
      const SizedBox(height: 10),
      const Text('Erreur de chargement',
        style: TextStyle(color: Colors.white, fontSize: 15)),
      const SizedBox(height: 6),
      Text(_error ?? '', textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8B96B8), fontSize: 12)),
      const SizedBox(height: 14),
      ElevatedButton.icon(onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914))),
    ])));

  Widget _creditBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF232B42)))),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      GabonFlag(w: 14, h: 9), SizedBox(width: 6),
      Text('Conçu par Damien (Starly Koumba)',
        style: TextStyle(color: Color(0xFF8B96B8), fontSize: 10)),
      SizedBox(width: 6), GabonFlag(w: 14, h: 9),
    ]),
  );
}

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      setState(() { _loading = true; _error = null; });
      _ctrl?.dispose();
      _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.url),
        httpHeaders: {
          'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
          'Referer': widget.channel.url,
        },
      );
      await _ctrl!.initialize();
      await _ctrl!.play();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Row(children: [
        const GabonFlag(w: 20, h: 12), const SizedBox(width: 8),
        Expanded(child: Text(widget.channel.name,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          overflow: TextOverflow.ellipsis)),
      ]),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _start)],
    ),
    body: Center(child: _error != null
      ? Padding(padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 44),
            const SizedBox(height: 12),
            const Text('Lecture impossible',
              style: TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B96B8), fontSize: 11)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _start,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914))),
          ]))
      : _loading ? const CircularProgressIndicator(color: Color(0xFFE50914))
      : AspectRatio(
          aspectRatio: _ctrl!.value.aspectRatio,
          child: VideoPlayer(_ctrl!))),
  );
}
