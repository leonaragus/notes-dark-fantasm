import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_gallery_screen.dart';
import 'profile_registration_screen.dart'; // Importar registro de perfil
import 'dart:ui' as ui;

class SplashScreen extends StatefulWidget {
  final bool forceTutorial;
  const SplashScreen({Key? key, this.forceTutorial = false}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _tutorialController;
  
  int _currentAct = 0; // 0: Logo, 1: Diseño, 2: Sincronización, 3: Resultado, 4: Welcome

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _tutorialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _checkFirstOpen();
  }

  Future<void> _checkFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('app_open_count') ?? 0;
    
    if (widget.forceTutorial) {
      _startTutorial();
    } else if (count < 4) {
      await prefs.setInt('app_open_count', count + 1);
      _startTutorial();
    } else {
      _startFastPath();
    }
  }

  void _startTutorial() {
    _logoController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _runTutorialActs();
      });
    });
  }

  void _startFastPath() {
    _logoController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () => _nextStep());
    });
  }

  void _runTutorialActs() async {
    for (int i = 1; i <= 4; i++) {
      if (!mounted) return;
      setState(() => _currentAct = i);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    _nextStep();
  }

  Future<void> _nextStep() async {
    final prefs = await SharedPreferences.getInstance();
    bool profileCompleted = prefs.getBool('profile_completed') ?? false;

    if (!mounted) return;

    if (profileCompleted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeGalleryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileRegistrationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _tutorialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo de partículas sutiles
          const Positioned.fill(child: _BackgroundParticles()),
          
          Center(
            child: _currentAct == 0 
              ? _buildLogo()
              : _buildTutorialContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_logoController),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack)
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_fix_high, color: Colors.cyanAccent, size: 80),
            const SizedBox(height: 20),
            const Text('GHOST NOTES', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6)),
            const Text('REALIST', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Column(
        key: ValueKey(_currentAct),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActVisual(),
          const SizedBox(height: 40),
          _buildActText(),
        ],
      ),
    );
  }

  Widget _buildActVisual() {
    switch (_currentAct) {
      case 1: // Diseño
        return _TutorialActWrapper(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.grid_4x4, color: Colors.white10, size: 150),
              const Icon(Icons.kitchen, color: Colors.cyanAccent, size: 80),
              Positioned(
                bottom: 20, right: 20,
                child: Icon(Icons.touch_app, color: Colors.white.withOpacity(0.5), size: 40),
              ),
            ],
          ),
        );
      case 2: // Sincronización
        return _TutorialActWrapper(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Colors.white10, size: 150),
              const Icon(Icons.sync, color: Colors.cyanAccent, size: 80),
              const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1),
            ],
          ),
        );
      case 3: // Resultado
        return _TutorialActWrapper(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
                ),
              ),
              const Icon(Icons.sticky_note_2, color: Colors.pinkAccent, size: 80),
              const Text('❄️', style: TextStyle(fontSize: 40)),
            ],
          ),
        );
      case 4: // Welcome
        return const Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 100);
      default:
        return const SizedBox();
    }
  }

  Widget _buildActText() {
    String title = "";
    String subtitle = "";
    
    switch (_currentAct) {
      case 1:
        title = "DISEÑO";
        subtitle = "Crea la maqueta digital de tu casa";
        break;
      case 2:
        title = "SINCRONIZACIÓN";
        subtitle = "Sincroniza el 3D con tu cámara";
        break;
      case 3:
        title = "RESULTADO";
        subtitle = "Mensajes neón que flotan en tu espacio";
        _playEnergySound(); // Simular sonido de energía en el resultado final
        break;
      case 4:
        title = "TU CASA AHORA TIENE MEMORIA";
        subtitle = "Bienvenido al Espejo Virtual";
        break;
    }

    return Column(
      children: [
        Text(title, 
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'Orbitron')),
        const SizedBox(height: 12),
        Text(subtitle, 
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w300)),
      ],
    );
  }

  void _playEnergySound() {
    // Simulación de sonido de energía (Haptic feedback en ausencia de audio assets)
    // En una app real, aquí se usaría audioplayers para reproducir el asset de sonido.
    debugPrint("AUDIO: Energía activándose...");
  }
}

class _TutorialActWrapper extends StatelessWidget {
  final Widget child;
  const _TutorialActWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _BackgroundParticles extends StatelessWidget {
  const _BackgroundParticles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyanAccent.withOpacity(0.05);
    // Dibujo estático para el demo, se puede animar
    for (var i = 0; i < 20; i++) {
      canvas.drawCircle(Offset(size.width * (i/20), size.height * (i/20)), 2, paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
