import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DamienApp());
}

class C {
  static const bg = Color(0xFF0B0F1A);
  static const card = Color(0xFF151B2B);
  static const accent = Color(0xFFE50914);
  static const gold = Color(0xFFFBBF24);
  static const text = Color(0xFFEEF2FF);
  static const muted = Color(0xFF8B96B8);
}

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

/* ====================== MODELS ====================== */
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

class Movie {
  final String title, description, poster, videoUrl, genre, language;
  final int year;
  final double rating;
  final bool featured;
  Movie({required this.title, required this.description, required this.poster,
    required this.videoUrl, required this.genre, required this.language,
    required this.year, this.rating = 4.5, this.featured = false});
}

/* ====================== BIBLIOTHÈQUE ====================== */
final List<Movie> library = [
  Movie(title: 'Big Buck Bunny',
    description: 'Un gros lapin gentil se venge de trois rongeurs malins. Court-métrage 3D libre.',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    genre: 'Animation', language: 'FR', year: 2008, rating: 4.8, featured: true),
  Movie(title: 'Sintel',
    description: 'Une jeune femme part à la recherche de son dragonneau. Chef-d\'œuvre libre.',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/3/33/Sintel_poster.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    genre: 'Animation', language: 'FR', year: 2010, rating: 4.9, featured: true),
  Movie(title: 'Le Voyage dans la Lune',
    description: 'Chef-d\'œuvre de Georges Méliès (1902). Film muet français, domaine public.',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/9/9f/Le_Voyage_dans_la_Lune.jpg',
    videoUrl: 'https://archive.org/download/Le_Voyage_dans_la_Lune_1902/Le_Voyage_dans_la_Lune_1902_512kb.mp4',
    genre: 'Aventure', language: 'FR', year: 1902, rating: 4.9, featured: true),
  Movie(title: 'Fantômas',
    description: 'Série culte de Louis Feuillade (1913). Film muet français, domaine public.',
    poster: 'https://archive.org/services/img/Fantomas_1913',
    videoUrl: 'https://archive.org/download/Fantomas_1913/Fantomas_1913_512kb.mp4',
    genre: 'Policier', language: 'FR', year: 1913, rating: 4.6),
  Movie(title: 'Les Vampires',
    description: 'Serial policier français de Louis Feuillade (1915). Domaine public.',
    poster: 'https://archive.org/services/img/LesVampires',
    videoUrl: 'https://archive.org/download/LesVampires/LesVampires_512kb.mp4',
    genre: 'Policier', language: 'FR', year: 1915, rating: 4.7),
  Movie(title: 'Le Voyage Imaginaire',
    description: 'Comédie fantastique de René Clair (1926). Muet français.',
    poster: 'https://archive.org/services/img/LeVoyageImaginaire',
    videoUrl: 'https://archive.org/download/LeVoyageImaginaire/LeVoyageImaginaire_512kb.mp4',
    genre: 'Comédie', language: 'FR', year: 1926, rating: 4.5),
  Movie(title: 'Napoléon',
    description: 'Chef-d\'œuvre d\'Abel Gance (1927). Film muet français monumental.',
    poster: 'https://archive.org/services/img/Napoleon1927',
    videoUrl: 'https://archive.org/download/Napoleon1927/Napoleon1927_512kb.mp4',
    genre: 'Historique', language: 'FR', year: 1927, rating: 4.9),
  Movie(title: 'Tears of Steel',
    description: 'Science-fiction néerlandaise mêlant acteurs et effets spéciaux.',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/4/49/Tos-poster.png',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 2012, rating: 4.5),
  Movie(title: 'Elephants Dream',
    description: 'Premier film open movie de Blender. Surréaliste et poétique.',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/8/83/Elephants_Dream_Poster.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    genre: 'Animation', language: 'VO', year: 2006, rating: 4.3),
  Movie(title: 'Nosferatu',
    description: 'Chef-d\'œuvre expressionniste de F.W. Murnau (1922).',
    poster: 'https://archive.org/services/img/nosferatu',
    videoUrl: 'https://archive.org/download/nosferatu/nosferatu_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1922, rating: 4.9),
  Movie(title: 'Metropolis',
    description: 'Classique visionnaire de Fritz Lang (1927).',
    poster: 'https://archive.org/services/img/Metropolis1927',
    videoUrl: 'https://archive.org/download/Metropolis1927/Metropolis1927_512kb.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 1927, rating: 4.9),
  Movie(title: 'Night of the Living Dead',
    description: 'Le film zombie culte de Romero (1968). Domaine public.',
    poster: 'https://archive.org/services/img/night_of_the_living_dead',
    videoUrl: 'https://archive.org/download/night_of_the_living_dead/night_of_the_living_dead_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1968, rating: 4.7),
  Movie(title: 'Plan 9 from Outer Space',
    description: 'Le film culte d\'Ed Wood (1959). Le "meilleur nanar".',
    poster: 'https://archive.org/services/img/Plan_9_from_Outer_Space_1959',
    videoUrl: 'https://archive.org/download/Plan_9_from_Outer_Space_1959/Plan_9_from_Outer_Space_1959_512kb.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 1959, rating: 4.0),
  Movie(title: 'The General',
    description: 'Comédie burlesque de Buster Keaton (1926).',
    poster: 'https://archive.org/services/img/TheGeneral_201208',
    videoUrl: 'https://archive.org/download/TheGeneral_201208/TheGeneral_201208_512kb.mp4',
    genre: 'Comédie', language: 'VO', year: 1926, rating: 4.8),
  Movie(title: 'His Girl Friday',
    description: 'Comédie romantique avec Cary Grant (1940).',
    poster: 'https://archive.org/services/img/his_girl_friday',
    videoUrl: 'https://archive.org/download/his_girl_friday/his_girl_friday_512kb.mp4',
    genre: 'Comédie', language: 'VO', year: 1940, rating: 4.7),
  Movie(title: 'The Cabinet of Dr. Caligari',
    description: 'Chef-d\'œuvre expressionniste de Robert Wiene (1920).',
    poster: 'https://archive.org/services/img/TheCabinetOfDrCaligari',
    videoUrl: 'https://archive.org/download/TheCabinetOfDrCaligari/TheCabinetOfDrCaligari_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1920, rating: 4.8),
  Movie(title: 'Charade',
    description: 'Thriller avec Cary Grant et Audrey Hepburn (1963).',
    poster: 'https://archive.org/services/img/charade_1963',
    videoUrl: 'https://archive.org/download/charade_1963/charade_1963_512kb.mp4',
    genre: 'Thriller', language: 'VO', year: 1963, rating: 4.6),
  Movie(title: 'Superman Cartoons',
    description: 'Les cartoons Fleischer de Superman (1941).',
    poster: 'https://archive.org/services/img/superman_cartoons',
    videoUrl: 'https://archive.org/download/superman_cartoons/superman_cartoons_512kb.mp4',
    genre: 'Animation', language: 'VO', year: 1941, rating: 4.5),
  Movie(title: 'Subaru Outback',
    description: 'Essai auto libre de droits.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Volkswagen GTI Review',
    description: 'Essai auto libre.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/VolkswagenGTIReview.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'We Are Going On Bullrun',
    description: 'Reportage auto libre.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/WeAreGoingOnBullrun.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
];

/* ====================== PARSER M3U ====================== */
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

/* ====================== STORAGE ====================== */
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

/* ====================== APP ====================== */
class DamienApp extends StatelessWidget {
  const DamienApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Damien TV 241',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.accent, secondary: C.gold)),
    home: const RootScreen(),
  );
}

/* ====================== ROOT (4 onglets) ====================== */
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: const [
      HomeScreen(), M3UScreen(), DirectScreen(), FavoritesScreen(),
    ]),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx,
      onTap: (i) => setState(() => _idx = i),
      backgroundColor: C.card,
      selectedItemColor: C.accent,
      unselectedItemColor: C.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'M3U'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Direct'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
      ]),
  );
}

/* ====================== HEADER COMMUN ====================== */
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
          const Text('Damien TV 241',
            style: TextStyle(color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.bold)),
          const SizedBox(width: 6), const Flag(w: 18, h: 11),
        ]),
        Text(subtitle, style: const TextStyle(color: C.gold, fontSize: 9,
          letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}

class CreditBar extends StatelessWidget {
  const CreditBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flag(w: 14, h: 9), SizedBox(width: 6),
      Text('Conçu par Damien (Starly Koumba)',
        style: TextStyle(color: C.muted, fontSize: 10)),
      SizedBox(width: 6), Flag(w: 14, h: 9),
    ]));
}

