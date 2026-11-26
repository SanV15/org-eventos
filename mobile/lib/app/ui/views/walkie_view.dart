import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/walkie_controller.dart';
import '../../controllers/auth_controller.dart';
import 'main_view.dart';

class WalkieView extends StatefulWidget {
  const WalkieView({super.key});

  @override
  State<WalkieView> createState() => _WalkieViewState();
}

class _WalkieViewState extends State<WalkieView>
    with SingleTickerProviderStateMixin {
  final WalkieController controller = Get.find<WalkieController>();
  final AuthController authCtrl = Get.find<AuthController>();
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1218),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Get.find<MainNavigationController>().abrirMenu(),
        ),
        title: const Text(
          'Canal de Radio',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.4,
          ),
        ),
        backgroundColor: const Color(0xFF161B24),
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                SizedBox(width: 6),
                Text(
                  'EN LÍNEA',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final isRecording = controller.isRecording.value;
          final isPlaying = controller.isPlaying.value;
          final emisor = controller.emisorActual.value;
          final operador = authCtrl.nombreUsuario.value.isNotEmpty
              ? authCtrl.nombreUsuario.value
              : controller.nombreUsuario.value;

          // Controlar la animación de palpitación según el estado
          if (isRecording) {
            if (!_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            }
          } else {
            if (_pulseController.isAnimating) {
              _pulseController.stop();
              _pulseController.reset();
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // 1. TARJETA DE FRECUENCIA / CANAL Y OPERADOR
                _buildTarjetaCanal(operador),

                const SizedBox(height: 18),

                // 2. CONSOLA DE AUDIO ENTRANTE / ESTADO (ESTILO HEYTELL)
                _buildConsolaEmisor(isRecording, isPlaying, emisor),

                const Spacer(),

                // 3. BOTÓN CENTRAL PUSH-TO-TALK (PTT)
                _buildBotonPTT(isRecording, isPlaying),

                const Spacer(),

                // 4. INDICADOR INFERIOR DE ACCIÓN
                _buildPieInstruccion(isRecording, isPlaying),
                const SizedBox(height: 10),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTarjetaCanal(String operador) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cell_tower_rounded,
              color: Colors.blueAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRECUENCIA EVENTO #${controller.idEventoActual.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Operador: $operador',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (authCtrl.rolUsuario.value.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Text(
                authCtrl.rolUsuario.value,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsolaEmisor(bool isRecording, bool isPlaying, String emisor) {
    Color colorAcento = Colors.white38;
    Color colorFondo = const Color(0xFF161B24);
    String etiqueta = 'ESTADO DEL CANAL';
    String titulo = 'Canal libre • En espera';
    String subtitulo = 'Listo para recibir o enviar audio';
    IconData icono = Icons.headset_mic_outlined;

    if (isPlaying) {
      colorAcento = Colors.greenAccent;
      colorFondo = Colors.greenAccent.withOpacity(0.08);
      etiqueta = 'AUDIO ENTRANTE DE';
      titulo = emisor.isNotEmpty ? emisor : 'Compañero en campo';
      subtitulo = 'Reproduciendo mensaje de voz en vivo...';
      icono = Icons.volume_up_rounded;
    } else if (isRecording) {
      colorAcento = Colors.redAccent;
      colorFondo = Colors.redAccent.withOpacity(0.08);
      etiqueta = 'TRANSMITIENDO AL AIRE';
      titulo = 'Tu voz se escucha en el canal';
      subtitulo = 'Suelta el botón al terminar de hablar';
      icono = Icons.mic_rounded;
    }

    final inicialEmisor = (isPlaying && emisor.isNotEmpty)
        ? emisor[0].toUpperCase()
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isPlaying || isRecording)
              ? colorAcento.withOpacity(0.7)
              : Colors.white10,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorAcento.withOpacity(0.18),
            child: inicialEmisor.isNotEmpty
                ? Text(
                    inicialEmisor,
                    style: TextStyle(
                      color: colorAcento,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  )
                : Icon(icono, color: colorAcento, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: TextStyle(
                    color: colorAcento,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPTT(bool isRecording, bool isPlaying) {
    final Color estadoColor = isRecording
        ? Colors.redAccent
        : (isPlaying ? Colors.greenAccent : Colors.blueAccent);

    return GestureDetector(
      onLongPressStart: (_) {
        // Bloqueo: no permite hablar si alguien más está transmitiendo
        if (!isPlaying) {
          HapticFeedback.mediumImpact();
          controller.iniciarGrabacion();
        }
      },
      onLongPressEnd: (_) {
        if (isRecording) {
          HapticFeedback.lightImpact();
          controller.finalizarYTransmitir();
        }
      },
      onLongPressCancel: () {
        if (isRecording) {
          controller.finalizarYTransmitir();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final factor = isRecording ? _scaleAnimation.value : 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Aro exterior fijo tipo radar
              Container(
                width: 235,
                height: 235,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: estadoColor.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
              ),

              // Aro exterior pulsante (solo al transmitir)
              if (isRecording)
                Transform.scale(
                  scale: factor * 1.15,
                  child: Container(
                    width: 195,
                    height: 195,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.22),
                    ),
                  ),
                ),

              // Botón central principal
              Transform.scale(
                scale: factor,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPlaying
                          ? [const Color(0xFF1B5E20), const Color(0xFF0D3311)]
                          : (isRecording
                                ? [
                                    const Color(0xFFFF5252),
                                    const Color(0xFFB71C1C),
                                  ]
                                : [
                                    const Color(0xFF252D3D),
                                    const Color(0xFF161B24),
                                  ]),
                    ),
                    border: Border.all(
                      color: estadoColor.withOpacity(
                        isRecording || isPlaying ? 0.8 : 0.35,
                      ),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: estadoColor.withOpacity(
                          isRecording ? 0.55 : 0.2,
                        ),
                        blurRadius: isRecording ? 32 : 18,
                        spreadRadius: isRecording ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.graphic_eq_rounded
                            : (isRecording
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded),
                        size: 72,
                        color: isPlaying ? Colors.greenAccent : Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPlaying
                            ? 'ESCUCHANDO'
                            : (isRecording ? 'AL AIRE' : 'PTT'),
                        style: TextStyle(
                          color: isPlaying
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieInstruccion(bool isRecording, bool isPlaying) {
    final Color colorTexto = isRecording
        ? Colors.redAccent
        : (isPlaying ? Colors.greenAccent : Colors.white60);

    final String mensaje = isRecording
        ? 'SUELTA PARA ENVIAR'
        : (isPlaying
              ? 'ESPERA A QUE TERMINE LA TRANSMISIÓN'
              : 'MANTÉN PRESIONADO PARA HABLAR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B24),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecording
                ? Icons.fiber_manual_record
                : (isPlaying ? Icons.lock_outline : Icons.touch_app_outlined),
            size: 16,
            color: colorTexto,
          ),
          const SizedBox(width: 8),
          Text(
            mensaje,
            style: TextStyle(
              color: colorTexto,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}
