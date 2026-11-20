import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('waqi_token');
}

Future<Map<String, dynamic>> fetchAqi(String city) async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    throw Exception('API token not found');
  }

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
  final _cityController = TextEditingController();
  final _tokenController = TextEditingController();

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
    final token = prefs.getString('waqi_token');

    if (last != null && token != null && token.isNotEmpty) {
      _cityController.text = last;

      if (!mounted) return;

      setState(() => _future = _load(last));
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waqi_token', token);

    _tokenController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar (
      const SnackBar(content: Text('API token saved')),
    );
  }

  void _search() {
    final city = _cityController.text.trim();
    
    if (city.isEmpty) return;
    
    setState(() {
      _future = _load(city);
    });
  }

  String _category(int aqi) {
    if (aqi <= 50) return 'Baik';
    if (aqi <= 100) return 'Sedang';
    if (aqi <= 150) return 'Tidak sehat untuk kelompok sensitif';
    if (aqi <= 200) return 'Tidak sehat';
    if (aqi <= 300) return 'Sangat tidak sehat';
    return 'Berbahaya';
  }

  Color _color(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return const Color.fromARGB(255, 255, 157, 0);
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
              controller: _tokenController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'WAQI API Token',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _saveToken,
              child: const Text('Save token'),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Nama kota'),
              onSubmitted: (_) => _search(),
            ),

            const SizedBox(height: 8),
            ElevatedButton(onPressed: _search, child: const Text('Cari')),
            const SizedBox(height: 24),
            if (_future == null) ...[
              const Text('Cari kota untuk melihat AQI'),
              const Text('Kadang kota yang di-return tidak sesuai dgn yg dicari 🙏'),
            ]
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

  @override
  void dispose() {
    _cityController.dispose();
    _tokenController.dispose();
    super.dispose();
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