/* ====================== HOME (NETFLIX STYLE) ====================== */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _langFilter = 'TOUS';

  List<Movie> get _filtered {
    if (_langFilter == 'TOUS') return library;
    return library.where((m) => m.language == _langFilter).toList();
  }

  List<Movie> byGenre(String g) => _filtered.where((m) => m.genre == g).toList();
  List<Movie> get _top10 {
    final s = [..._filtered]..sort((a, b) => b.rating.compareTo(a.rating));
    return s.take(10).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • FILMS'),
      // Filtre langue
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: C.bg,
        child: Row(children: [
          const Text('Langue :',
            style: TextStyle(color: C.muted, fontSize: 11,
              fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _langChip('TOUS', '🌍 Tous'),
          const SizedBox(width: 6),
          _langChip('FR', '🇫🇷 Français'),
          const SizedBox(width: 6),
          _langChip('VO', '🌐 VO'),
        ])),
      Expanded(child: _filtered.isEmpty
        ? const Center(child: Text('Aucun film',
            style: TextStyle(color: C.muted)))
        : _list()),
    ]),
  );

  Widget _langChip(String value, String label) {
    final active = _langFilter == value;
    return InkWell(
      onTap: () => setState(() => _langFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? C.accent : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? C.accent : C.muted.withOpacity(0.3))),
        child: Text(label,
          style: TextStyle(color: active ? Colors.white : C.muted,
            fontSize: 11, fontWeight: FontWeight.w600)),
      ));
  }

  Widget _list() {
    final featured = _filtered.where((m) => m.featured).toList();
    return ListView(children: [
      if (featured.isNotEmpty) _banner(featured.first),
      const SizedBox(height: 12),
      _section('⭐ Tendances', _top10),
      _section('🎬 Films Français', _filtered.where((m) => m.language == 'FR').toList()),
      _section('🐰 Animations', byGenre('Animation')),
      _section('🚀 Science-Fiction', byGenre('Science-Fiction')),
      _section('👻 Horreur', byGenre('Horreur')),
      _section('😂 Comédie', byGenre('Comédie')),
      _section('🕵️ Policier', byGenre('Policier')),
      _section('📚 Documentaires', byGenre('Documentaire')),
      _section('🎭 Historique', byGenre('Historique')),
      const SizedBox(height: 20),
      const CreditBar(),
      const SizedBox(height: 12),
    ]);
  }

  Widget _banner(Movie f) => SizedBox(height: 420, child: Stack(children: [
    Positioned.fill(child: CachedNetworkImage(
      imageUrl: f.poster, fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: C.card),
      errorWidget: (_, __, ___) => Container(color: C.card))),
    Positioned.fill(child: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, C.bg], stops: [0.35, 1.0])))),
    Positioned(left: 16, right: 16, bottom: 16, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: C.accent,
          borderRadius: BorderRadius.circular(4)),
        child: const Text('TOP AUJOURD\'HUI',
          style: TextStyle(color: Colors.white, fontSize: 10,
            fontWeight: FontWeight.bold, letterSpacing: 1))),
      const SizedBox(height: 8),
      Text(f.title, style: const TextStyle(color: Colors.white,
        fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.star, color: C.gold, size: 16),
        Text(' ${f.rating}  •  ${f.year}  •  ${f.genre}  •  ${f.language}',
          style: const TextStyle(color: C.muted, fontSize: 11)),
      ]),
      const SizedBox(height: 8),
      Text(f.description, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _openMovie(f),
          icon: const Icon(Icons.play_arrow, size: 20),
          label: const Text('Lecture', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))))),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white24,
            borderRadius: BorderRadius.circular(6)),
          child: IconButton(icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfo(f))),
      ]),
    ])),
  ]));

  Widget _section(String title, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Text(title, style: const TextStyle(color: Colors.white,
          fontSize: 16, fontWeight: FontWeight.bold))),
      SizedBox(height: 210, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: movies.length,
        itemBuilder: (_, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => _openMovie(m),
            child: Container(width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: m.poster,
                    width: 130, height: 180, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 130, height: 180,
                      color: C.card, child: const Icon(Icons.movie, color: C.muted)),
                    errorWidget: (_, __, ___) => Container(width: 130, height: 180,
                      color: C.card, child: const Icon(Icons.movie, color: C.muted)))),
                const SizedBox(height: 6),
                Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w600)),
                Text('${m.language} • ⭐ ${m.rating}',
                  style: const TextStyle(color: C.muted, fontSize: 10)),
              ])),
          );
        })),
    ]);
  }

  void _openMovie(Movie m) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        title: m.title,
        url: m.videoUrl)));
  }

  void _showInfo(Movie m) {
    showModalBottomSheet(context: context, backgroundColor: C.card,
      builder: (_) => Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title, style: const TextStyle(color: Colors.white,
            fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${m.year} • ${m.genre} • ${m.language} • ⭐ ${m.rating}',
            style: const TextStyle(color: C.gold, fontSize: 12)),
          const SizedBox(height: 12),
          Text(m.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); _openMovie(m); },
            icon: const Icon(Icons.play_arrow), label: const Text('Lecture'),
            style: ElevatedButton.styleFrom(backgroundColor: C.accent))),
        ])));
  }
}

