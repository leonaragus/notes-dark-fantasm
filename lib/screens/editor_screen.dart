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
import 'splash_screen.dart';
import 'profile_registration_screen.dart';
import '../logic/game_rules.dart'; // <-- IMPORTAMOS LAS REGLAS

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
  bool isEditMode = true;
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
    } else {
      _roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      _loadFromLocal();
    }
    _loadUserProfile();
    _wifiService.startScanning();
    _setupAlertMonitoring();
  }

  // ... (el resto de los métodos iniciales como dispose, setupAlertMonitoring, etc. se mantienen igual)
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Invitado';
        _userAvatar = prefs.getString('user_avatar') ?? 'person';
        _totalNotesCount = currentAssets.fold(0, (sum, asset) => sum + asset.notes.length);
      });
    }
  }

  @override
  void dispose() {
    _wifiService.stopScanning();
    super.dispose();
  }

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
    final room = Room(
      id: _roomId,
      floorLevel: selectedFloor,
      type: selectedRoomType,
      assets: currentAssets,
      targetSSID: targetSSID,
      targetRSSI: targetRSSI,
    );
    final roomsJson = prefs.getString('saved_rooms_list');
    List<Room> rooms = [];
    if (roomsJson != null) {
      rooms = (jsonDecode(roomsJson) as List).map((item) => Room.fromJson(item)).toList();
    }
    final index = rooms.indexWhere((r) => r.id == _roomId);
    if (index != -1) {
      rooms[index] = room;
    } else {
      rooms.add(room);
    }
    await prefs.setString('saved_rooms_list', jsonEncode(rooms.map((r) => r.toJson()).toList()));
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
            selectedRoomType = RoomType.values[data['type'] ?? 0];
            currentAssets = (data['assets'] as List).map((a) => FurnitureAsset.fromJson(a)).toList();
            targetSSID = data['ssid'];
            targetRSSI = data['rssi'];
          });
        }
        _loadUserProfile();
      } catch (e) {
        debugPrint('Error loading local data: $e');
      }
    }
  }
  
  // --- REFACTORIZADO --- 
  Future<void> _addAssetFromRegistry(int modelId) async {
    final subscription = await UserSubscription.load();

    if (!GameRules.canAddMoreObjects(subscription, currentAssets.length)) {
      _showUpgradeDialog(
          'LÍMITE DE OBJETOS ALCANZADO',
          'Has alcanzado el límite de ${GameRules.free_maxObjectsPerRoom} objetos para el plan gratuito. Actualiza a Premium para añadir objetos ilimitados.');
      return;
    }

    setState(() {
      final newAsset = AssetRegistry.createAsset(modelId, v.Vector3(0, 0, 0));
      currentAssets.add(newAsset);
    });
    _saveToLocal();
  }

  // --- REFACTORIZADO Y UNIFICADO ---
  void _showUpgradeDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: CyberTheme.neonPurple), borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: CyberTheme.neonPurple, fontFamily: 'Orbitron', fontSize: 16)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonPurple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen())).then((_) => _loadUserProfile());
            },
            child: const Text('MEJORAR PLAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- REFACTORIZADO --- 
  Future<void> _simulateAd() async {
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

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context); // Cierra el diálogo de progreso

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Gracias por ver! Ahora puedes crear tu nota.'), backgroundColor: CyberTheme.neonGreen),
    );
  }

  // --- NUEVO --- 
  Future<bool> _showAdForNoteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: CyberTheme.neonGreen), borderRadius: BorderRadius.circular(20)),
        title: const Text('NOTA EXTRA', style: TextStyle(color: CyberTheme.neonGreen, fontFamily: 'Orbitron', fontSize: 16)),
        content: const Text('Has alcanzado el límite de ${GameRules.free_notesBeforeAd} notas gratuitas. ¡Mira un anuncio corto para crear otra!',
          style: TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonGreen),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('VER ANUNCIO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- REFACTORIZADO CON LÓGICA DE ANUNCIOS ---
  Future<void> _createNewNote(FurnitureAsset asset) async {
    if (!asset.isAnchored) {
      // ... (La lógica de anclaje se mantiene)
      return;
    }

    final subscription = await UserSubscription.load();
    if (GameRules.requiresAdForNextNote(subscription)) {
      final wantsToWatchAd = await _showAdForNoteDialog();
      if (wantsToWatchAd) {
        await _simulateAd();
        subscription.recordAdWatchedForNote(); 
      } else {
        return; // El usuario canceló.
      }
    }
    
    _showNoteEditorDialog(asset);
  }

  // --- REFACTORIZADO CON REGISTRO DE CREACIÓN ---
  void _addNoteToAsset(FurnitureAsset asset, String content, NoteMood mood) async {
    final subscription = await UserSubscription.load();
    subscription.recordNoteCreation(); // <-- REGISTRA LA CREACIÓN DE LA NOTA

    final newNote = GhostNote(
      id: const Uuid().v4(),
      furnitureId: asset.id,
      content: content,
      authorName: _userName,
      authorAvatar: _userAvatar,
      theme: NoteTheme.PRO, 
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
    _loadUserProfile();
  }

  // ... (El resto del archivo, incluyendo build(), _buildAppBar(), _showNoteEditorDialog(), etc. se mantienen sin cambios)

}
