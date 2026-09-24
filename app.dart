import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

/* ===== MODELS ===== */
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

class Episode {
  final int number;
  final String title, videoUrl;
  Episode({required this.number, required this.title, required this.videoUrl});
}

class Series {
  final String title, description, poster, genre, language;
  final int year;
  final double rating;
  final List<Episode> episodes;
  Series({required this.title, required this.description, required this.poster,
    required this.genre, required this.language, required this.year,
    this.rating = 4.5, required this.episodes});
}

/* ===== FILMS ===== */
final List<Movie> library = [
  Movie(title: 'Big Buck Bunny', description: 'Un gros lapin gentil se venge de trois rongeurs.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    genre: 'Animation', language: 'FR', year: 2008, rating: 4.8, featured: true),
  Movie(title: 'Sintel', description: 'Une jeune femme part à la recherche de son dragonneau.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    genre: 'Animation', language: 'FR', year: 2010, rating: 4.9, featured: true),
  Movie(title: 'Elephants Dream', description: 'Surréaliste et poétique.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    genre: 'Animation', language: 'FR', year: 2006, rating: 4.3),
  Movie(title: 'Tears of Steel', description: 'Science-fiction avec effets spéciaux.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 2012, rating: 4.5),
  Movie(title: 'For Bigger Blazes', description: 'Action démo HD.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    genre: 'Action', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'For Bigger Escapes', description: 'Aventure démo HD.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    genre: 'Action', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'For Bigger Fun', description: 'Comédie démo HD.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    genre: 'Comédie', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'For Bigger Joyrides', description: 'Action démo HD.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    genre: 'Action', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'For Bigger Meltdowns', description: 'Action démo HD.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerMeltdowns.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    genre: 'Action', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Subaru Outback', description: 'Essai auto tout-terrain.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Volkswagen GTI', description: 'Essai auto sport.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/VolkswagenGTIReview.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Bullrun Rally', description: 'Reportage course auto.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/WeAreGoingOnBullrun.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Voiture à 1000€', description: 'Documentaire auto.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/WhatCarCanYouGetForAGrand.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
    genre: 'Documentaire', language: 'VO', year: 2015, rating: 4.2),
  Movie(title: 'Nosferatu', description: 'Le vampire de Murnau (1922).',
    poster: 'https://archive.org/services/img/nosferatu',
    videoUrl: 'https://archive.org/download/nosferatu/nosferatu_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1922, rating: 4.9, featured: true),
  Movie(title: 'Metropolis', description: 'Le classique de Fritz Lang (1927).',
    poster: 'https://archive.org/services/img/Metropolis1927',
    videoUrl: 'https://archive.org/download/Metropolis1927/Metropolis1927_512kb.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 1927, rating: 4.9),
  Movie(title: 'Night of the Living Dead', description: 'Le film zombie culte de Romero (1968).',
    poster: 'https://archive.org/services/img/night_of_the_living_dead',
    videoUrl: 'https://archive.org/download/night_of_the_living_dead/night_of_the_living_dead_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1968, rating: 4.7),
  Movie(title: 'The Cabinet of Dr. Caligari', description: 'Expressionniste (1920).',
    poster: 'https://archive.org/services/img/TheCabinetOfDrCaligari',
    videoUrl: 'https://archive.org/download/TheCabinetOfDrCaligari/TheCabinetOfDrCaligari_512kb.mp4',
    genre: 'Horreur', language: 'VO', year: 1920, rating: 4.8),
  Movie(title: 'The General', description: 'Buster Keaton (1926).',
    poster: 'https://archive.org/services/img/TheGeneral_201208',
    videoUrl: 'https://archive.org/download/TheGeneral_201208/TheGeneral_201208_512kb.mp4',
    genre: 'Comédie', language: 'VO', year: 1926, rating: 4.8),
  Movie(title: 'Plan 9 from Outer Space', description: 'Ed Wood (1959).',
    poster: 'https://archive.org/services/img/Plan_9_from_Outer_Space_1959',
    videoUrl: 'https://archive.org/download/Plan_9_from_Outer_Space_1959/Plan_9_from_Outer_Space_1959_512kb.mp4',
    genre: 'Science-Fiction', language: 'VO', year: 1959, rating: 4.0),
  Movie(title: 'Charade', description: 'Audrey Hepburn (1963).',
    poster: 'https://archive.org/services/img/charade_1963',
    videoUrl: 'https://archive.org/download/charade_1963/charade_1963_512kb.mp4',
    genre: 'Thriller', language: 'VO', year: 1963, rating: 4.6),
  Movie(title: 'Le Voyage dans la Lune', description: 'Méliès (1902).',
    poster: 'https://upload.wikimedia.org/wikipedia/commons/9/9f/Le_Voyage_dans_la_Lune.jpg',
    videoUrl: 'https://archive.org/download/Le_Voyage_dans_la_Lune_1902/Le_Voyage_dans_la_Lune_1902_512kb.mp4',
    genre: 'Aventure', language: 'FR', year: 1902, rating: 4.9),
  Movie(title: 'Fantômas', description: 'Louis Feuillade (1913).',
    poster: 'https://archive.org/services/img/Fantomas_1913',
    videoUrl: 'https://archive.org/download/Fantomas_1913/Fantomas_1913_512kb.mp4',
    genre: 'Policier', language: 'FR', year: 1913, rating: 4.6),
];

/* ===== DESSINS ANIMÉS ===== */
final List<Movie> cartoons = [
  Movie(title: 'Big Buck Bunny', description: 'Le célèbre court-métrage 3D.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    genre: 'Dessin animé', language: 'FR', year: 2008, rating: 4.8),
  Movie(title: 'Sintel', description: 'Une quête fantastique.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    genre: 'Dessin animé', language: 'FR', year: 2010, rating: 4.9),
  Movie(title: 'Elephants Dream', description: 'Surréaliste et poétique.',
    poster: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    genre: 'Dessin animé', language: 'FR', year: 2006, rating: 4.3),
  Movie(title: 'Superman - Fleischer', description: 'Cartoons Superman (1941).',
    poster: 'https://archive.org/services/img/superman_cartoons',
    videoUrl: 'https://archive.org/download/superman_cartoons/superman_cartoons_512kb.mp4',
    genre: 'Dessin animé', language: 'VO', year: 1941, rating: 4.6),
];

/* ===== SÉRIES ===== */
final List<Series> seriesLibrary = [
  Series(
    title: 'Les Vampires',
    description: 'Serial policier culte de Louis Feuillade (1915).',
    poster: 'https://archive.org/services/img/LesVampires',
    genre: 'Policier', language: 'FR', year: 1915, rating: 4.7,
    episodes: [
      Episode(number: 1, title: 'La Tête coupée', videoUrl: 'https://archive.org/download/LesVampires/LesVampires_01_512kb.mp4'),
      Episode(number: 2, title: 'La Bague qui tue', videoUrl: 'https://archive.org/download/LesVampires/LesVampires_02_512kb.mp4'),
      Episode(number: 3, title: 'Le Cryptogramme rouge', videoUrl: 'https://archive.org/download/LesVampires/LesVampires_03_512kb.mp4'),
      Episode(number: 4, title: 'Le Spectre', videoUrl: 'https://archive.org/download/LesVampires/LesVampires_04_512kb.mp4'),
      Episode(number: 5, title: 'L\'Évasion du mort', videoUrl: 'https://archive.org/download/LesVampires/LesVampires_05_512kb.mp4'),
    ]),
  Series(
    title: 'Fantômas',
    description: 'Série policière culte (1913).',
    poster: 'https://archive.org/services/img/Fantomas_1913',
    genre: 'Policier', language: 'FR', year: 1913, rating: 4.6,
    episodes: [
      Episode(number: 1, title: 'Fantômas', videoUrl: 'https://archive.org/download/Fantomas_1913/Fantomas_1913_01_512kb.mp4'),
      Episode(number: 2, title: 'Juve contre Fantômas', videoUrl: 'https://archive.org/download/Fantomas_1913/Fantomas_1913_02_512kb.mp4'),
      Episode(number: 3, title: 'Le Mort qui tue', videoUrl: 'https://archive.org/download/Fantomas_1913/Fantomas_1913_03_512kb.mp4'),
    ]),
  Series(
    title: 'Flash Gordon',
    description: 'Serial de science-fiction culte (1936).',
    poster: 'https://archive.org/services/img/FlashGordonSerial',
    genre: 'Science-Fiction', language: 'VO', year: 1936, rating: 4.5,
    episodes: [
      Episode(number: 1, title: 'Planet in Peril', videoUrl: 'https://archive.org/download/FlashGordonSerial/FlashGordon_01_512kb.mp4'),
      Episode(number: 2, title: 'Tunnel of Terror', videoUrl: 'https://archive.org/download/FlashGordonSerial/FlashGordon_02_512kb.mp4'),
      Episode(number: 3, title: 'Shark Men', videoUrl: 'https://archive.org/download/FlashGordonSerial/FlashGordon_03_512kb.mp4'),
    ]),
  Series(
    title: 'Batman (1943)',
    description: 'Le tout premier serial Batman.',
    poster: 'https://archive.org/services/img/Batman1943Serial',
    genre: 'Aventure', language: 'VO', year: 1943, rating: 4.3,
    episodes: [
      Episode(number: 1, title: 'The Electrical Brain', videoUrl: 'https://archive.org/download/Batman1943Serial/Batman_01_512kb.mp4'),
      Episode(number: 2, title: 'The Bat\'s Cave', videoUrl: 'https://archive.org/download/Batman1943Serial/Batman_02_512kb.mp4'),
      Episode(number: 3, title: 'Mark of the Zombies', videoUrl: 'https://archive.org/download/Batman1943Serial/Batman_03_512kb.mp4'),
    ]),
];

/* ===== PARSER M3U ===== */
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
    final intentUrl = 'intent://${url.replaceFirst(RegExp(r'^https?://'), '')}'
        '#Intent;scheme=${url.startsWith('https') ? 'https' : 'http'};'
        'package=org.videolan.vlc;type=video/*;end';
    final u = Uri.parse(intentUrl);
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
    home: const RootScreen(),
  );
}

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
      HomeScreen(), CartoonScreen(), SeriesScreen(), M3UScreen(), DirectScreen(),
    ]),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx,
      onTap: (i) => setState(() => _idx = i),
      backgroundColor: C.card,
      selectedItemColor: C.accent,
      unselectedItemColor: C.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Films'),
        BottomNavigationBarItem(icon: Icon(Icons.animation), label: 'Dessins'),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Séries'),
        BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'M3U'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Direct'),
      ]),
  );
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

/* ===== CARTE FILM ===== */
Widget movieCard(BuildContext context, Movie m) => GestureDetector(
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => PlayerScreen(title: m.title, url: m.videoUrl))),
  child: Container(width: 130, margin: const EdgeInsets.symmetric(horizontal: 4),
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
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      Text('${m.language} • ⭐ ${m.rating}',
        style: const TextStyle(color: C.muted, fontSize: 10)),
    ])));

