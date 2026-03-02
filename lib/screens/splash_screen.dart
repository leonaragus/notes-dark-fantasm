import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_gallery_screen.dart';
import 'profile_registration_screen.dart';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart'; // <-- AÑADIDO: para reproducir sonidos

// --- MEJORA: Textos externalizados para fácil mantenimiento ---
class _TutorialStrings {
  static const String designTitle = "DISEÑO";
  static const String designSubtitle = "Crea la maqueta digital de tu casa";
  static const String syncTitle = "SINCRONIZACIÓN";
  static const String syncSubtitle = "Sincroniza el 3D con tu cámara";
  static const String resultTitle = "RESULTADO";
  static const String resultSubtitle = "Mensajes neón que flotan en tu espacio";
  static const String welcomeTitle = "TU CASA AHORA TIENE MEMORIA";
  static const String welcomeSubtitle = "Bienvenido al Espejo Virtual";
}


class SplashScreen extends StatefulWidget {
  final bool forceTutorial;
  const SplashScreen({Key? key, this.forceTutorial = false}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController; // MEJORA: Controlador para partículas
  late AudioPlayer _audioPlayer; // <-- AÑADIDO: reproductor de audio
  
  int _currentAct = 0; // 0: Logo, 1: Diseño, 2: Sincronización, 3: Resultado, 4: Welcome
  bool _tutorialSkipped = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _audioPlayer = AudioPlayer(); // <-- AÑADIDO: inicializar el reproductor

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstOpen();
    });
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
        if (!mounted) return;
        _runTutorialActs();
      });
    });
  }
  
  void _startFastPath() {
    _logoController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () => _skipTutorial());
    });
  }

  void _runTutorialActs() async {
    for (int i = 1; i <= 4; i++) {
      if (!mounted || _tutorialSkipped) return;
      setState(() => _currentAct = i);
      await Future.delayed(const Duration(milliseconds: 1200)); 
    }
    if (!_tutorialSkipped) {
      _nextStep();
    }
  }
  
  void _skipTutorial() {
    if (_tutorialSkipped) return;
    setState(() {
      _tutorialSkipped = true;
    });
    _nextStep();
  }

  Future<void> _nextStep() async {
    final prefs = await SharedPreferences.getInstance();
    bool profileCompleted = prefs.getBool('profile_completed') ?? false;

    if (!mounted) return;

    final targetScreen = profileCompleted ? const HomeGalleryScreen() : const ProfileRegistrationScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _audioPlayer.dispose(); // <-- AÑADIDO: liberar el reproductor de audio
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _BackgroundParticles(controller: _particleController)),
          
          Center(
            child: _currentAct == 0 
              ? _buildLogo()
              : _buildTutorialContent(),
          ),

          if (_currentAct > 0 && _currentAct <= 4 && !_tutorialSkipped)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: const Text(
                    'Saltar',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
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
      case 1:
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
      case 2:
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
      case 3:
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
      case 4:
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
        title = _TutorialStrings.designTitle;
        subtitle = _TutorialStrings.designSubtitle;
        break;
      case 2:
        title = _TutorialStrings.syncTitle;
        subtitle = _TutorialStrings.syncSubtitle;
        break;
      case 3:
        title = _TutorialStrings.resultTitle;
        subtitle = _TutorialStrings.resultSubtitle;
        _playEnergySound();
        break;
      case 4:
        title = _TutorialStrings.welcomeTitle;
        subtitle = _TutorialStrings.welcomeSubtitle;
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
    // <-- MEJORA: ahora reproduce un sonido real
    try {
      _audioPlayer.play(AssetSource('sounds/energy_sound.wav'));
    } catch (e) {
      debugPrint("Error al reproducir el sonido: $e");
    }
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

class _BackgroundParticles extends StatefulWidget {
  final AnimationController controller;
  const _BackgroundParticles({required this.controller});

  @override
  __BackgroundParticlesState createState() => __BackgroundParticlesState();
}

class __BackgroundParticlesState extends State<_BackgroundParticles> {
    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(widget.controller.value),
          );
        },
      );
    }
}

class _Particle {
  final double x, y, radius, initialPhase;
  _Particle({required this.x, required this.y, required this.radius, required this.initialPhase});
}

class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<_Particle> _particles;
  final Random _random = Random(12345);

  _ParticlePainter(this.animationValue) : _particles = [] {
    for (var i = 0; i < 40; i++) {
        final x = _random.nextDouble();
        final y = _random.nextDouble();
        final radius = _random.nextDouble() * 2 + 1;
        final initialPhase = _random.nextDouble() * pi * 2;
        _particles.add(_Particle(x: x, y: y, radius: radius, initialPhase: initialPhase));
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyanAccent.withOpacity(0.08);

    for (final particle in _particles) {
      final currentX = particle.x * size.width;
      final currentY = particle.y * size.height;
      
      final offsetX = cos(animationValue * 2 * pi + particle.initialPhase) * 10;
      final offsetY = sin(animationValue * 2 * pi + particle.initialPhase) * 10;
      
      canvas.drawCircle(Offset(currentX + offsetX, currentY + offsetY), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}