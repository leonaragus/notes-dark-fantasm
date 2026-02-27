import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room_package.dart';
import '../models/room_models.dart';
import 'room_setup_flow.dart';
import 'note_viewer.dart';

class RecordingModuleScreen extends StatefulWidget {
  final RoomConfig config;
  final List<FurnitureAsset> assets;
  final Room? existingRoom; // Sala existente para refuerzo de datos

  const RecordingModuleScreen({
    Key? key,
    required this.config,
    required this.assets,
    this.existingRoom,
  }) : super(key: key);

  @override
  _RecordingModuleScreenState createState() => _RecordingModuleScreenState();
}

class _RecordingModuleScreenState extends State<RecordingModuleScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _preCheckPassed = false;
  String _statusMessage = 'Iniciando sensores...';
  
  // Datos de sensores
  final List<GyroData> _gyroBuffer = [];
  final List<WifiFingerprint> _wifiBuffer = [];
  StreamSubscription? _gyroSub;
  StreamSubscription? _userAccelSub;
  Timer? _wifiTimer;
  int? _lastWifiRssi; 
  int _lastGyroTimestamp = 0;

  // Emparejamiento Silencioso (Background Tracking)
  bool _isBackgroundTracking = false;
  int _stepCount = 0;
  double _distanceTraveled = 0.0;
  v.Vector3 _lastAccel = v.Vector3.zero();
  bool _isMoving = false;
  DateTime? _lastMoveTime;
  FurnitureAsset? _predictedFurniture;
  bool _showConfirmation = false;

  // Guías visuales
  double _currentRotationX = 0;
  double _currentRotationY = 0;
  double _rotationSpeed = 0;
  v.Vector3 _lastGyro = v.Vector3.zero();

  @override
  void initState() {
    super.initState();
    _initSensorsAndCamera();
    _startBackgroundTracking();
  }

  void _startBackgroundTracking() {
    _isBackgroundTracking = true;
    _stepCount = 0;
    _distanceTraveled = 0.0;
    _lastAccel = v.Vector3.zero();

    // 1. Conteo de pasos y detección de movimiento
    _userAccelSub = userAccelerometerEventStream().listen((event) {
      final currentAccel = v.Vector3(event.x, event.y, event.z);
      
      // Filtro simple para detectar movimiento
      double delta = (currentAccel - _lastAccel).length;
      bool movingNow = delta > 0.8;

      if (movingNow && !_isMoving) {
        _isMoving = true;
        _lastMoveTime = DateTime.now();
      } else if (!movingNow && _isMoving) {
        // Detección de parada suave (Lógica de 'Llegada')
        if (_lastMoveTime != null && 
            DateTime.now().difference(_lastMoveTime!).inMilliseconds > 1500) {
          _isMoving = false;
          _onUserArrived();
        }
      }

      // Conteo de pasos (basado en picos de aceleración en Z)
      if (currentAccel.z.abs() > 1.2 && _lastAccel.z.abs() <= 1.2) {
        if (mounted) {
          setState(() {
            _stepCount++;
            _distanceTraveled += 0.7; // Aproximación: 0.7m por paso
          });
        }
      }

      _lastAccel = currentAccel;
    });

    // 2. Registro de RSSI Wi-Fi en segundo plano
    _wifiTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        final results = await WiFiScan.instance.getScannedResults();
        if (results.isNotEmpty) {
          if (mounted) {
            setState(() {
              _lastWifiRssi = results.first.level;
            });
          }
          // El Fingerprinting ayuda a confirmar la sala
          print('DEBUG: [BG SCAN] Wi-Fi RSSI: $_lastWifiRssi dBm');
          
          // Detección de Entrada (Persistencia Fantasmagórica)
          // Si el RSSI es fuerte (>-60), asumimos que estamos en la sala conocida
          if (_lastWifiRssi != null && _lastWifiRssi! > -60 && !_showConfirmation && !_isRecording) {
            _triggerRoomEntry();
          }
        }
      }
    });
  }

  void _triggerRoomEntry() {
    // 1. Vibración Suave
    HapticFeedback.heavyImpact();
    
    // 2. Notificación Visual (Opcional, pero para feedback del usuario)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sala Identificada: Persistencia Fantasmagórica Activada'),
        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
        duration: const Duration(seconds: 2),
      ),
    );

    // 3. Abrir visor directamente con todas las notas flotando
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteViewerScreen(
          package: RoomPackage(
            roomId: 'room_detected',
            roomName: widget.config.type,
            videoPath: '', // En una app real usaríamos el video previo o streaming
            rotationData: [],
            wifiMap: [],
            notes: [], // Aquí vendrían las notas reales de la DB
            furnitureLayout: widget.assets.map((e) => e.toJson()).toList(),
          ),
          assets: widget.assets,
        ),
      ),
    );
  }

  void _onUserArrived() {
    // Lógica de 'Llegada': El usuario se detuvo. Predecimos el mueble.
    final predicted = _predictFurniture();
    if (predicted != null) {
      if (mounted) {
        setState(() {
          _predictedFurniture = predicted;
          _showConfirmation = true;
        });
      }
    }
  }

  FurnitureAsset? _predictFurniture() {
    if (widget.assets.isEmpty) return null;

    // Predicción basada en distancia recorrida (simplificada)
    // En una app real, usaríamos una malla de navegación o SLAM
    double minDiff = double.infinity;
    FurnitureAsset? closest;

    for (var asset in widget.assets) {
      double distToAsset = asset.position.length;
      double diff = (distToAsset - _distanceTraveled).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = asset;
      }
    }
    return closest;
  }

  void _confirmFurniture(FurnitureAsset asset) {
    if (mounted) {
      setState(() {
        _showConfirmation = false;
      });
    }

    // Ajuste Automático del Espejo
    // Usamos la distancia real recorrida para corregir la posición 3D
    final correctedPosition = v.Vector3(
      asset.position.x,
      asset.position.y,
      _distanceTraveled, // Ajustamos profundidad basada en pasos
    );

    print('DEBUG: [ESPEJO AJUSTADO] Mueble: ${asset.name} | Nueva Pos: $correctedPosition');

    // Inmediatamente abrir editor de Ghost Notes
    _openGhostNoteEditor(asset);
  }

  void _openGhostNoteEditor(FurnitureAsset asset) {
    // Aquí disparamos la navegación o el bottom sheet del editor
    // Por ahora, simulamos el flujo hacia NoteViewer con el asset confirmado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteViewerScreen(
          package: RoomPackage(
            roomId: 'room_${DateTime.now().millisecondsSinceEpoch}',
            roomName: widget.config.type,
            videoPath: '', // Se llenará al grabar
            rotationData: [],
            wifiMap: [],
            furnitureLayout: widget.assets.map((a) => 
              a.id == asset.id ? a.copyWith(position: v.Vector3(a.position.x, a.position.y, _distanceTraveled)) : a
            ).map((e) => e.toJson()).toList(),
          ),
          assets: widget.assets,
          initialSelectedAssetId: asset.id, // Nueva propiedad para abrir editor directo
        ),
      ),
    );
  }

  Future<void> _initSensorsAndCamera() async {
    // 1. Pre-Check de Sensores
    final check = await SensorPreCheckService.runFullCheck();
    if (!check['ready']) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${check['errors'].join("\n")}';
          _preCheckPassed = false;
        });
      }
      return;
    }

    // 2. Inicializar Cámara
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _preCheckPassed = true;
        _isInitialized = true;
        _statusMessage = 'Sensores OK. Listo para grabar.';
      });
    }
  }

  void _startRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      
      // Iniciar captura dual de sensores
      _gyroBuffer.clear();
      _wifiBuffer.clear();
      _lastGyroTimestamp = 0;
      
      _gyroSub = gyroscopeEventStream().listen((event) {
        if (_isRecording) {
          final now = DateTime.now().millisecondsSinceEpoch;
          
          // Captura a ~30Hz (aprox cada 33ms)
          if (now - _lastGyroTimestamp >= 33) {
            _gyroBuffer.add(GyroData(event.x, event.y, event.z, now));
            _lastGyroTimestamp = now;
          }
          
          // Actualizar UI nivel de burbuja y velocidad
          if (mounted) {
            setState(() {
              _currentRotationX = event.x;
              _currentRotationY = event.y;
              
              // Cálculo de velocidad (magnitud)
              _rotationSpeed = (v.Vector3(event.x, event.y, event.z)).length;
            });
          }
        }
      });

      // Wi-Fi Fingerprinting cada 2 segundos con detección de oclusión
      _wifiTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_isRecording) {
          final canScan = await WiFiScan.instance.canStartScan();
          if (canScan == CanStartScan.yes) {
            await WiFiScan.instance.startScan();
            final results = await WiFiScan.instance.getScannedResults();
            final now = DateTime.now().millisecondsSinceEpoch;
            
            for (var r in results) {
              _wifiBuffer.add(WifiFingerprint(r.ssid, r.level, now));
              
              // Lógica de Oclusión: Detectar variación brusca (>15dBm)
              if (_lastWifiRssi != null) {
                int diff = (r.level - _lastWifiRssi!).abs();
                if (diff > 15) {
                  final nearestMueble = _findNearestMueble();
                  print('DEBUG: [OCLUSIÓN DETECTADA] Red: ${r.ssid} | Variación: ${diff}dBm | Mueble cercano: $nearestMueble');
                }
              }
              if (mounted) {
                setState(() {
                  _lastWifiRssi = r.level;
                });
              }
            }
          }
        }
      });

      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      print('Error al iniciar grabación: $e');
    }
  }

  String _findNearestMueble() {
    if (widget.assets.isEmpty) return 'Ninguno';
    
    // En una implementación real, usaríamos la rotación actual del giroscopio
    // para proyectar un rayo y ver qué mueble está en el campo visual.
    // Para esta prueba técnica, devolvemos el mueble con mayor volumen (oclusor probable).
    final voluminous = widget.assets.reduce((a, b) {
      double volA = a.dimensions.x * a.dimensions.y * a.dimensions.z;
      double volB = b.dimensions.x * b.dimensions.y * b.dimensions.z;
      return volA > volB ? a : b;
    });
    return voluminous.name;
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    final videoFile = await _cameraController!.stopVideoRecording();
    _gyroSub?.cancel();
    _wifiTimer?.cancel();

    if (mounted) {
      setState(() => _isRecording = false);
    }

    RoomPackage finalPackage;
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Anon';

    if (widget.existingRoom != null) {
      // --- LÓGICA DE REFUERZO DE DATOS (Calibración Colaborativa) ---
      print('DEBUG: [COLABORACIÓN] Reforzando sala ${widget.existingRoom!.id}');
      
      // Intentar cargar el paquete original para combinar
      final originalPkgJson = prefs.getString('package_${widget.existingRoom!.id}');
      RoomPackage? originalPkg;
      if (originalPkgJson != null) {
        originalPkg = RoomPackage.fromJson(jsonDecode(originalPkgJson));
      }

      // Combinar datos: Promediado simple o concatenación con limpieza
      // Por ahora concatenamos y marcamos al colaborador para aumentar precisión en el visor
      final combinedGyro = originalPkg != null 
          ? [...originalPkg.rotationData, ..._gyroBuffer]
          : List<GyroData>.from(_gyroBuffer);
          
      final combinedWifi = originalPkg != null
          ? [...originalPkg.wifiMap, ..._wifiBuffer]
          : List<WifiFingerprint>.from(_wifiBuffer);

      final collaborators = originalPkg != null
          ? {...originalPkg.collaboratorIds, userName}.toList()
          : [userName];

      finalPackage = RoomPackage(
        roomId: widget.existingRoom!.id,
        roomName: widget.config.type,
        videoPath: videoFile.path, // Usamos el video más reciente como referencia visual
        rotationData: combinedGyro,
        wifiMap: combinedWifi,
        furnitureLayout: widget.existingRoom!.assets.map((a) => a.toJson()).toList(),
        collaboratorIds: collaborators,
        targetSSID: widget.existingRoom!.targetSSID,
        targetRSSI: widget.existingRoom!.targetRSSI,
      );

      // Guardar paquete reforzado
      await prefs.setString('package_${widget.existingRoom!.id}', jsonEncode(finalPackage.toJson()));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡CALIBRACIÓN REFORZADA! La precisión del mapa ha aumentado.'),
          backgroundColor: Colors.purpleAccent,
        ),
      );
    } else {
      // Creación normal
      finalPackage = RoomPackage(
        roomId: 'room_${DateTime.now().millisecondsSinceEpoch}',
        roomName: widget.config.type,
        videoPath: videoFile.path,
        rotationData: List.from(_gyroBuffer),
        wifiMap: List.from(_wifiBuffer),
        furnitureLayout: widget.assets.map((a) => a.toJson()).toList(),
      );
    }

    // Navegar al ajuste fino (Offset)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FineTuningScreen(
          package: finalPackage,
          assets: widget.existingRoom?.assets ?? widget.assets,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _gyroSub?.cancel();
    _wifiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cámara Preview
          CameraPreview(_cameraController!),

          // 2. Overlay de Referencia (Wireframe 3D)
          _buildWireframeOverlay(),

          // 3. Guías Visuales (HUD)
          _buildHUD(),

          // 4. Controles
          _buildControls(),

          // 5. Interfaz de Confirmación Rápida
          if (_showConfirmation && _predictedFurniture != null)
            _buildConfirmationOverlay(),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.cyanAccent, size: 40),
                const SizedBox(height: 15),
                Text(
                  '¿Estás en la ${_predictedFurniture!.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Detectamos tu llegada tras ${_stepCount} pasos (${_distanceTraveled.toStringAsFixed(1)}m)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => _confirmFurniture(_predictedFurniture!),
                        child: const Text('SÍ, CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white54),
                      onPressed: _showFurnitureMenu,
                      tooltip: 'No es este',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFurnitureMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELECCIONAR MUEBLE',
              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: widget.assets.length,
              itemBuilder: (context, index) {
                final asset = widget.assets[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmFurniture(asset);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(Icons.Chair, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWireframeOverlay() {
    // Usamos el mueble principal para alinear (ej: Heladera en cocina, Cama en dormitorio)
    final mainAsset = widget.assets.isNotEmpty ? widget.assets.first : null;
    if (mainAsset == null) return const SizedBox();

    return IgnorePointer(
      child: Opacity(
        opacity: 0.4,
        child: cube.Cube(
          onSceneCreated: (scene) {
            scene.camera.position.setValues(0, 2, 5);
            scene.camera.target.setValues(0, 0, 0);
            
            final obj = cube.Object(
              fileName: mainAsset.modelPath ?? 'assets/cube.obj',
              scale: v.Vector3(1, 1, 1),
            );
            obj.mesh.color.setValues(0, 1, 1); // Cyan Wireframe color
            scene.world.add(obj);
          },
        ),
      ),
    );
  }

  Widget _buildHUD() {
    bool speedWarning = _rotationSpeed > 1.5;
    bool tiltWarning = _currentRotationX.abs() > 0.5;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(
                  label: 'VELOCIDAD',
                  color: speedWarning ? Colors.redAccent : Colors.greenAccent,
                  value: speedWarning ? 'MUY RÁPIDO' : 'OK',
                ),
                _StatusBadge(
                  label: 'INCLINACIÓN',
                  color: tiltWarning ? Colors.redAccent : Colors.greenAccent,
                  value: tiltWarning ? 'ALINEAR' : 'OK',
                ),
              ],
            ),
            const Spacer(),
            // Nivel de Burbuja
            _BubbleLevel(x: _currentRotationY, y: _currentRotationX),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: _isRecording ? Colors.redAccent : Colors.transparent,
            ),
            child: Center(
              child: _isRecording 
                ? const Icon(Icons.stop, color: Colors.white, size: 40)
                : Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BubbleLevel extends StatelessWidget {
  final double x;
  final double y;

  const _BubbleLevel({required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(x * 50, y * 50).translate(0, 0),
          child: Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// Pantalla de Ajuste Fino (Offset)
class FineTuningScreen extends StatefulWidget {
  final RoomPackage package;
  final List<FurnitureAsset> assets;

  const FineTuningScreen({Key? key, required this.package, required this.assets}) : super(key: key);

  @override
  _FineTuningScreenState createState() => _FineTuningScreenState();
}

class _FineTuningScreenState extends State<FineTuningScreen> {
  double _offset = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AJUSTE FINO'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(child: Text('VIDEO PAUSADO: ${widget.package.videoPath.split('/').last}', style: const TextStyle(color: Colors.white54))),
                // Overlay 3D rotado según el offset
                IgnorePointer(
                  child: cube.Cube(
                    onSceneCreated: (scene) {
                      scene.camera.position.setValues(0, 10, 15);
                      scene.camera.target.setValues(0, 0, 0);
                      for (var asset in widget.assets) {
                        final obj = cube.Object(
                          fileName: asset.modelPath ?? 'assets/cube.obj',
                          position: asset.position,
                          rotation: v.Vector3(0, (asset.rotation + _offset).toDouble(), 0),
                        );
                        scene.world.add(obj);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(30),
            color: const Color(0xFF1A1A1A),
            child: Column(
              children: [
                const Text('Deslizá para alinear la Realidad con el 3D', style: TextStyle(color: Colors.cyanAccent)),
                Slider(
                  value: _offset,
                  min: -45,
                  max: 45,
                  activeColor: Colors.cyanAccent,
                  onChanged: (v) => setState(() => _offset = v),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isSaving ? null : _savePackage,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('CONFIRMAR Y BLOQUEAR DISEÑO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _savePackage() async {
    setState(() => _isSaving = true);
    // Simular procesamiento y guardado
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DISEÑO BLOQUEADO E INDESTRUCTIBLE'), backgroundColor: Colors.green),
      );
      
      // Navegar al Visualizador de Notas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NoteViewerScreen(
            package: widget.package.copyWith(offsetDegrees: _offset),
            assets: widget.assets,
          ),
        ),
      );
    }
  }
}