Widget movieSection(String title, List<Movie> movies) {
  if (movies.isEmpty) return const SizedBox.shrink();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.white,
        fontSize: 16, fontWeight: FontWeight.bold))),
    SizedBox(height: 210, child: Builder(builder: (ctx) =>
      ListView.builder(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: movies.length,
        itemBuilder: (_, i) => movieCard(ctx, movies[i])))),
  ]);
}

/* ===== ACCUEIL ===== */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lang = 'TOUS';
  List<Movie> get _f => _lang == 'TOUS' ? library
    : library.where((m) => m.language == _lang).toList();
  List<Movie> byG(String g) => _f.where((m) => m.genre == g).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • FILMS'),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: C.bg,
        child: Row(children: [
          const Text('Langue :', style: TextStyle(color: C.muted, fontSize: 11)),
          const SizedBox(width: 8),
          _chip('TOUS', '🌍 Tous'), const SizedBox(width: 6),
          _chip('FR', '🇫🇷 FR'), const SizedBox(width: 6),
          _chip('VO', '🌐 VO'),
        ])),
      Expanded(child: ListView(children: [
        movieSection('⭐ Tendances', _f.take(10).toList()),
        movieSection('🎬 Films Français', _f.where((m) => m.language == 'FR').toList()),
        movieSection('🚀 Science-Fiction', byG('Science-Fiction')),
        movieSection('👻 Horreur', byG('Horreur')),
        movieSection('😂 Comédie', byG('Comédie')),
        movieSection('💥 Action', byG('Action')),
        movieSection('🕵️ Policier', byG('Policier')),
        movieSection('📚 Documentaires', byG('Documentaire')),
        const SizedBox(height: 20),
        const CreditBar(),
      ])),
    ]),
  );

  Widget _chip(String v, String label) {
    final a = _lang == v;
    return InkWell(onTap: () => setState(() => _lang = v),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: a ? C.accent : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: a ? C.accent : C.muted.withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: a ? Colors.white : C.muted,
          fontSize: 11, fontWeight: FontWeight.w600))));
  }
}

