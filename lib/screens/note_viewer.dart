import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptics
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription_model.dart';
import '../theme/cyber_theme.dart';

class NoteViewerScreen extends StatefulWidget {
  final RoomPackage package;
  final List<FurnitureAsset> assets;
  final String? initialSelectedAssetId;

  const NoteViewerScreen({
    Key? key,
    required this.package,
    required this.assets,
    this.initialSelectedAssetId,
  }) : super(key: key);

  @override
  _NoteViewerScreenState createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  double _currentOffset = 0.0;
  late RoomPackage _currentPackage;
  
  // Sincronización
  Timer? _syncTimer;
  v.Vector3 _currentRotation = v.Vector3.zero();
  
  // Animaciones Avanzadas
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  late AnimationController _scanController;
  
  // Selección de muebles
  FurnitureAsset? _selectedAsset;
  String? _selectedMuebleName;
  bool _showNoteButton = false;
  cube.Object? _neonGlow;
  late cube.Scene _cubeScene;
  
  // Notas persistentes
  final List<GhostNote> _notes = [];
  final Map<String, cube.Object> _noteObjects = {};

  // Suscripción
  UserSubscription? _userSubscription;

  // Lógica de Desbloqueo por Wi-Fi
  bool _isRoomUnlocked = false;
  double _proximity = 0.0;
  StreamSubscription? _wifiSubscription;

