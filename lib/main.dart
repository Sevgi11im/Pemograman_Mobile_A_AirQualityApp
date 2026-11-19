import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String token = 'TOKEN';

Future<Map<String, dynamic>> fetchAqi(String city) async {
  final url = Uri.parse('https://api.waqi.info/feed/$city/?token=$token');
  final res = await http.get(url);
  final json = jsonDecode(res.body);
    if (json['status'] != 'ok') {
      throw Exception('City not found');
    }
    return json['data'];
}

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  Future<Map<String, dynamic>>? _future;
  
  @override
  void initState() {
    super.initState();
    _loadLastCity();
    }

  Future<Map<String, dynamic>> _load(String city) async {
    final data = await fetchAqi(city);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);
    return data;
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_city');
    if (last != null) {
      _controller.text = last;
      setState(() => _future = _load(last));
    }
  }

  void _search() {
    final city = _controller.text.trim();
    if (city.isEmpty) return;
    setState(() => _future = _load(city));
  }

  String _category(int aqi) {
    if (aqi <= 50) return 'Baik';
    if (aqi <= 100) return 'Sedang';
    if (aqi <= 150) return 'Tidak sehat untuk kelompok sensitif';
    if (aqi <= 200) return 'Tidka sehat';
    if (aqi <= 300) return 'Sangat tidak sehat';
    return 'Berbahaya';
  }

  Color _color(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Air Quality')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Nama kota'),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _search, child: const Text('Cari')),
            const SizedBox(height: 24),
            if (_future == null)
              const Text('Cari kota untuk melihat AQI')
            else
              FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // loading
                  }
                  if (snap.hasError) {
                    return Text('Error: ${snap.error}'); // error
                  }
                  final data = snap.data!; // sukses
                  final aqi = int.tryParse('${data['aqi']}') ?? 0;
                  return Column(
                    children: [
                      Text(data['city']['name'].toString()),
                      Text('$aqi',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: _color(aqi))),
                      Text(_category(aqi)),
                    ],
                  );
                },
              ),
          ], // children
        ),
      ),
    );
  }
}



// NGE-TEST DOANG INI MAH
// void main() async {
//   final data =  await fetchAqi('Jakarta');

//   print('Waktu/Tanggal: ${data['time']['s'] ?? 'N/A'}');
//   print('Lokasi: ${data['city']['name']}');
//   print('AQI: ${data['aqi']}');
//   print('Dominan Polutan: ${data['dominentpol']}');
// }