/* ===== DESSINS ===== */
class CartoonScreen extends StatelessWidget {
  const CartoonScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • DESSINS ANIMÉS'),
      Expanded(child: ListView(children: [
        movieSection('🎨 Dessins Animés', cartoons),
        const SizedBox(height: 20),
        const CreditBar(),
      ])),
    ]),
  );
}

/* ===== SÉRIES ===== */
class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      const AppHeader(subtitle: 'PROTOTYPE NEYLA 241 • SÉRIES'),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: seriesLibrary.length,
        itemBuilder: (_, i) {
          final s = seriesLibrary[i];
          return Card(color: C.card, margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(series: s))),
              child: Padding(padding: const EdgeInsets.all(10),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(imageUrl: s.poster,
                      width: 80, height: 110, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 80,
                        height: 110, color: C.bg,
                        child: const Icon(Icons.video_library, color: C.muted)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(s.title, style: const TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${s.year} • ${s.genre} • ${s.language} • ⭐ ${s.rating}',
                      style: const TextStyle(color: C.gold, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.muted, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text('${s.episodes.length} épisodes',
                      style: const TextStyle(color: C.accent, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ])),
                ]))));
        })),
      const CreditBar(),
    ]),
  );
}

class SeriesDetailScreen extends StatelessWidget {
  final Series series;
  const SeriesDetailScreen({super.key, required this.series});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    appBar: AppBar(backgroundColor: C.card,
      title: Text(series.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      iconTheme: const IconThemeData(color: Colors.white)),
    body: ListView(children: [
      SizedBox(height: 200, child: Stack(children: [
        Positioned.fill(child: CachedNetworkImage(imageUrl: series.poster,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: C.card))),
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, C.bg])))),
      ])),
      Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(series.title, style: const TextStyle(color: Colors.white,
          fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${series.year} • ${series.genre} • ${series.language} • ⭐ ${series.rating}',
          style: const TextStyle(color: C.gold, fontSize: 12)),
        const SizedBox(height: 12),
        Text(series.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 20),
        const Text('Épisodes', style: TextStyle(color: Colors.white,
          fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
      ])),
      ...series.episodes.map((ep) => ListTile(
        leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text('${ep.number}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        title: Text(ep.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text('Épisode ${ep.number}', style: const TextStyle(color: C.muted, fontSize: 11)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlayerScreen(title: '${series.title} - ${ep.title}',
            url: ep.videoUrl))),
      )),
      const SizedBox(height: 20),
      const CreditBar(),
    ]),
  );
}