  @override
  void initState() {
    super.initState();
    _currentPackage = widget.package;
    _currentOffset = _currentPackage.offsetDegrees;
    
    // Inicialización Automática: Los muebles ya nacen con su ramillete de notas
    for (var asset in widget.assets) {
      final assetNotes = _currentPackage.notes.where((n) => n.furnitureId == asset.id).toList();
      if (assetNotes.isEmpty) {
        _notes.add(GhostNote(
          id: const Uuid().v4(),
          furnitureId: asset.id,
          content: '',
          authorName: 'Sistema',
          theme: NoteTheme.PRO,
          fontSize: 16.0,
          neonColor: Colors.cyanAccent,
          createdAt: DateTime.now(),
          isActive: false,
        ));
      } else {
        _notes.addAll(assetNotes);
      }
    }
    
    // Actualizar el paquete con las notas inicializadas si es necesario
    _currentPackage = _currentPackage.copyWith(notes: _notes);
    
    // Configurar Animaciones
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3), // Pulso más lento para "respiración"
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.elasticOut),
    );

    _scanController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _breathingController.addListener(() {
      _updateAmbientEffects();
    });

    _initVideo();
    _initWifiUnlocking();
    _loadSubscription();

    // Auto-seleccionar asset si viene de una confirmación rápida
    if (widget.initialSelectedAssetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final asset = widget.assets.firstWhere((a) => a.id == widget.initialSelectedAssetId);
        _selectAssetManually(asset);
        _openNoteEditor(context);
      });
    }
  }

  Future<void> _loadSubscription() async {
    final sub = await UserSubscription.load();
    if (mounted) {
      setState(() {
        _userSubscription = sub;
      });
    }
  }

  void _shareNote(GhostNote note) {
    if (_userSubscription == null || !_userSubscription!.isPremium) {
      _showUpgradeDialog('LA FUNCIÓN DE COMPARTIR ES EXCLUSIVA PARA USUARIOS PREMIUM.');
      return;
    }

    final String text = "He dejado una Ghost Note en mi ${_selectedAsset?.name ?? 'mueble'}. "
        "Ven a verlo en 'Notes Dark Fantasm'.\n\n"
        "Mensaje: ${note.content}\n"
        "Autor: ${note.authorName}";

    Share.share(text, subject: '¡Mira mi nota en AR!');
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: CyberTheme.neonPurple),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('FUNCIÓN PREMIUM',
            style: TextStyle(color: CyberTheme.neonPurple, fontFamily: 'Orbitron', fontSize: 16)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MÁS TARDE', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonPurple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              ).then((_) => _loadSubscription());
            },
            child: const Text('VER PLANES',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _updateAmbientEffects() {
    final intensity = _breathingAnimation.value;
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    
    // Sincronización de notas flotantes sobre muebles reales
    for (var asset in widget.assets) {
      final activeNotes = _notes.where((n) => n.furnitureId == asset.id && n.isActive).toList();
      
      // Mueble real visible: Opacidad completa (1.0) para que se vea tal cual es
      final baseKey = '${asset.id}_base';
      if (_noteObjects.containsKey(baseKey)) {
        final obj = _noteObjects[baseKey]!;
        // Restauramos visibilidad completa del mueble real
        obj.mesh.color.setValues(1.0, 1.0, 1.0);
      }

      // Notas con formatos por edad y colores fuertes
      if (activeNotes.isNotEmpty) {
        for (int i = 0; i < activeNotes.length; i++) {
          final noteKey = '${asset.id}_note_$i';
          if (_noteObjects.containsKey(noteKey)) {
            final noteObj = _noteObjects[noteKey]!;
            final note = activeNotes[i];
            
            // Movimiento preestablecido según el mood/tema
            double bounce = math.sin(time * 2 + i) * 0.05;
            double rotation = math.cos(time + i) * 0.1;
            
            // Posicionamiento flotante sobre el mueble real
            noteObj.position.y = asset.position.y + 0.5 + (i * 0.3) + bounce;
            noteObj.rotation.y = asset.rotation.toDouble() + rotation;

            // Colores fuertes y vibrantes
            final color = note.neonColor;
            noteObj.mesh.color.setValues(
              (color.red / 255) * (0.8 + intensity * 0.2),
              (color.green / 255) * (0.8 + intensity * 0.2),
              (color.blue / 255) * (0.8 + intensity * 0.2),
            );
          }
        }
      }
    }
    
    if (mounted) setState(() {});
  }

  void _selectAssetManually(FurnitureAsset asset) {
    setState(() {
      _selectedAsset = asset;
      _selectedMuebleName = asset.name;
      _showNoteButton = true;
      _applyNeonEffect(asset, isActive: _notes.any((n) => n.furnitureId == asset.id && n.isActive));
    });
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(widget.package.videoPath));
    await _videoController.initialize();
    await _videoController.setLooping(true);
    
    setState(() {
      _isInitialized = true;
    });
    
    _videoController.play();
    
    // Timer de sincronización (aprox 30fps)
    _syncTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      _updateRotationFromVideo();
    });
  }

  void _updateRotationFromVideo() {
    if (!_isInitialized || widget.package.rotationData.isEmpty) return;
    
    final currentMs = _videoController.value.position.inMilliseconds;
    // Encontrar el dato de rotación más cercano al timestamp del video
    // (Asumimos que el primer dato de rotación coincide con el inicio del video)
    final startTime = widget.package.rotationData.first.timestamp;
    final targetTs = startTime + currentMs;
    
    // Búsqueda simple (puede optimizarse con búsqueda binaria)
    GyroData closest = widget.package.rotationData.first;
    for (var data in widget.package.rotationData) {
      if ((data.timestamp - targetTs).abs() < (closest.timestamp - targetTs).abs()) {
        closest = data;
      }
    }
    
    setState(() {
      // Aplicamos la rotación + el offset
      _currentRotation = v.Vector3(closest.x, closest.y + _currentOffset, closest.z);
      if (mounted) {
        _cubeScene.camera.rotation.setValues(0, _currentRotation.y, 0);
        _cubeScene.update();
      }
    });
  }

  void _handleTap(TapUpDetails details) {
    // Raycasting simulado para detectar muebles
    // En una implementación real, usaríamos la posición de la cámara y el punto de toque
    // para proyectar un rayo en el mundo 3D.
    
    // Por ahora, simulamos la detección: si toca cerca del centro y hay un mueble cerca
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    final relativeX = localPos.dx / box.size.width;
    final relativeY = localPos.dy / box.size.height;

    // Lógica simplificada: si toca el tercio central
    if (relativeX > 0.3 && relativeX < 0.7 && relativeY > 0.3 && relativeY < 0.7) {
      _detectFurniture();
    } else {
      setState(() {
        _selectedMuebleName = null;
        _showNoteButton = false;
        if (_selectedAsset != null) {
          _removeNeonEffect(_selectedAsset!.id);
        }
      });
    }
  }

  void _detectFurniture() {
    if (widget.assets.isEmpty) return;
    
    FurnitureAsset? closestAsset;
    double minAngleDiff = double.infinity;
    
    for (var asset in widget.assets) {
      final assetAngle = v.atan2(asset.position.x, asset.position.z);
      final diff = (assetAngle - _currentRotation.y).abs() % (v.pi * 2);
      final normalizedDiff = diff > v.pi ? (v.pi * 2 - diff) : diff;
      
      if (normalizedDiff < minAngleDiff) {
        minAngleDiff = normalizedDiff;
        closestAsset = asset;
      }
    }
    
    if (closestAsset != null && minAngleDiff < 0.8) {
      final asset = closestAsset;
      final activeNotes = _notes.where((n) => n.furnitureId == asset.id && n.isActive).toList();
      final hasActiveNotes = activeNotes.isNotEmpty;

      setState(() {
        _selectedAsset = asset;
        _selectedMuebleName = asset.name;
        _showNoteButton = true;
        _applyNeonEffect(asset, isActive: hasActiveNotes);
        
        if (hasActiveNotes) {
          // Feedback Háptico Dinámico
          final mood = activeNotes.first.mood;
          if (mood == NoteMood.joy) {
            HapticFeedback.lightImpact();
            Timer.periodic(const Duration(milliseconds: 200), (t) {
              if (t.tick > 2) t.cancel();
              HapticFeedback.lightImpact();
            });
          } else {
            HapticFeedback.heavyImpact();
            Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
            Future.delayed(const Duration(milliseconds: 250), () => HapticFeedback.vibrate());
          }

          // Efecto Focus (Rebote) solo si hay activas
          _focusController.forward(from: 0);
          // Efecto Scanning solo si hay activas
          _scanController.forward(from: 0);
        }
      });
    } else {
      setState(() {
        _selectedMuebleName = null;
        _showNoteButton = false;
        if (_selectedAsset != null) {
          _removeNeonEffect(_selectedAsset!.id);
        }
      });
    }
  }

  void _applyNeonEffect(FurnitureAsset asset, {bool isActive = true}) {
    _removeNeonEffect(asset.id);
    
    // El mueble real se mantiene visible al 100%
    final baseObj = cube.Object(
      fileName: asset.modelPath ?? 'assets/cube.obj',
      position: asset.position,
      rotation: v.Vector3(0, asset.rotation.toDouble(), 0),
      scale: v.Vector3(1.0, 1.0, 1.0),
    );
    // Color blanco puro para que se vea la textura/modelo real
    baseObj.mesh.color.setValues(1.0, 1.0, 1.0); 
    _cubeScene.world.add(baseObj);
    _noteObjects['${asset.id}_base'] = baseObj;

    final activeNotes = _notes.where((n) => n.furnitureId == asset.id && n.isActive).toList();
    
    if (activeNotes.isNotEmpty) {
      // Formatos por escala de edades (KIDS, YOUNG, PRO)
      for (int i = 0; i < activeNotes.length; i++) {
        final note = activeNotes[i];
        
        // Selección de modelo según el formato de edad (Theme)
        String modelFile;
        v.Vector3 scale;
        
        switch (note.theme) {
          case NoteTheme.KIDS:
            modelFile = 'assets/star.obj'; // Formato lúdico para niños
            scale = v.Vector3(0.12, 0.12, 0.12);
            break;
          case NoteTheme.YOUNG:
            modelFile = 'assets/diamond.obj'; // Formato moderno para jóvenes
            scale = v.Vector3(0.15, 0.15, 0.15);
            break;
          case NoteTheme.PRO:
          default:
            modelFile = 'assets/cube_hollow.obj'; // Formato minimalista para adultos
            scale = v.Vector3(0.18, 0.18, 0.18);
            break;
        }

        final noteObj = cube.Object(
          fileName: modelFile,
          position: v.Vector3(
            asset.position.x,
            asset.position.y + 0.5 + (i * 0.3),
            asset.position.z,
          ),
          scale: scale,
        );

        // Colores fuertes y vibrantes iniciales
        final intensity = _breathingAnimation.value;
        final color = note.neonColor;
        noteObj.mesh.color.setValues(
          (color.red / 255) * (0.8 + intensity * 0.2),
          (color.green / 255) * (0.8 + intensity * 0.2),
          (color.blue / 255) * (0.8 + intensity * 0.2),
        );
        
        _cubeScene.world.add(noteObj);
        _noteObjects['${asset.id}_note_$i'] = noteObj;
      }
    }
  }

  void _removeNeonEffect(String assetId) {
    // Limpiamos todos los objetos relacionados con este asset (base y orbes)
    final keysToRemove = _noteObjects.keys.where((k) => k.startsWith(assetId)).toList();
    for (var key in keysToRemove) {
      _cubeScene.world.remove(_noteObjects[key]!);
      _noteObjects.remove(key);
    }
  }

  void _openNoteEditor(BuildContext context) {
    if (_selectedAsset == null) return;
    
    final furnitureId = _selectedAsset!.id;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteEditorPanel(
        furnitureId: furnitureId,
        onSave: (note) {
          // Activación por Escritura: Si tiene contenido, isActive pasa a true
          final updatedNote = note.copyWith(
            isActive: note.content.trim().isNotEmpty,
          );
          
          setState(() {
            _notes.add(updatedNote);
            _currentPackage = _currentPackage.copyWith(notes: _notes);
            
            // Si se activó, disparamos efectos
            if (updatedNote.isActive) {
              _applyNeonEffect(_selectedAsset!, isActive: true);
              _focusController.forward(from: 0);
              _scanController.forward(from: 0);
            } else {
              _applyNeonEffect(_selectedAsset!, isActive: false);
            }
          });
        },
      ),
    );
  }

  void _initWifiUnlocking() {
    final wifiService = WifiSignalService();
    wifiService.startScanning();
    
    _wifiSubscription = wifiService.rssiStream.listen((rssi) {
      // Prioridad: Usar el targetRSSI guardado en el RoomPackage (específico de esta sala)
      final targetRSSI = _currentPackage.targetRSSI;
      final targetSSID = _currentPackage.targetSSID;
      final currentSSID = wifiService.currentSSID;

      if (targetRSSI == null || targetSSID == null) {
        // Fallback: Si no hay firma específica, intentar con el mapa general si existe
        if (_currentPackage.wifiMap.isEmpty) {
          // Para desarrollo: si no hay nada, desbloqueamos
          setState(() {
            _proximity = 1.0;
            _isRoomUnlocked = true;
          });
          return;
        }

        // Buscar en el mapa general
        final fingerprints = _currentPackage.wifiMap.where((f) => f.ssid == currentSSID).toList();
        if (fingerprints.isNotEmpty) {
          int minDiff = 100;
          for (var f in fingerprints) {
            int diff = (f.level - rssi).abs();
            if (diff < minDiff) minDiff = diff;
          }
          double proximity = (1.0 - (minDiff / 30.0)).clamp(0.0, 1.0);
          _updateUnlockStatus(proximity > 0.7, proximity);
        } else {
          _updateUnlockStatus(false, 0.0);
        }
        return;
      }

      // Lógica Principal: Validar contra el target de la sala
      if (currentSSID == targetSSID) {
        int diff = (targetRSSI - rssi).abs();
        // Curva de proximidad: 0dB de diferencia = 1.0, 30dB de diferencia = 0.0
        double proximity = (1.0 - (diff / 30.0)).clamp(0.0, 1.0);
        bool unlocked = proximity > 0.65; // Umbral un poco más permisivo para el target directo

        _updateUnlockStatus(unlocked, proximity);
      } else {
        // SSID no coincide
        _updateUnlockStatus(false, 0.0);
      }
    });
  }

  void _updateUnlockStatus(bool unlocked, double proximity) {
    if (unlocked && !_isRoomUnlocked) {
      // ¡Match detectado!
      _triggerMatchFeedback();
    }

    if (mounted) {
      setState(() {
        _proximity = proximity;
        _isRoomUnlocked = unlocked;
      });
    }
  }

  void _triggerMatchFeedback() {
    // Patrón de vibración de match
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 250), () => HapticFeedback.heavyImpact());
    
    // Destello de bienvenida (Reality Sync)
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white.withOpacity(0.8), // Destello blanco intenso
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      // Segundo destello más suave
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.cyanAccent.withOpacity(0.3),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
      });
    });
  }

  @override
  void dispose() {
    _wifiSubscription?.cancel();
    WifiSignalService().stopScanning();
    _syncTimer?.cancel();
    _videoController.dispose();
    _breathingController.dispose();
    _focusController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Widget _buildNoteInteractionUI() {
    final activeNotes = _notes.where((n) => n.furnitureId == _selectedAsset!.id && n.isActive).toList();
    
    // Si no está desbloqueado, forzamos la visualización bloqueada
    if (!_isRoomUnlocked) {
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Colors.cyanAccent, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'CONTENIDO MATERIALIZADO\nEN LA REALIDAD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    letterSpacing: 2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Acercate a ${_currentPackage.roomName} para revelar el mensaje',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 30),
                // Indicador de proximidad
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _proximity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        // Foto de Referencia (Paso Cero)
        if (_selectedAsset?.initialPhotoPath != null)
          Positioned(
            top: 100,
            right: 20,
            child: GestureDetector(
              onTap: () => _showReferencePhoto(_selectedAsset!.initialPhotoPath!),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: CyberTheme.neonGreen, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: CyberTheme.neonGreen.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_selectedAsset!.initialPhotoPath!), fit: BoxFit.cover),
                ),
              ),
            ),
          ),

        if (activeNotes.isEmpty)
          _buildSingleNoteDisplay(_notes.firstWhere((n) => n.furnitureId == _selectedAsset!.id))
        else if (activeNotes.length == 1)
          _buildSingleNoteDisplay(activeNotes.first)
        else
          _buildCarouselNotes(activeNotes),
      ],
    );
  }

  void _showReferencePhoto(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: CyberTheme.neonGreen, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(File(path)),
              ),
            ),
            const SizedBox(height: 10),
            const Text('REFERENCIA ORIGINAL (PASO CERO)', 
              style: TextStyle(color: CyberTheme.neonGreen, fontFamily: 'Orbitron', fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselNotes(List<GhostNote> activeNotes) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: LeaderLinePainter(
            furniturePos: _selectedAsset!.position,
            cameraRotation: _currentRotation,
            neonColor: activeNotes.first.neonColor,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: 0,
          right: 0,
          height: 400,
          child: PageView.builder(
            itemCount: activeNotes.length,
            controller: PageController(viewportFraction: 0.85),
            itemBuilder: (context, index) {
              final note = activeNotes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: _GhostNoteDisplay(
                    note: note,
                    onComplete: () => _explodeAndRemoveNote(note),
                    onEdit: () => _openNoteEditor(context),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${activeNotes.length} notas en este objeto',
              style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleNoteDisplay(GhostNote note) {
    return Stack(
      children: [
        // Leader Line (Línea de Vínculo) - Solo si está activa
        if (note.isActive)
          CustomPaint(
            size: Size.infinite,
            painter: LeaderLinePainter(
              furniturePos: _selectedAsset!.position,
              cameraRotation: _currentRotation,
              neonColor: note.neonColor,
            ),
          ),

        // Note Card con Efecto Focus
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: 40,
          right: 40,
          child: ScaleTransition(
            scale: _focusAnimation,
            child: FadeTransition(
              opacity: note.isActive ? _scanController : const AlwaysStoppedAnimation(1.0),
              child: _GhostNoteDisplay(
                note: note,
                onComplete: () => _explodeAndRemoveNote(note),
                onEdit: () => _openNoteEditor(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _explodeAndRemoveNote(GhostNote note) {
    // 1. Efecto Visual de Explosión
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => _ExplosionOverlay(color: note.neonColor),
    );

    // 2. Regla de Tarea Cumplida: Solo se elimina SU nota
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      
      // Si el mueble se quedó sin notas, agregamos un placeholder
      if (!_notes.any((n) => n.furnitureId == note.furnitureId)) {
        _notes.add(GhostNote(
          id: const Uuid().v4(),
          furnitureId: note.furnitureId,
          content: '',
          authorName: 'Sistema',
          theme: NoteTheme.PRO,
          fontSize: 16.0,
          neonColor: Colors.cyanAccent,
          createdAt: DateTime.now(),
          isActive: false,
        ));
      }
      
      _currentPackage = _currentPackage.copyWith(notes: _notes);
      
      // Actualizar Aura y Efectos
      if (_selectedAsset != null && _selectedAsset!.id == note.furnitureId) {
        final remainingActive = _notes.where((n) => n.furnitureId == note.furnitureId && n.isActive).toList();
        if (remainingActive.isNotEmpty) {
          _applyNeonEffect(_selectedAsset!, isActive: true);
        } else {
          _applyNeonEffect(_selectedAsset!, isActive: false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Player (Fondo)
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),

          // 2. Efecto de Ambiente (Partículas de Envejecimiento)
          _AtmosphericOverlay(),

          // 3. Layer 3D Invisible (Muebles)
          GestureDetector(
            onTapUp: _handleTap,
            child: cube.Cube(
              onSceneCreated: (scene) {
                _cubeScene = scene;
                scene.camera.position.setValues(0, 2, 0); // Cámara en el centro (usuario)
                scene.camera.target.setValues(0, 2, 5);
                
                // Agregar muebles y sus efectos fantasmagóricos persistentes
                for (var asset in widget.assets) {
                  // Mueble invisible para colisiones
                  final obj = cube.Object(
                    fileName: asset.modelPath ?? 'assets/cube.obj',
                    position: asset.position,
                    rotation: v.Vector3(0, asset.rotation.toDouble(), 0),
                  );
                  obj.mesh.color.setValues(0, 0, 0); 
                  scene.world.add(obj);

                  // Cargar notas activas persistentes (Visibilidad por Defecto)
                  final assetNotes = _notes.where((n) => n.furnitureId == asset.id && n.isActive).toList();
                  
                  if (assetNotes.isNotEmpty) {
                    // Mueble con Aura Combinada
                    final glow = cube.Object(
                      fileName: asset.modelPath ?? 'assets/cube.obj',
                      position: asset.position,
                      rotation: v.Vector3(0, asset.rotation.toDouble(), 0),
                      scale: v.Vector3(1.05, 1.05, 1.05),
                    );
                    
                    // Color inicial promediado
                    double r = 0, g = 0, b = 0;
                    for (var note in assetNotes) {
                      r += note.neonColor.red;
                      g += note.neonColor.green;
                      b += note.neonColor.blue;
                    }
                    glow.mesh.color.setValues(r / assetNotes.length / 255, g / assetNotes.length / 255, b / assetNotes.length / 255);
                    
                    scene.world.add(glow);
                    _noteObjects[asset.id] = glow;

                    // Renderizado en 'Ramillete': Representación visual de múltiples notas
                    for (int i = 0; i < assetNotes.length; i++) {
                      final angle = (i * (2 * math.pi / assetNotes.length));
                      final radius = 0.8;
                      final heightOffset = (i - (assetNotes.length - 1) / 2) * 0.4;
                      
                      final noteParticle = cube.Object(
                        fileName: 'assets/sphere.obj', // Un objeto pequeño para representar la nota
                        position: v.Vector3(
                          asset.position.x + math.cos(angle) * radius,
                          asset.position.y + 1.5 + heightOffset,
                          asset.position.z + math.sin(angle) * radius,
                        ),
                        scale: v.Vector3(0.2, 0.2, 0.2),
                      );
                      
                      final noteColor = assetNotes[i].neonColor;
                      noteParticle.mesh.color.setValues(noteColor.red / 255, noteColor.green / 255, noteColor.blue / 255);
                      scene.world.add(noteParticle);
                    }
                  }
                }
              },
            ),
          ),

          // 3. UI: Botón "Ver Nota" y Overlays
          if (_showNoteButton && _selectedAsset != null)
            _buildNoteInteractionUI(),

          // 4. Slider de Offset (Sutil)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text('Ajuste de Alineación (Offset)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Slider(
                  value: _currentOffset,
                  min: -45,
                  max: 45,
                  activeColor: Colors.cyanAccent.withOpacity(0.5),
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    setState(() {
                      _currentOffset = val;
                      _currentPackage = _currentPackage.copyWith(offsetDegrees: val);
                    });
                  },
                ),
              ],
            ),
          ),

          // Botón Cerrar
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, _currentPackage),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticEnergyPainter extends CustomPainter {
  final Color color;
  final List<_Particle> particles = List.generate(15, (index) => _Particle());

  _StaticEnergyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final time = DateTime.now().millisecondsSinceEpoch / 500;

    for (var p in particles) {
      final x = (p.baseX + math.sin(time * p.speedX) * 0.05) * size.width;
      final y = (p.baseY + math.cos(time * p.speedY) * 0.05) * size.height;
      
      canvas.drawCircle(Offset(x, y), p.size * 0.5, paint);
      
      // Mini destellos
      if (math.Random().nextDouble() > 0.95) {
        canvas.drawCircle(Offset(x, y), p.size, Paint()..color = Colors.white.withOpacity(0.4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
 class _AtmosphericOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AtmospherePainter(),
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final List<_Particle> particles = List.generate(30, (index) => _Particle());

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final time = DateTime.now().millisecondsSinceEpoch / 1000;

    for (var p in particles) {
      final x = (p.baseX + ui.sin(time * p.speedX) * 0.1) * size.width;
      final y = (p.baseY + ui.cos(time * p.speedY) * 0.1) * size.height;
      
      // Color gélido/nieve o cálido/otoño dependiendo del tiempo
      paint.color = Colors.white.withOpacity(p.opacity * 0.3);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Particle {
  static final math.Random _random = math.Random();
  final double baseX = _random.nextDouble();
  final double baseY = _random.nextDouble();
  final double speedX = _random.nextDouble() * 0.5;
  final double speedY = _random.nextDouble() * 0.5;
  final double size = _random.nextDouble() * 3 + 1;
  final double opacity = _random.nextDouble();
}

class LeaderLinePainter extends CustomPainter {
  final v.Vector3 furniturePos;
  final v.Vector3 cameraRotation;
  final Color neonColor;

  LeaderLinePainter({
    required this.furniturePos,
    required this.cameraRotation,
    required this.neonColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculamos una posición aproximada en pantalla basada en la rotación
    // Esto es una simplificación ya que no tenemos la matriz de proyección completa aquí
    final angle = v.atan2(furniturePos.x, furniturePos.z);
    final diff = (angle - cameraRotation.y).abs() % (v.pi * 2);
    final normalizedDiff = diff > v.pi ? (v.pi * 2 - diff) : diff;
    
    // Si no está en el campo de visión (aprox 90 grados), no dibujamos
    if (normalizedDiff > 0.8) return;

    final xOffset = (angle - cameraRotation.y) * 500;
    final start = Offset(size.width / 2 + xOffset, size.height * 0.6);
    final end = Offset(size.width / 2, size.height * 0.4);

    final paint = Paint()
      ..color = neonColor.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      start.dx, start.dy - 100,
      end.dx, end.dy + 100,
      end.dx, end.dy
    );
    
    canvas.drawPath(path, paint);
    
    // Efecto de pulso en la línea (partícula viajera)
    final progress = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
    final metric = ui.PathMetrics(path, false).first;
    final pos = metric.getTangentForOffset(metric.length * progress)!.position;
    
    canvas.drawCircle(pos, 4, Paint()..color = Colors.white.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GhostNoteDisplay extends StatefulWidget {
  final GhostNote note;
  final VoidCallback onComplete;
  final VoidCallback onEdit;

  const _GhostNoteDisplay({
    required this.note,
    required this.onComplete,
    required this.onEdit,
  });

  @override
  __GhostNoteDisplayState createState() => __GhostNoteDisplayState();
}

class __GhostNoteDisplayState extends State<_GhostNoteDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _typewriterController;
  late int _visibleCharacters;
  
  @override
  void initState() {
    super.initState();
    _visibleCharacters = 0;
    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.note.content.length * 50),
    );

    if (widget.note.theme == NoteTheme.PRO) {
      _typewriterController.addListener(() {
        setState(() {
          _visibleCharacters = (widget.note.content.length * _typewriterController.value).toInt();
        });
      });
      _typewriterController.forward();
    } else {
      _visibleCharacters = widget.note.content.length;
    }
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  Color _getAgedColor() {
    final age = DateTime.now().difference(widget.note.createdAt).inHours;
    if (age < 3) return widget.note.neonColor;
    
    // Degradado hacia tonos gélidos/otoñales
    final t = ((age - 3) / 21).clamp(0.0, 1.0); // De 3h a 24h
    return Color.lerp(widget.note.neonColor, const Color(0xFF4A5D6B), t)!;
  }

  @override
  Widget build(BuildContext context) {
    final agedColor = _getAgedColor();
    final ageHours = DateTime.now().difference(widget.note.createdAt).inHours;
    final isOld = ageHours >= 24;
    final isActive = widget.note.isActive;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isActive ? agedColor.withOpacity(0.5) : Colors.white10, 
              width: 1.5
            ),
            boxShadow: isActive ? [
              BoxShadow(color: agedColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
            ] : [],
          ),
          child: Stack(
            children: [
              // 0. Fondo de Partículas (Energía Estática)
              if (isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _StaticEnergyPainter(color: agedColor),
                    ),
                  ),
                ),

              // 1. Identidad de Autor (Holográfico)
              if (isActive)
                Positioned(
                  top: 15,
                  left: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: agedColor,
                          boxShadow: [BoxShadow(color: agedColor, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.note.authorName.toUpperCase(),
                        style: TextStyle(
                          color: agedColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Variante de Estilo (KIDS/YOUNG/PRO) o Placeholder si inactiva
              if (isActive)
                _buildStyleSpecificContent(agedColor)
              else
                _buildInactivePlaceholder(),
              
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      if (isActive)
                        TextButton.icon(
                          icon: Icon(Icons.check_circle_outline, color: agedColor, size: 20),
                          label: Text(
                            'Tarea Cumplida',
                            style: TextStyle(color: agedColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: widget.onComplete,
                          style: TextButton.styleFrom(
                            backgroundColor: agedColor.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white54, size: 18),
                        onPressed: () => _shareNote(widget.note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                        onPressed: widget.onEdit,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInactivePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, color: Colors.white24, size: 40),
          SizedBox(height: 10),
          Text(
            'Sin nota asignada',
            style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w300),
          ),
          Text(
            'Toca el lápiz para escribir',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: FrostPainter(),
        ),
      ),
    );
  }

  Widget _buildStyleSpecificContent(Color agedColor) {
    final content = widget.note.theme == NoteTheme.PRO 
        ? widget.note.content.substring(0, _visibleCharacters)
        : widget.note.content;

    // Efecto Glitch para Miedo
    final isFear = widget.note.mood == NoteMood.fear;
    
    return Stack(
      children: [
        // Avatar Holográfico
        Positioned(
          top: 10,
          right: 60,
          child: _HolographicAvatar(
            avatar: widget.note.authorAvatar,
            mood: widget.note.mood,
            color: agedColor,
          ),
        ),
        
        // Contenido de la nota con posibles efectos de mood
        _buildMoodAdaptedContent(agedColor, content, isFear),
      ],
    );
  }

  Widget _buildMoodAdaptedContent(Color agedColor, String content, bool isFear) {
    Widget baseContent;
    switch (widget.note.theme) {
      case NoteTheme.KIDS:
        baseContent = _KIDSVariant(note: widget.note, color: agedColor, content: content);
        break;
      case NoteTheme.YOUNG:
        baseContent = _YOUNGVariant(note: widget.note, color: agedColor, content: content);
        break;
      case NoteTheme.PRO:
        baseContent = _PROVariant(note: widget.note, color: agedColor, content: content);
        break;
    }

    if (isFear) {
      return _GlitchEffect(child: baseContent);
    }
    return baseContent;
  }
}

class _HolographicAvatar extends StatefulWidget {
  final String avatar;
  final NoteMood mood;
  final Color color;

  const _HolographicAvatar({
    required this.avatar,
    required this.mood,
    required this.color,
  });

  @override
  State<_HolographicAvatar> createState() => _HolographicAvatarState();
}

class _HolographicAvatarState extends State<_HolographicAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'child_care': return Icons.child_care;
      case 'rocket': return Icons.rocket_launch;
      case 'account_circle': return Icons.account_circle;
      case 'volunteer_activism': return Icons.volunteer_activism;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJoy = widget.mood == NoteMood.joy;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * math.pi * 2) * (isJoy ? 5 : 2);
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.1),
              border: Border.all(
                color: widget.color.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _getIconData(widget.avatar),
              color: widget.color,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

class _GlitchEffect extends StatefulWidget {
  final Widget child;
  const _GlitchEffect({required this.child});

  @override
  State<_GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<_GlitchEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_random.nextDouble() > 0.8) {
          final x = (_random.nextDouble() - 0.5) * 4;
          final y = (_random.nextDouble() - 0.5) * 4;
          return Transform.translate(
            offset: Offset(x, y),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}

// --- Variantes Específicas ---

class _KIDSVariant extends StatefulWidget {
  final GhostNote note;
  final Color color;
  final String content;

  const _KIDSVariant({required this.note, required this.color, required this.content});

  @override
  _KIDSVariantState createState() => _KIDSVariantState();
}

class _KIDSVariantState extends State<_KIDSVariant> with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  final List<_Particle> _particles = List.generate(15, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Partículas de fondo (Burbujas y Estrellas)
            ..._particles.map((p) => Positioned(
              left: p.x * 300,
              top: ((p.y + _floatingController.value * p.speed) % 1.0) * 200,
              child: Opacity(
                opacity: 0.3,
                child: Icon(
                  p.isStar ? Icons.star : Icons.circle,
                  color: p.isStar ? Colors.yellowAccent : widget.color,
                  size: p.size,
                ),
              ),
            )),
            
            Container(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.yellowAccent, size: 20),
                      SizedBox(width: 10),
                      Text('GHOST KIDS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                      SizedBox(width: 10),
                      Icon(Icons.star, color: Colors.yellowAccent, size: 20),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.content,
                    style: TextStyle(
                      fontSize: widget.note.fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: widget.color, blurRadius: 10),
                        Shadow(color: widget.color, blurRadius: 20),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}

class _Particle {
  final double x = ui.lerpDouble(0, 1, (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)!;
  final double y = ui.lerpDouble(0, 1, (DateTime.now().microsecondsSinceEpoch % 1001) / 1001)!;
  final double speed = 0.2 + (DateTime.now().microsecondsSinceEpoch % 100) / 200;
  final double size = 5 + (DateTime.now().microsecondsSinceEpoch % 15).toDouble();
  final bool isStar = DateTime.now().microsecondsSinceEpoch % 2 == 0;
}

              shadows: [Shadow(color: color, blurRadius: 15)],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _YOUNGVariant extends StatefulWidget {
  final GhostNote note;
  final Color color;
  final String content;

  const _YOUNGVariant({required this.note, required this.color, required this.content});

  @override
  __YOUNGVariantState createState() => __YOUNGVariantState();
}

class __YOUNGVariantState extends State<_YOUNGVariant> with SingleTickerProviderStateMixin {
  late AnimationController _rainbowController;

  @override
  void initState() {
    super.initState();
    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _rainbowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rainbowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: [widget.color, Colors.blueAccent, Colors.purpleAccent, widget.color],
              transform: GradientRotation(_rainbowController.value * 6.28),
            ).addOpacity(0.1),
          ),
          child: Text(
            widget.content,
            style: TextStyle(
              fontSize: widget.note.fontSize,
              color: Colors.white,
              fontFamily: 'Modern',
              shadows: [Shadow(color: widget.color.withOpacity(0.5), blurRadius: 10)],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class _PROVariant extends StatelessWidget {
  final GhostNote note;
  final Color color;
  final String content;

  const _PROVariant({required this.note, required this.color, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: color,
              ),
              const SizedBox(width: 10),
              const Text('SECURE_GHOST_HUD // v1.0', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Monospace')),
              const Spacer(),
              const Icon(Icons.security, color: Colors.white24, size: 14),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: TextStyle(
              fontSize: note.fontSize,
              color: color.withOpacity(0.9),
              fontFamily: 'Monospace',
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text('>> SYSTEM_READY', style: TextStyle(color: Colors.white24, fontSize: 8)),
          ),
        ],
      ),
    );
  }
}

// --- Pintores Auxiliares ---

class FrostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Dibujamos pequeños "cristales" en las esquinas
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(Offset(0, i * 10), Offset(i * 10, 0), paint);
      canvas.drawLine(Offset(size.width, size.height - i * 10), Offset(size.width - i * 10, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExplosionOverlay extends StatefulWidget {
  final Color color;
  const _ExplosionOverlay({required this.color});

  @override
  __ExplosionOverlayState createState() => __ExplosionOverlayState();
}

class __ExplosionOverlayState extends State<_ExplosionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _controller.forward().then((_) => Navigator.pop(context));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Container(
            width: _controller.value * 400,
            height: _controller.value * 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withOpacity(1 - _controller.value), width: 10),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.5 * (1 - _controller.value)), blurRadius: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension GradientOpacity on Gradient {
  Gradient addOpacity(double opacity) {
    return this; // Placeholder for simplicity
  }
}
  final GhostNote? initialNote;
  final String furnitureId;
  final Function(GhostNote) onSave;

  const _NoteEditorPanel({
    Key? key,
    this.initialNote,
    required this.furnitureId,
    required this.onSave,
  }) : super(key: key);

  @override
  __NoteEditorPanelState createState() => __NoteEditorPanelState();
}

class __NoteEditorPanelState extends State<_NoteEditorPanel> {
  late TextEditingController _contentController;
  late NoteTheme _currentTheme;
  late NoteMood _currentMood;
  late double _fontSize;
  late Color _neonColor;
  String _userName = 'Invitado';
  String _userAvatar = 'person';

  final List<Color> _neonColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialNote?.content ?? '');
    _currentTheme = widget.initialNote?.theme ?? NoteTheme.YOUNG;
    _currentMood = widget.initialNote?.mood ?? NoteMood.joy;
    _fontSize = widget.initialNote?.fontSize ?? 18.0;
    _neonColor = widget.initialNote?.neonColor ?? Colors.cyanAccent;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Invitado';
      _userAvatar = prefs.getString('user_avatar') ?? 'person';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.initialNote == null ? 'NUEVA NOTA GHOST' : 'EDITAR NOTA GHOST',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Firmado por: $_userName',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Selector de Mood Emocional
            const Text('ESTADO DE ÁNIMO DEL HOLOGRAMA', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _currentMood = NoteMood.joy;
                      _neonColor = Colors.cyanAccent;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentMood == NoteMood.joy ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _currentMood == NoteMood.joy ? Colors.cyanAccent : Colors.transparent,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.sentiment_very_satisfied, color: Colors.cyanAccent),
                          SizedBox(height: 4),
                          Text('ALEGRÍA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _currentMood = NoteMood.fear;
                      _neonColor = Colors.purpleAccent;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentMood == NoteMood.fear ? Colors.purpleAccent.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _currentMood == NoteMood.fear ? Colors.purpleAccent : Colors.transparent,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.sentiment_very_dissatisfied, color: Colors.purpleAccent),
                          SizedBox(height: 4),
                          Text('MIEDO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selector de Temas
            const Text('ESTILO DE NOTA', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: NoteTheme.values.map((theme) {
                final isSelected = _currentTheme == theme;
                return GestureDetector(
                  onTap: () => setState(() => _currentTheme = theme),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _neonColor.withOpacity(0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? _neonColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Editor de Contenido
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje ghost aquí...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Slider de Tamaño de Fuente
            Row(
              children: [
                const Text('TAMAÑO', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 48,
                    activeColor: _neonColor,
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                ),
                Text('${_fontSize.toInt()}px', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),

            // Selector de Color Neón
            const Text('COLOR DE RESPLANDOR', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _neonColors.length,
                itemBuilder: (context, index) {
                  final color = _neonColors[index];
                  final isSelected = _neonColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _neonColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 15),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: [
                          if (isSelected) BoxShadow(color: color.withOpacity(0.6), blurRadius: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Preview del Estilo
            const Text('VISTA PREVIA', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            _buildThemePreview(),
            const SizedBox(height: 30),

            // Botón Guardar
            ElevatedButton(
              onPressed: () {
                final note = GhostNote(
                  id: widget.initialNote?.id ?? const Uuid().v4(),
                  furnitureId: widget.furnitureId,
                  content: _contentController.text,
                  authorName: _userName,
                  authorAvatar: _userAvatar,
                  mood: _currentMood,
                  theme: _currentTheme,
                  fontSize: _fontSize,
                  neonColor: _neonColor,
                  createdAt: widget.initialNote?.createdAt ?? DateTime.now(),
                );
                widget.onSave(note);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('GUARDAR GHOST NOTE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview() {
    switch (_currentTheme) {
      case NoteTheme.KIDS:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _neonColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _neonColor, width: 4),
          ),
          child: Text(
            _contentController.text.isEmpty ? '¡Hola! 👻✨' : _contentController.text,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: _neonColor, blurRadius: 10),
              ],
            ),
          ),
        );
      case NoteTheme.YOUNG:
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_neonColor.withOpacity(0.4), _neonColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _contentController.text.isEmpty ? 'Vibe Check...' : _contentController.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontFamily: 'Modern',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      case NoteTheme.PRO:
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border(left: BorderSide(color: _neonColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: _neonColor,
                    child: const Text('INFORMATIVO', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.qr_code, color: Colors.white24, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _contentController.text.isEmpty ? 'Registro de mantenimiento técnico.' : _contentController.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontFamily: 'Monospace',
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
    }
  }
}

