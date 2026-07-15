///lib/services/voice_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  // Usaremos audioplayers para reproducir la voz que nos envía ElevenLabs
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _sttDisponible = false;
  bool _isSpeaking = false;
  bool _debeEscucharContinuo = false;

  Function(String)? _onResultCallback;
  Function()? _onSpeechCompleteCallback;

  bool get isSpeaking => _isSpeaking;

  Future<void> initTts(Function() onSpeechComplete) async {
    _onSpeechCompleteCallback = onSpeechComplete;

    // CONTROL CRÍTICO: Cuando el audio de ElevenLabs termina, volvemos a escuchar
    _audioPlayer.onPlayerComplete.listen((event) {
      _isSpeaking = false;
      if (_onSpeechCompleteCallback != null) {
        _onSpeechCompleteCallback!();
      }
    });
  }

  Future<bool> initStt(Function(String) onStatusChange) async {
    if (!_sttDisponible) {
      _sttDisponible = await _speechToText.initialize(
        onError: (val) {
          debugPrint('Error STT: $val');
          _reintentarEscuchaSiEsNecesario();
        },
        onStatus: (val) {
          debugPrint('Estado STT en Servicio: $val');
          onStatusChange(val);
          if ((val == 'done' || val == 'notListening') && _debeEscucharContinuo && !_isSpeaking) {
            _reintentarEscuchaSiEsNecesario();
          }
        },
      );
    }
    return _sttDisponible;
  }

  void _reintentarEscuchaSiEsNecesario() {
    if (_debeEscucharContinuo && !_isSpeaking && !_speechToText.isListening) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_debeEscucharContinuo && !_isSpeaking && !_speechToText.isListening) {
          _activarMecanismoEscucha();
        }
      });
    }
  }

  // --- NUEVA CONEXIÓN A ELEVENLABS ---
  Future<void> hablar(String texto) async {
    _debeEscucharContinuo = false;
    await _speechToText.stop();
    await _audioPlayer.stop();

    _isSpeaking = true;

    try {
      // Obtenemos las claves del .env
      final apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
      final voiceId = dotenv.env['ELEVENLABS_VOICE_ID'] ?? '';

      if (apiKey.isEmpty || voiceId.isEmpty) {
        debugPrint('Error: Faltan credenciales de ElevenLabs en el .env');
        _isSpeaking = false;
        _onSpeechCompleteCallback?.call();
        return;
      }

      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');

      // Enviamos el texto a la nube
      final response = await http.post(
        url,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({
          "text": texto,
          "model_id": "eleven_multilingual_v2", // El mejor modelo para español
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
          }
        }),
      );

      if (response.statusCode == 200) {
        // Reproducimos el audio HD directamente desde la respuesta
        Uint8List audioBytes = response.bodyBytes;
        await _audioPlayer.play(BytesSource(audioBytes));
      } else {
        debugPrint('Error en ElevenLabs: ${response.statusCode} - ${response.body}');
        _isSpeaking = false;
        _onSpeechCompleteCallback?.call();
      }
    } catch (e) {
      debugPrint('Error de conexión: $e');
      _isSpeaking = false;
      _onSpeechCompleteCallback?.call();
    }
  }

  Future<void> escucharPermanente({required Function(String) onResult}) async {
    _onResultCallback = onResult;
    _debeEscucharContinuo = true;
    if (_isSpeaking) return;
    await _activarMecanismoEscucha();
  }

  Future<void> _activarMecanismoEscucha() async {
    try {
      // Intentamos inicializar el micrófono de forma segura
      bool disponible = await _speechToText.initialize();
      if (disponible && !_speechToText.isListening) {
        await _speechToText.listen(
          localeId: "es_MX",
          onResult: (result) {
            // Solo queremos procesar cuando el usuario termina de hablar
            if (result.finalResult) {
              _onResultCallback?.call(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5), // Damos más tiempo para que el usuario tome aire sin cortar la frase
          cancelOnError: false,  // CRÍTICO: Evita que el micrófono se apague si no entiende algo
          partialResults: false, // CRÍTICO: No enviamos texto incompleto a la interfaz
        );
      }
    } catch (e) {
      // Si el dispositivo no soporta voz (ej. Emulador), atrapamos el error aquí
      debugPrint('Error crítico al inicializar el micrófono (STT): $e');
      _debeEscucharContinuo = false; // Apagamos el bucle para que no colapse
    }
  }

  Future<void> detenerTodo() async {
    _debeEscucharContinuo = false;
    await _speechToText.stop();
    await _audioPlayer.stop();
  }
}