/* ===== M3U ===== */
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
  String _category = 'TOUTES';

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
    if (_vis.isEmpty) return Center(child: Text(
      _all.isEmpty ? 'Charge une playlist' : 'Aucun résultat',
      style: const TextStyle(color: C.muted)));
    return ListView(children: _grouped.entries.expand((e) => [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text('${e.key.toUpperCase()} (${e.value.length})',
          style: const TextStyle(color: C.muted, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      ...e.value.map((c) => ListTile(
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
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline, color: C.accent, size: 22),
          tooltip: 'Ouvrir dans VLC', onPressed: () => openInVlc(c.url)),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlayerScreen(title: c.name, url: c.url))),
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
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlayerScreen(title: 'Flux direct', url: u)));
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
      const CreditBar(),
    ]),
  );
}

/* ===== PLAYER ===== */
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
  bool _remoteMode = false;
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

  void _toggleRemote() {
    setState(() {
      _remoteMode = !_remoteMode;
      _fullscreen = _remoteMode;
    });
    if (_remoteMode) {
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
    WakelockPlus.disable();
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
              IconButton(icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                tooltip: 'VLC', onPressed: () => openInVlc(widget.url)),
              IconButton(icon: Icon(_remoteMode ? Icons.tv_off : Icons.tv, color: Colors.white),
                tooltip: 'Mode télécommande', onPressed: _toggleRemote),
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_remoteMode) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _bigBtn(Icons.speed, '${_speed}x', _cycleSpeed),
                  const SizedBox(width: 40),
                  _bigBtn(Icons.play_circle_outline, 'VLC',
                    () => openInVlc(widget.url)),
                ])),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                  onPressed: () => _seek(-10)),
                IconButton(iconSize: _remoteMode ? 70 : 54,
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
              ]),
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
      ])),
  );

  Widget _bigBtn(IconData icon, String label, VoidCallback onTap) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: Icon(icon, color: Colors.white, size: 32), onPressed: onTap),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
}
