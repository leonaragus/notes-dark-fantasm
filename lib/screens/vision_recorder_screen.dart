import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/cyber_theme.dart';

class VisionRecorderScreen extends StatefulWidget {
  final String assetName;
  final bool isRoom360; // Indica si es una grabación de habitación completa
  final bool isAnchoringOnly; // Nuevo: Para el Paso Cero (Caminata + Wi-Fi)

  const VisionRecorderScreen({
    Key? key, 
    required this.assetName,
    this.isRoom360 = false,
    this.isAnchoringOnly = false,
  }) : super(key: key);

  @override
  _VisionRecorderScreenState createState() => _VisionRecorderScreenState();
}

class _VisionRecorderScreenState extends State<VisionRecorderScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _secondsRemaining = 10; // 10 segundos para 360
  Timer? _timer;
  
  // Datos de giroscopio para alineación
  final List<double> _gyroData = [];
  StreamSubscription? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    if (widget.isRoom360) {
      _secondsRemaining = 15; // Más tiempo para una habitación completa
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      
      // Iniciar captura de giroscopio
      _gyroData.clear();
      _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (_isRecording) {
          // Guardamos la rotación en el eje Y (horizontal) para el 360
          _gyroData.add(event.y);
        }
      });

      setState(() {
        _isRecording = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsRemaining > 1) {
            _secondsRemaining--;
          } else {
            _stopRecording();
          }
        });
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    _gyroSubscription?.cancel();
    if (!_isRecording) return;

    try {
      String? photoPath;
      XFile? video;

      if (widget.isAnchoringOnly) {
        // En el Paso Cero, capturamos una foto final del elemento
        final photo = await _controller!.takePicture();
        photoPath = photo.path;
      } else {
        video = await _controller!.stopVideoRecording();
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });
      }

      // Procesar datos (aquí se vincularía el giroscopio con el modelo)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        if (widget.isAnchoringOnly) {
          Navigator.pop(context, {
            'photoPath': photoPath,
            'gyroData': _gyroData,
          }); // Devuelve la foto y los datos de anclaje
        } else {
          Navigator.pop(context, {
            'videoPath': video?.path,
            'gyroData': _gyroData,
          });
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          
          // HUD de Grabación (Color según modo)
          if (_isRecording)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonPurple, 
                  width: 4
                ),
              ),
            ),

          // Guía de Giro / Paso Cero
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && !_isProcessing)
                  Icon(
                    widget.isAnchoringOnly ? Icons.directions_walk : Icons.sync, 
                    color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonCyan, 
                    size: 80
                  ),
                const SizedBox(height: 20),
                if (_isRecording)
                  Text(
                    widget.isAnchoringOnly ? 'CALIBRANDO ANCLA REAL...' : 'GIRÁ 360° LENTAMENTE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonPurple, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2
                    ),
                  ),
              ],
            ),
          ),

          // Contador
          if (_isRecording)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '$_secondsRemaining',
                  style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonGreen),
                    const SizedBox(height: 20),
                    Text(
                      widget.isAnchoringOnly 
                        ? 'SINCRONIZANDO ANCLA FÍSICA...' 
                        : (widget.isRoom360 ? 'VINCULANDO MODELO 3D...' : 'PROCESANDO ADN VISUAL...'),
                      style: TextStyle(
                        color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonGreen, 
                        letterSpacing: 2, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón de Inicio
          if (!_isRecording && !_isProcessing)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonCyan,
                    side: BorderSide(color: widget.isAnchoringOnly ? Colors.redAccent : CyberTheme.neonCyan, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    widget.isAnchoringOnly 
                      ? 'INICIAR CALIBRACIÓN' 
                      : (widget.isRoom360 ? 'INICIAR ESCANEO 360' : 'INICIAR CAPTURA'),
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
