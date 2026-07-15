///lib/virtual_chef_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/voice_service.dart';
import 'services/clarifai_service.dart';

class VirtualChefPage extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const VirtualChefPage({super.key, required this.recipeData});

  @override
  State<VirtualChefPage> createState() => _VirtualChefPageState();
}

class _VirtualChefPageState extends State<VirtualChefPage> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();

  List<String> _pasos = [];
  int _pasoActual = 0;
  bool _estaEscuchando = false;
  String _ultimaFraseEscuchada = "";
  String _estadoAsistente = "Inicializando...";

  bool _mostrarTooltip = true;
  Timer? _tooltipTimer;

  // --- DETECTOR HÍBRIDO SEGURO: Escáner (IA) e Historial (Supabase) ---
  String get _nombrePlato {
    Map<String, dynamic> data = widget.recipeData;
    if (widget.recipeData.containsKey('recetas') && widget.recipeData['recetas'] is Map) {
      data = widget.recipeData['recetas'];
    }
    return data['plato'] ??
        data['titulo_receta'] ??
        data['nombre'] ??
        data['title'] ??
        data['name'] ??
        "tu receta";
  }

  // --- PALETA DE COLORES ---
  final Color primaryColor = const Color(0xFF016782);
  final Color primaryDim = const Color(0xFF005B73);
  final Color primaryContainer = const Color(0xFF94DFFE);
  final Color onPrimary = const Color(0xFFF2FAFF);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color surfaceContainer = const Color(0xFFEAEFF2);
  final Color onSurface = const Color(0xFF2C3437);
  final Color onSurfaceVariant = const Color(0xFF596064);
  final Color inverseSurface = const Color(0xFF0B0F10);
  final Color outlineVariant = const Color(0xFFACB3B7);

  late List<AnimationController> _animationControllers;

  @override
  void initState() {
    super.initState();
    _prepararPasosDeReceta();
    _inicializarAsistenteVoz();
    _inicializarAnimacionesEcualizador();

    _tooltipTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _mostrarTooltip = false);
    });
  }

  void _inicializarAnimacionesEcualizador() {
    final delays = [100, 300, 500, 200, 400, 600];
    _animationControllers = List.generate(6, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: delays[index]), () {
        if (mounted && _estaEscuchando) controller.repeat(reverse: true);
      });
      return controller;
    });
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _voiceService.detenerTodo();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepararPasosDeReceta() {
    Map<String, dynamic> data = widget.recipeData;
    if (widget.recipeData.containsKey('recetas') && widget.recipeData['recetas'] is Map) {
      data = widget.recipeData['recetas'];
    }

    var instrucciones = data['pasos'] ?? data['instrucciones_json'] ?? data['instrucciones'];

    if (instrucciones == null) {
      _pasos = ["No se encontraron instrucciones en esta receta."];
      return;
    }

    if (instrucciones is List) {
      _pasos = instrucciones.map((e) => e.toString()).toList();
    } else if (instrucciones is Map) {
      var subLista = instrucciones['pasos'] ?? instrucciones['steps'];
      if (subLista is List) {
        _pasos = subLista.map((e) => e.toString()).toList();
      } else {
        _pasos = [instrucciones.toString()];
      }
    } else if (instrucciones is String && instrucciones.trim().isNotEmpty) {
      if (instrucciones.contains('\n')) {
        _pasos = instrucciones.split('\n').where((s) => s.trim().isNotEmpty).toList();
      } else {
        _pasos = [instrucciones];
      }
    } else {
      _pasos = ["Modo lectura listo. Presione siguiente para comenzar."];
    }
  }

  Future<void> _inicializarAsistenteVoz() async {
    try {
      await _voiceService.initStt((status) {
        if (!mounted) return;
        setState(() {
          if (status == 'listening') {
            _estaEscuchando = true;
            _estadoAsistente = "Escuchando...";
            for (var c in _animationControllers) c.repeat(reverse: true);
          } else {
            _estaEscuchando = false;
            for (var c in _animationControllers) c.stop();
            if (!_voiceService.isSpeaking) _estadoAsistente = "Modo Manos Libres";
          }
        });
      });

      await _voiceService.initTts(() {
        // El VoiceService ya incluye el delay de 600ms antes de llamar aquí
        _activarEscuchaActiva();
      });

      _emitirPasoActual(esInicio: true);
      // NO llamamos _activarEscuchaActiva() aquí: lo hace el callback de initTts
      // cuando el TTS termina. Evitamos el race condition.

    } catch (e) {
      debugPrint("Error crítico en inicialización de hardware de voz: $e");
      if (mounted) setState(() => _estadoAsistente = "Voz no disponible");
    }
  }

  void _emitirPasoActual({bool esInicio = false}) {
    try {
      if (_pasos.isEmpty) return;
      String textoBase = _pasos[_pasoActual];
      String fraseHumana = textoBase;

      if (esInicio) {
        final user = Supabase.instance.client.auth.currentUser;
        String nombreCompleto = user?.userMetadata?['name'] ??
            user?.userMetadata?['full_name'] ??
            user?.userMetadata?['first_name'] ??
            "Chef";
        String primerNombre = nombreCompleto.trim().split(' ').first;
        if (primerNombre.isEmpty) primerNombre = "Chef";
        fraseHumana = "¡Excelente $primerNombre! Vamos a preparar $_nombrePlato. El primer paso es: $textoBase.";
      }

      if (!mounted) return;
      setState(() {
        _estadoAsistente = "Hablando...";
        _estaEscuchando = false;
      });

      _voiceService.hablar(fraseHumana);
    } catch (e) {
      debugPrint("Error TTS: $e");
    }
  }

  void _activarEscuchaActiva() {
    if (!mounted) return;
    try {
      _voiceService.escucharPermanente(
        onResult: (fraseRecibida) {
          _procesarComandoVoz(fraseRecibida);
        },
      );
    } catch (e) {
      debugPrint("Escucha activa no disponible: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // FIX PRINCIPAL: Filtro de wake word más robusto y amplio
  // ---------------------------------------------------------------------------
  void _procesarComandoVoz(String frase) {
    if (!mounted) return;

    final String comando = frase.toLowerCase().trim();

    // Palabras de navegación directa — siempre se procesan sin wake word
    final bool esSiguiente = comando.contains("siguiente") ||
        comando.contains("avanzar") ||
        comando.contains("adelante") ||
        comando.contains("próximo");

    final bool esAnterior = comando.contains("anterior") ||
        comando.contains("regresar") ||
        comando.contains("atrás") ||
        comando.contains("volver");

    final bool esRepetir = comando.contains("repetir") ||
        comando.contains("repite") ||
        comando.contains("de nuevo") ||
        comando.contains("otra vez");

    // Wake words — activan pregunta al asistente
    final bool llamoAlAsistente = comando.contains("epicuria") ||
        comando.contains("epicurÍa") ||
        comando.contains("chef") ||
        comando.contains("asistente") ||
        comando.contains("ayuda");

    // FIX: Si no hay ni navegación ni wake word, ignoramos — ruido ambiente
    if (!esSiguiente && !esAnterior && !esRepetir && !llamoAlAsistente) {
      debugPrint("Ruido de fondo ignorado: $frase");
      return;
    }

    setState(() => _ultimaFraseEscuchada = frase);

    if (esSiguiente) {
      if (_pasoActual < _pasos.length - 1) {
        setState(() => _pasoActual++);
        _emitirPasoActual();
      } else {
        _voiceService.hablar("Ya estás en el último paso. ¡Buen provecho!");
      }
    } else if (esAnterior) {
      if (_pasoActual > 0) {
        setState(() => _pasoActual--);
        _emitirPasoActual();
      } else {
        _voiceService.hablar("Ya estás en el primer paso.");
      }
    } else if (esRepetir) {
      _emitirPasoActual();
    } else if (llamoAlAsistente) {
      _resolverDudaConIA(frase);
    }
  }

  void _resolverDudaConIA(String duda) async {
    if (!mounted) return;
    setState(() {
      _estadoAsistente = "Pensando...";
      _estaEscuchando = false;
    });
    String respuestaIA = await ClarifaiService.responderDudaChef("", duda);
    _voiceService.hablar(respuestaIA);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildEtherealBlobs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImmersiveHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularProgress(),
                        const SizedBox(height: 48),
                        _buildInstructionHierarchy(),
                        const SizedBox(height: 64),
                        _buildActiveVoiceFeedback(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationControls(),
              ],
            ),
          ),
          if (_mostrarTooltip) _buildContextualTooltip(),
        ],
      ),
    );
  }

  Widget _buildEtherealBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -100,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryContainer.withValues(alpha: 0.15)),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent)),
          ),
        ),
      ],
    );
  }

  Widget _buildImmersiveHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                  child: Icon(Icons.close_rounded, color: primaryColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Modo chef virtual", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: primaryColor)),
                  Text(_nombrePlato, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant)),
                ],
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(99), border: Border.all(color: primaryColor.withValues(alpha: 0.1)), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text("12:45", style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCircularProgress() {
    double totalPasos = _pasos.isEmpty ? 1 : _pasos.length.toDouble();
    double fraccionProgreso = (_pasoActual + 1) / totalPasos;
    String numeroPaso = _pasos.isEmpty ? "00" : (_pasoActual + 1).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100, height: 100,
          child: Stack(
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: fraccionProgreso,
                  strokeWidth: 4,
                  backgroundColor: primaryContainer.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Center(
                child: Text(numeroPaso, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor)),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInstructionHierarchy() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _pasos.isEmpty ? "Cargando pasos..." : _pasos[_pasoActual],
        key: ValueKey<int>(_pasoActual),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildActiveVoiceFeedback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _animationControllers[index],
                builder: (context, child) {
                  double animatedHeight = 12.0 + (_animationControllers[index].value * 20.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: _estaEscuchando ? animatedHeight : 12.0,
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(99)),
                  );
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), border: Border.all(color: primaryContainer.withValues(alpha: 0.4)), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                  children: [
                    TextSpan(text: _estaEscuchando && _ultimaFraseEscuchada.isNotEmpty ? 'Escuchando... ' : '$_estadoAsistente '),
                    if (_estaEscuchando)
                      TextSpan(
                        text: '"${_ultimaFraseEscuchada.isNotEmpty ? _ultimaFraseEscuchada : 'Siguiente'}"',
                        style: TextStyle(color: primaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildContextualTooltip() {
    return Positioned(
      bottom: 144, left: 0, right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _mostrarTooltip ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.bolt_rounded, size: 18, color: primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontFamily: 'Manrope', fontSize: 11, color: onSurface, height: 1.3),
                          children: [
                            const TextSpan(text: 'Di '),
                            TextSpan(text: '"siguiente" o "EpicurIA, ayúdame con..."', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' para controlar sin tocar la pantalla.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: _pasoActual > 0 ? () {
                  setState(() => _pasoActual--);
                  _emitirPasoActual();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: onSurfaceVariant,
                  elevation: 1,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: primaryContainer.withValues(alpha: 0.3))),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left_rounded, size: 24, color: onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text("ANTERIOR", style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 56, height: 56,
            child: ElevatedButton(
              onPressed: () => _activarEscuchaActiva(),
              style: ElevatedButton.styleFrom(backgroundColor: surfaceContainer, foregroundColor: onSurfaceVariant, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: Icon(Icons.keyboard_rounded, size: 20, color: onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 15,
            child: SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: _pasoActual < _pasos.length - 1 ? () {
                  setState(() => _pasoActual++);
                  _emitirPasoActual();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimary,
                  elevation: 12,
                  shadowColor: primaryColor.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_right_rounded, size: 24, color: onPrimary),
                    const SizedBox(height: 4),
                    Text("SIGUIENTE", style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: onPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}