/* ====================== M3U SCREEN ====================== */
class M3UScreen extends StatefulWidget {
  const M3UScreen({super.key});
  @override
  State<M3UScreen> createState() => _M3UScreenState();
}

class _M3UScreenState extends State<M3UScreen> {
  final _urlCtrl = TextEditingController(
    text: 'https://tvradiozap.eu/live/x/vlc/d/tvzeu.m3u');
  final _searchCtrl = TextEditingController();
  List<Channel> _all = [];
  bool _loading = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(() =>
      setState(() => _search = _searchCtrl.text.toLowerCase().trim()));
  }

  Future<void> _init() async {
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
      _snack('OK : ${ch.length} chaînes');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
      _snack('Erreur : $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: C.card));
  }

  List<Channel> get _visible {
    if (_search.isEmpty) return _all;
    return _all.where((c) => c.name.toLowerCase().contains(_search) ||
      c.group.toLowerCase().contains(_search)).toList();
  }

  Map<String, List<Channel>> get _grouped {
    final m = <String, List<Channel>>{};
    for (final c in _visible) m.putIfAbsent(c.group, () => []).add(c);
    return m;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • IPTV'),
      Padding(padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: TextField(controller: _urlCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: _deco('URL M3U / M3U8'))),
          const SizedBox(width: 6),
          ElevatedButton(onPressed: _loading ? null : _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent, foregroundColor: Colors.white),
            child: const Text('Charger', style: TextStyle(fontSize: 12))),
        ])),
      Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: TextField(controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Rechercher une chaîne...',
            hintStyle: const TextStyle(color: C.muted),
            prefixIcon: const Icon(Icons.search, color: C.muted, size: 18),
            filled: true, fillColor: const Color(0xFF0D1220),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF232B42)))))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.accent))
        : _error != null ? _err() : _list()),
      const CreditBar(),
    ]),
  );

  InputDecoration _deco(String h) => InputDecoration(
    hintText: h, hintStyle: const TextStyle(color: C.muted, fontSize: 11),
    filled: true, fillColor: const Color(0xFF0D1220),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF232B42))));

  Widget _list() {
    if (_visible.isEmpty) return Center(child: Text(
      _all.isEmpty ? 'Charge une playlist' : 'Aucun résultat',
      style: const TextStyle(color: C.muted)));
    return ListView(children: _grouped.entries.expand((e) => [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text('${e.key.toUpperCase()} (${e.value.length})',
          style: const TextStyle(color: C.muted, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ...e.value.map((c) => ListTile(
        dense: true,
        leading: c.logo.isEmpty
          ? _fb()
          : ClipRRect(borderRadius: BorderRadius.circular(6),
              child: Image.network(c.logo, width: 36, height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fb())),
        title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w600)),
        subtitle: Text(c.group, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: C.muted, fontSize: 10)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlayerScreen(
            title: c.name, url: c.url,
            allChannels: _all, currentChannel: c))),
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

/* ====================== DIRECT SCREEN ====================== */
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
          const Text('Lien direct',
            style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Colle ton lien m3u8, rtsp, rtmp, mp4...',
            style: TextStyle(color: C.muted, fontSize: 12),
            textAlign: TextAlign.center),
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
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlayerScreen(title: 'Flux direct', url: u)));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lire le lien',
              style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)))),
        ]))),
      const CreditBar(),
    ]),
  );
}

