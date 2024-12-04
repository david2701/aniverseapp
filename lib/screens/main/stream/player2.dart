import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DualAirplayTestScreen extends StatefulWidget {
  const DualAirplayTestScreen({super.key});

  @override
  State<DualAirplayTestScreen> createState() => _DualAirplayTestScreenState();
}

class _DualAirplayTestScreenState extends State<DualAirplayTestScreen> {
  bool _isLoading = false;
  String? _videoUrl;
  String? _errorMessage;
  bool _isAirplayActive = false;
  bool _isVideo1 = true; // Para controlar qué video está activo

  Future<void> _fetchVideoData(bool isVideo1) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = isVideo1
          ? 'https://aniwatch-api-instance.vercel.app/api/v2/hianime/episode/sources?animeEpisodeId=ranma-1-2-19335?ep=128452&server=hd-2&category=sub'
          : 'https://aniwatch-api-instance.vercel.app/api/v2/hianime/episode/sources?animeEpisodeId=dandadan-19319?ep=128368?ep=1&server=hd-1&category=sub';

      final response = await http.get(Uri.parse(url));
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data']?['sources']?.isNotEmpty) {
          setState(() {
            _videoUrl = data['data']['sources'][0]['url'];
            _isVideo1 = isVideo1;
          });
          debugPrint('Video URL cargada: $_videoUrl');
        } else {
          throw 'No se encontraron fuentes de video';
        }
      } else {
        throw 'Error HTTP: ${response.statusCode}';
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        title: Text(_isVideo1 ? 'Video con Audios' : 'Video con Subtítulos'),
        actions: [
          IconButton(
            icon: Icon(_isAirplayActive ? Icons.airplay : Icons.airplay_outlined),
            onPressed: () {
              setState(() => _isAirplayActive = !_isAirplayActive);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Botones de selección
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVideo1 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () => _fetchVideoData(true),
                    child: const Text('Video con\nAudios'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isVideo1 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () => _fetchVideoData(false),
                    child: const Text('Video con\nSubtítulos'),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_videoUrl == null) {
      return const Center(
        child: Text(
          'Selecciona un video para probar',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  FlutterAVPlayerView(
                    urlString: _videoUrl,
                  ),
                  const Positioned(
                    top: 20,
                    right: 20,
                    child: AirPlayRoutePickerView(
                      tintColor: Colors.white,
                      activeTintColor: Colors.blue,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Info de depuración
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo: ${_isVideo1 ? "Audio múltiple" : "Con subtítulos"}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'AirPlay: ${_isAirplayActive ? "Activo" : "Inactivo"}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}