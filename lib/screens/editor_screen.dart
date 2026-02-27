import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../models/room_models.dart';
import '../logic/furniture_catalog.dart';
import '../models/subscription_model.dart';
import 'subscription_screen.dart';
import '../widgets/canvas_2d.dart';
import '../widgets/scene_3d_view.dart';
import '../theme/cyber_theme.dart';
import 'vision_recorder_screen.dart';
import '../services/wifi_signal_service.dart';
import '../assets_registry.dart';
import 'room_demo_screen.dart';
import 'splash_screen.dart'; // Importar Splash para el tutorial
import 'profile_registration_screen.dart';

class EditorScreen extends StatefulWidget {
  final Room? room;
  const EditorScreen({Key? key, this.room}) : super(key: key);

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late String _roomId;
  String selectedFloor = 'PB';
  RoomType selectedRoomType = RoomType.bedroom;
  List<FurnitureAsset> currentAssets = [];
  bool is3DView = false;
  bool isEditMode = true; // true = Modo Arquitecto, false = Modo Ghost
  bool isOrbiting = false;
  FurnitureAsset? selectedAsset;
  
  String? targetSSID;
  int? targetRSSI;
  final WifiSignalService _wifiService = WifiSignalService();

  String _userName = 'Invitado';
  String _userAvatar = 'person';
  int _totalNotesCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _roomId = widget.room!.id;
      selectedFloor = widget.room!.floorLevel;
      selectedRoomType = widget.room!.type;
      currentAssets = List.from(widget.room!.assets);
      targetSSID = widget.room!.targetSSID;
      targetRSSI = widget.room!.targetRSSI;
      _loadUserProfile();
    } else {
      _roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      _loadFromLocal();
    }
    _loadUserProfile();
    _wifiService.startScanning();
    _setupAlertMonitoring();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Invitado';
        _userAvatar = prefs.getString('user_avatar') ?? 'person';
        
        // Contar notas activas en los muebles
        _totalNotesCount = 0;
        for (var asset in currentAssets) {
          _totalNotesCount += asset.notes.length;
        }
      });
    }
  }

  IconData _getAvatarIcon(String key) {
    switch (key) {
      case 'child_care': return Icons.child_care;
      case 'rocket': return Icons.rocket_launch;
      case 'account_circle': return Icons.account_circle;
      case 'volunteer_activism': return Icons.volunteer_activism;
      default: return Icons.person;
    }
  }

  @override
  void dispose() {
    _wifiService.stopScanning();
    super.dispose();
  }

  // Modo Alerta: Monitorea proximidad y notas no leídas
  void _setupAlertMonitoring() {
    _wifiService.rssiStream.listen((rssi) {
      if (targetRSSI != null) {
        double proximity = _wifiService.calculateProximity(targetRSSI!);
        bool hasUnread = currentAssets.any((a) => a.hasUnreadNotes);
        
        if (proximity > 0.8 && hasUnread) {
          _wifiService.triggerHapticAlert();
        }
      }
    });
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Crear objeto Room actualizado
    final room = Room(
      id: _roomId,
      floorLevel: selectedFloor,
      type: selectedRoomType,
      assets: currentAssets,
      targetSSID: targetSSID,
      targetRSSI: targetRSSI,
    );

    // Cargar lista de habitaciones
    final roomsJson = prefs.getString('saved_rooms_list');
    List<Room> rooms = [];
    if (roomsJson != null) {
      final List<dynamic> decoded = jsonDecode(roomsJson);
      rooms = decoded.map((item) => Room.fromJson(item)).toList();
    }

    // Actualizar o Añadir
    final index = rooms.indexWhere((r) => r.id == _roomId);
    if (index != -1) {
      rooms[index] = room;
    } else {
      rooms.add(room);
    }

    // Guardar lista
    await prefs.setString('saved_rooms_list', jsonEncode(rooms.map((r) => r.toJson()).toList()));
    
    // Mantener compatibilidad con modo único si es necesario
    final data = {
      'floor': selectedFloor,
      'type': selectedRoomType.index,
      'assets': currentAssets.map((a) => a.toJson()).toList(),
      'ssid': targetSSID,
      'rssi': targetRSSI,
    };
    await prefs.setString('saved_room_3d', jsonEncode(data));
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_room_3d');
    if (saved != null) {
      try {
        final data = jsonDecode(saved);
        if (mounted) {
          setState(() {
            selectedFloor = data['floor'] ?? 'PB';
            
            // Validación robusta de RoomType
            selectedRoomType = RoomType.bedroom;
            if (data['type'] != null) {
              int typeIndex = data['type'] as int;
              if (typeIndex >= 0 && typeIndex < RoomType.values.length) {
                selectedRoomType = RoomType.values[typeIndex];
              }
            }
            
            // Validación robusta de assets
            if (data['assets'] != null && data['assets'] is List) {
              currentAssets = (data['assets'] as List)
                  .map((a) => FurnitureAsset.fromJson(a as Map<String, dynamic>))
                  .toList();
            } else {
              currentAssets = [];
            }

            targetSSID = data['ssid'];
            targetRSSI = data['rssi'];
          });
        }
        _loadUserProfile(); // Recalcular contador de notas
      } catch (e) {
        debugPrint('Error cargando datos locales: $e');
        // Si hay error en el JSON, limpiamos para evitar crashes infinitos
        // await prefs.remove('saved_room_3d'); 
      }
    }
  }

  void _linkWifiSignal() {
    setState(() {
      targetSSID = _wifiService.currentSSID;
      targetRSSI = _wifiService.currentRSSI;
    });
    _saveToLocal();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sala vinculada a: $targetSSID ($targetRSSI dBm)')),
    );
  }

  Future<void> _addAssetFromRegistry(int modelId) async {
    final subscription = await UserSubscription.load();
    if (!subscription.isPremium && currentAssets.length >= subscription.maxObjects) {
      _showUnlockObjectDialog();
      return;
    }

    setState(() {
      final newAsset = AssetRegistry.createAsset(modelId, v.Vector3(0, 0, 0));
      currentAssets.add(newAsset);
    });
    _saveToLocal();
  }

  void _showUnlockObjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: CyberTheme.neonCyan), borderRadius: BorderRadius.circular(20)),
        title: const Text('LÍMITE ALCANZADO', style: TextStyle(color: CyberTheme.neonCyan, fontFamily: 'Orbitron', fontSize: 16)),
        content: const Text('Has alcanzado el límite de objetos gratuitos. Puedes ver 3 anuncios para desbloquear uno nuevo o pasarte a Premium.', 
          style: TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _simulateAd(isForUnlock: true);
            },
            child: const Text('VER ANUNCIO', style: TextStyle(color: CyberTheme.neonGreen, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonPurple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen())).then((_) => _loadUserProfile());
            },
            child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateAd({bool isForUnlock = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: CyberTheme.neonGreen),
            SizedBox(height: 20),
            Text('REPRODUCIENDO ANUNCIO...', style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 12)),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));
    Navigator.pop(context);

    final sub = await UserSubscription.load();
    if (isForUnlock) {
      bool unlocked = sub.watchAdForUnlock();
      if (unlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡NUEVO OBJETO DESBLOQUEADO!'), backgroundColor: CyberTheme.neonGreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anuncio visto (${sub.adsWatchedForUnlock}/3 para desbloquear)')),
        );
      }
    } else {
      sub.watchAdForNote();
    }
  }

  void _rotateAsset(FurnitureAsset asset) {
    setState(() {
      final index = currentAssets.indexOf(asset);
      final newRotation = (asset.rotation + 90) % 360;
      currentAssets[index] = asset.copyWith(rotation: newRotation);
    });
    _saveToLocal();
  }

  void _deleteAsset(FurnitureAsset asset) {
    setState(() {
      currentAssets.removeWhere((a) => a.id == asset.id);
      selectedAsset = null;
    });
    _saveToLocal();
  }

  void _clearScene() {
    setState(() {
      currentAssets = [];
      selectedAsset = null;
      targetSSID = null;
      targetRSSI = null;
    });
    _saveToLocal();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Escena limpiada. Listo para nueva habitación.')),
    );
  }

  void _finishRoom() async {
    // 1. Capturar Firma Wi-Fi final
    final ssid = _wifiService.currentSSID;
    final rssi = _wifiService.currentRSSI;
    
    // 2. Abrir grabadora 360
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisionRecorderScreen(
          assetName: 'Habitación $selectedRoomType',
          isRoom360: true,
        ),
      ),
    );

    if (result != null && result is Map) {
      final videoPath = result['videoPath'];
      // final gyroData = result['gyroData']; // En el futuro se usa para alinear

      if (mounted) {
        setState(() {
          targetSSID = ssid;
          targetRSSI = rssi;
        });
      }

      // 3. Guardar todo el paquete
      await _saveToLocal();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text('HABITACIÓN FINALIZADA', style: TextStyle(color: CyberTheme.neonGreen, fontFamily: 'Orbitron')),
            content: Text('Modelo 3D, Video 360 y Firma Wi-Fi ($ssid) guardados correctamente.', style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearScene();
                },
                child: const Text('NUEVA HABITACIÓN', style: TextStyle(color: CyberTheme.neonCyan)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CONTINUAR EDITANDO', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _openVisionRecorder(FurnitureAsset asset) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisionRecorderScreen(assetName: asset.name),
      ),
    );

    if (result != null && result is Map) {
      final videoPath = result['videoPath'];
      if (mounted) {
        setState(() {
          final index = currentAssets.indexWhere((a) => a.id == asset.id);
          if (index != -1) {
            currentAssets[index] = asset.copyWith(videoPath: videoPath);
            selectedAsset = currentAssets[index];
          }
        });
      }
      _saveToLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: !isOrbiting ? _buildAppBar() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF0A0015), // Púrpura muy oscuro
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Efecto de Nebulosa (simulado con partículas o sombras)
            _buildNebulaBackground(),
            
            is3DView 
              ? Scene3DView(
                  assets: currentAssets,
                  isInspectionMode: isOrbiting,
                  onAssetSelected: (asset) {
                    setState(() => selectedAsset = asset);
                  },
                )
              : Canvas2D(
                  assets: currentAssets,
                  isEditMode: isEditMode,
                  onAssetMoved: (asset, newPos) {
                    setState(() {
                      final index = currentAssets.indexWhere((a) => a.id == asset.id);
                      currentAssets[index] = asset.copyWith(
                        position: v.Vector3(newPos.dx, 0, newPos.dy)
                      );
                    });
                    _saveToLocal();
                  },
                  onAssetSelected: (asset) => setState(() => selectedAsset = asset),
                  onAssetRotate: _rotateAsset,
                ),
            
            if (isEditMode && !isOrbiting) _buildCatalog(),
            if (!isOrbiting) _buildHUDControls(),
            
            // Botón para alternar órbita (Inspección 360)
            if (is3DView)
              Positioned(
                top: isOrbiting ? 20 : 10,
                left: 20,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: isOrbiting ? CyberTheme.neonGreen : CyberTheme.accentColor,
                  child: Icon(isOrbiting ? Icons.stop : Icons.rotate_right, color: Colors.white),
                  onPressed: () => setState(() => isOrbiting = !isOrbiting),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNebulaBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Pulso neón central
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(seconds: 4),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 300 * value,
                  height: 300 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.neonPurple.withOpacity(0.05 * (2 - value)),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                );
              },
              onEnd: () {}, // Se repite por el builder si se gestiona estado, pero aquí es sutil
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('GHOST NOTES', 
        style: TextStyle(fontFamily: 'Orbitron', letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, color: CyberTheme.neonGreen)),
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: _showProfileStatsPanel,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CyberTheme.neonCyan, width: 2),
              boxShadow: [
                BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(_getAvatarIcon(_userAvatar), color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: CyberTheme.neonCyan),
          tooltip: 'Ver Tutorial',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen(forceTutorial: true)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.play_circle_fill, color: Colors.orangeAccent),
          tooltip: 'Ver Demo 3D',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomDemoScreen()),
          ),
        ),
        IconButton(
          icon: Icon(is3DView ? Icons.grid_view : Icons.view_in_ar, color: CyberTheme.neonCyan),
          onPressed: () => setState(() {
            is3DView = !is3DView;
            selectedAsset = null;
          }),
        ),
      ],
    );
  }

  void _showProfileStatsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: CyberTheme.neonCyan.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CyberTheme.neonCyan, width: 2),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black,
                child: Icon(_getAvatarIcon(_userAvatar), color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _userName.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'Orbitron'),
            ),
            const SizedBox(height: 10),
            const Text(
              'MEMORIA DE LA CASA ACTIVADA',
              style: TextStyle(color: CyberTheme.neonCyan, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('GHOST NOTES', _totalNotesCount.toString(), CyberTheme.neonGreen),
                _buildStatItem('SALA', selectedRoomType.name.toUpperCase(), CyberTheme.neonPurple),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileRegistrationScreen(isEditing: true)),
                      );
                      if (result == true) {
                        _loadUserProfile();
                      }
                    },
                    icon: const Icon(Icons.edit, color: CyberTheme.neonCyan),
                    label: const Text('EDITAR PERFIL', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CyberTheme.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildHUDControls() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'mode_btn',
            backgroundColor: CyberTheme.accentColor,
            child: Icon(isEditMode ? Icons.remove_red_eye : Icons.architecture, color: isEditMode ? CyberTheme.neonGreen : CyberTheme.neonPurple),
            onPressed: () => setState(() {
              isEditMode = !isEditMode;
              selectedAsset = null;
            }),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            mini: true,
            heroTag: 'finish_btn',
            backgroundColor: CyberTheme.neonGreen,
            child: const Icon(Icons.check, color: Colors.black),
            onPressed: _finishRoom,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'wifi_btn',
            backgroundColor: CyberTheme.neonCyan,
            child: const Icon(Icons.wifi, color: Colors.black),
            onPressed: _linkWifiSignal,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 110,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border(top: BorderSide(color: CyberTheme.neonCyan.withOpacity(0.5))),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          children: AssetRegistry.models.entries.map((entry) {
            final model = entry.value;
            return GestureDetector(
              onTap: () => _addAssetFromRegistry(entry.key),
              child: Container(
                width: 90,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: CyberTheme.accentColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CyberTheme.neonCyan.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.view_in_ar, color: CyberTheme.neonCyan, size: 30),
                    const SizedBox(height: 4),
                    Text(model['name'], 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAssetInfo() {
    if (selectedAsset == null) {
      return const Center(child: Text('Toca un mueble para ver su info', style: TextStyle(color: Colors.grey, fontSize: 12)));
    }
    
    // Si no está anclado, forzar registro en realidad
    if (!selectedAsset!.isAnchored) {
      return _buildAnchoringRequirement();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, border: Border.all(color: selectedAsset!.color), borderRadius: BorderRadius.circular(4)),
            child: Column(
              children: [
                Icon(selectedAsset!.icon, color: selectedAsset!.color, size: 32),
                const SizedBox(height: 8),
                Text(selectedAsset!.name, style: TextStyle(color: selectedAsset!.color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Posición:', 'X: ${(selectedAsset!.position.x).toStringAsFixed(2)}m, Y: ${(selectedAsset!.position.z).toStringAsFixed(2)}m'),
          _infoRow('Dimensiones:', '${selectedAsset!.dimensions.width}x${selectedAsset!.dimensions.depth}m'),
          _infoRow('Sincronización:', selectedAsset!.isSynced ? 'ACTIVA (ADN PROCESADO)' : 'PENDIENTE'),
          const Spacer(),
          // Notas con restricción de lectura en 3D
          _buildNotesSection(),
          const SizedBox(height: 8),
          if (!selectedAsset!.isSynced)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openVisionRecorder(selectedAsset!),
                icon: const Icon(Icons.videocam),
                label: const Text('REGISTRAR VISIÓN'),
                style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonCyan.withOpacity(0.2), foregroundColor: CyberTheme.neonCyan, side: BorderSide(color: CyberTheme.neonCyan)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.greenAccent)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  const Text('VISIÓN SINCRONIZADA', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openVisionRecorder(selectedAsset!),
                    child: const Text('REGRABAR', style: TextStyle(color: Colors.white54, fontSize: 9)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deleteAsset(selectedAsset!),
              icon: const Icon(Icons.delete),
              label: const Text('ELIMINAR'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchoringRequirement() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person, color: Colors.redAccent, size: 48),
          const SizedBox(height: 20),
          const Text(
            'PASO CERO REQUERIDO',
            style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Este mueble aún no existe en el mundo físico. Debes realizar la caminata de calibración para anclarlo a la realidad.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _startAnchoringProcess(selectedAsset!),
            icon: const Icon(Icons.directions_walk),
            label: const Text('CALIBRAR EN REALIDAD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _startAnchoringProcess(FurnitureAsset asset) async {
    // Simular proceso de calibración (Pasos + Wi-Fi + Giro)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisionRecorderScreen(
          assetName: asset.name,
          isAnchoringOnly: true, // Nuevo flag para solo anclaje
        ),
      ),
    );

    if (result == true) {
      setState(() {
        final index = currentAssets.indexWhere((a) => a.id == asset.id);
        if (index != -1) {
          currentAssets[index] = asset.copyWith(isAnchored: true);
          selectedAsset = currentAssets[index];
        }
      });
      _saveToLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CyberTheme.neonGreen,
          content: Text('Mueble "${asset.name}" anclado correctamente a la realidad.'),
        ),
      );
    }
  }

  Widget _buildNotesSection() {
    final notes = selectedAsset!.notes;
    final hasUnread = selectedAsset!.hasUnreadNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('NOTAS GHOST', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1)),
            const Spacer(),
            if (hasUnread)
              _buildNeonBadge('NEW', CyberTheme.neonGreen),
          ],
        ),
        const SizedBox(height: 12),
        // Lista de Avatares y Moods (Solo info, contenido bloqueado)
        if (notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final isMyNote = note.authorName == _userName;
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: note.mood == NoteMood.joy ? CyberTheme.neonGreen : Colors.redAccent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (note.mood == NoteMood.joy ? CyberTheme.neonGreen : Colors.redAccent).withOpacity(0.3),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black,
                      child: Icon(
                        _getAvatarIcon(note.authorAvatar),
                        color: isMyNote ? Colors.white : Colors.white70,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.black.withOpacity(0.9),
                content: Text(
                  'CONTENIDO MATERIALIZADO EN LA REALIDAD.\nAcercate a ${selectedRoomType.name.toUpperCase()} para revelar el mensaje.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CyberTheme.neonCyan, fontFamily: 'Orbitron', fontSize: 10, letterSpacing: 1),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            height: 100, // Un poco más pequeño para dar espacio a los avatares
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: CyberTheme.neonCyan.withOpacity(0.1)),
            ),
            child: Stack(
              children: [
                // Fondo con patrón de rejilla técnica
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(color: CyberTheme.neonCyan.withOpacity(0.05)),
                  ),
                ),
                
                // Contenido borroso simulado
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        color: Colors.black.withOpacity(0.4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_person, color: CyberTheme.neonCyan, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'CONTENIDO ENCRIPTADO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CyberTheme.neonCyan, 
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                fontFamily: 'Orbitron'
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Acceso exclusivo desde el Espejo Virtual',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createNewNote(selectedAsset!),
            icon: const Icon(Icons.add_comment, size: 18),
            label: const Text('ESCRIBIR NOTA GHOST', style: TextStyle(fontFamily: 'Orbitron', fontSize: 10, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.neonPurple.withOpacity(0.1),
              foregroundColor: CyberTheme.neonPurple,
              side: const BorderSide(color: CyberTheme.neonPurple, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeonBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4)],
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

  void _createNewNote(FurnitureAsset asset) {
    // REGLA: La primera nota DEBE ser en la realidad (Paso Cero)
    if (!asset.isAnchored || asset.notes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('PASO CERO REQUERIDO', 
            style: TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron', fontSize: 16)),
          content: const Text(
            'La primera huella de este objeto debe registrarse en la realidad física.\n\n'
            'Realizá la caminata de calibración y creá tu primer Ghost Note frente al mueble real.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openVisionRecorderForAnchoring(asset);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('IR A LA REALIDAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Si ya está anclado y tiene notas, puede crear directamente en la maqueta
    _showNoteEditorDialog(asset);
  }

  void _openVisionRecorderForAnchoring(FurnitureAsset asset) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisionRecorderScreen(
          assetName: asset.name,
          isAnchoringOnly: true,
        ),
      ),
    );

    if (result != null && result is Map) {
      final photoPath = result['photoPath'];
      // Anclaje exitoso, ahora marcar como anclado y guardar la foto
      setState(() {
        final index = currentAssets.indexWhere((a) => a.id == asset.id);
        if (index != -1) {
          currentAssets[index] = asset.copyWith(
            isAnchored: true,
            initialPhotoPath: photoPath,
          );
          selectedAsset = currentAssets[index];
        }
      });
      await _saveToLocal();

      // Redirigir al visor con el asset seleccionado para que cree la primera nota
      // con la referencia visual ya guardada.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ANCLAJE EXITOSO. Foto de referencia guardada.', 
              style: TextStyle(color: CyberTheme.neonGreen)),
            backgroundColor: Colors.black87,
          ),
        );
        
        // Aquí podríamos abrir automáticamente el NoteViewer o el editor de la primera nota
        _showNoteEditorDialog(selectedAsset!);
      }
    }
  }

  void _showNoteEditorDialog(FurnitureAsset asset) {
    final TextEditingController _controller = TextEditingController();
    NoteMood _selectedMood = NoteMood.joy;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: CyberTheme.neonPurple.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('NUEVA NOTA GHOST', style: TextStyle(color: CyberTheme.neonPurple, fontFamily: 'Orbitron', fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje aquí...',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonPurple)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ESTADO DE ÁNIMO', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ToggleButtons(
                    isSelected: [_selectedMood == NoteMood.joy, _selectedMood == NoteMood.fear],
                    onPressed: (index) {
                      setModalState(() {
                        _selectedMood = index == 0 ? NoteMood.joy : NoteMood.fear;
                      });
                    },
                    fillColor: _selectedMood == NoteMood.joy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    selectedColor: _selectedMood == NoteMood.joy ? Colors.greenAccent : Colors.redAccent,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.sentiment_very_satisfied)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.sentiment_very_dissatisfied)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addNoteToAsset(asset, _controller.text, _selectedMood);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonPurple, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text('MATERIALIZAR NOTA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _addNoteToAsset(FurnitureAsset asset, String content, NoteMood mood) {
    final newNote = GhostNote(
      id: const Uuid().v4(),
      furnitureId: asset.id,
      content: content,
      authorName: _userName,
      authorAvatar: _userAvatar,
      theme: NoteTheme.PRO, // Por defecto
      mood: mood,
      fontSize: 14.0,
      neonColor: mood == NoteMood.joy ? CyberTheme.neonGreen : Colors.redAccent,
      createdAt: DateTime.now(),
    );

    setState(() {
      final index = currentAssets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        final updatedNotes = List<GhostNote>.from(currentAssets[index].notes)..add(newNote);
        currentAssets[index] = currentAssets[index].copyWith(notes: updatedNotes);
        selectedAsset = currentAssets[index];
      }
    });
    _saveToLocal();
    _loadUserProfile(); // Actualizar contador total
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
