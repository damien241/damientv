import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const Home(),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _ctrl = TextEditingController(
    text: 'https://iptv-org.github.io/iptv/countries/fr.m3u');
  List<Map<String, String>> _channels = [];
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(_ctrl.text));
      final lines = res.body.split('\n');
      final list = <Map<String, String>>[];
      String? name;
      for (var line in lines) {
        line = line.trim();
        if (line.startsWith('#EXTINF:')) {
          name = line.split(',').last.trim();
        } else if (line.isNotEmpty && !line.startsWith('#') && name != null) {
          list.add({'name': name, 'url': line});
          name = null;
        }
      }
      setState(() { _channels = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Damien TV 241')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl)),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _loading ? null : _load,
          ),
        ]),
      ),
      if (_loading) const LinearProgressIndicator(),
      Expanded(
        child: ListView.builder(
          itemCount: _channels.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(_channels[i]['name']!),
            onTap: () => Navigator.push(c, MaterialPageRoute(
              builder: (_) => Player(
                title: _channels[i]['name']!,
                url: _channels[i]['url']!,
              ),
            )),
          ),
        ),
      ),
    ]),
  );
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
    _start();
  }

  Future<void> _start() async {
    try {
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
    appBar: AppBar(title: Text(widget.title)),
    backgroundColor: Colors.black,
    body: Center(
      child: _error != null
        ? Text(_error!, style: const TextStyle(color: Colors.white))
        : _ctrl != null && _ctrl!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!))
          : const CircularProgressIndicator(),
    ),
  );
}