/* ====================== FAVORIS ====================== */
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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlayerScreen(title: c.name, url: c.url))),
            );
          })),
      const CreditBar(),
    ]),
  );
}

/* ====================== PLAYER ====================== */
class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  final List<Channel>? allChannels;
  final Channel? currentChannel;
  const PlayerScreen({super.key, required this.title, required this.url,
    this.allChannels, this.currentChannel});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _loading = true;
  String? _error;
  bool _controlsVisible = true;
  double _speed = 1.0;
  bool _fullscreen = false;
  late String _title;
  late String _url;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _url = widget.url;
    _start();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight]);
  }

  Future<void> _start() async {
    try {
      setState(() { _loading = true; _error = null; });
      _ctrl?.dispose();
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(_url),
        httpHeaders: {
          'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
          'Referer': _url,
        });
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
    if (pos == null) return;
    final np = pos + Duration(seconds: s);
    await _ctrl!.seekTo(np.isNegative ? Duration.zero : np);
  }

  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    setState(() => _speed = speeds[(idx + 1) % speeds.length]);
    _ctrl?.setPlaybackSpeed(_speed);
  }

  void _openList() {
    if (widget.allChannels == null) return;
    showModalBottomSheet(context: context, backgroundColor: C.card,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white24,
              borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(12),
            child: Text('Changer de chaîne',
              style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.bold))),
          Expanded(child: ListView.builder(controller: sc,
            itemCount: widget.allChannels!.length,
            itemBuilder: (_, i) {
              final c = widget.allChannels![i];
              final active = widget.currentChannel?.url == c.url;
              return ListTile(dense: true,
                tileColor: active ? const Color(0xFF1B2338) : null,
                leading: c.logo.isEmpty
                  ? const Icon(Icons.tv, color: C.muted)
                  : Image.network(c.logo, width: 32, height: 32,
                      errorBuilder: (_, __, ___) =>
                        const Icon(Icons.tv, color: C.muted)),
                title: Text(c.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                subtitle: Text(c.group,
                  style: const TextStyle(color: C.muted, fontSize: 10)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _title = c.name; _url = c.url; });
                  _start();
                });
            })),
        ])));
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
        Center(child: _buildVideo()),
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
              Expanded(child: Text(_title,
                style: const TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (widget.allChannels != null)
                IconButton(icon: const Icon(Icons.list, color: Colors.white),
                  onPressed: _openList),
              IconButton(icon: Icon(_fullscreen
                ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent])),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              _btn('${_speed}x', Icons.speed, _cycleSpeed),
              _btn('-10s', Icons.replay_10, () => _seek(-10)),
              IconButton(iconSize: 48,
                icon: Icon(_ctrl?.value.isPlaying == true
                  ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white),
                onPressed: () {
                  if (_ctrl == null) return;
                  setState(() => _ctrl!.value.isPlaying
                    ? _ctrl!.pause() : _ctrl!.play());
                }),
              _btn('+10s', Icons.forward_10, () => _seek(10)),
              _btn('Liste', Icons.playlist_play, _openList),
            ]))),
        if (_loading) const Center(
          child: CircularProgressIndicator(color: C.accent)),
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
            ElevatedButton.icon(onPressed: _start,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: C.accent)),
          ]))),
      ])),
  );

  Widget _buildVideo() {
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
      child: VideoPlayer(_ctrl!));
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: Icon(icon, color: Colors.white, size: 26),
        onPressed: onTap),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
    ]);
}
