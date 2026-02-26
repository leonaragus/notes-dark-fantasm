import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'editor_screen.dart';

class ProfileRegistrationScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileRegistrationScreen({Key? key, this.isEditing = false}) : super(key: key);

  @override
  _ProfileRegistrationScreenState createState() => _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedAvatar = 'person';
  
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      final age = prefs.getInt('user_age');
      _ageController.text = age?.toString() ?? '';
      _selectedAvatar = prefs.getString('user_avatar') ?? 'person';
    });
  }
  
  void _updateAvatar(String ageStr) {
    int age = int.tryParse(ageStr) ?? 25;
    setState(() {
      if (age <= 13) {
        _selectedAvatar = 'child_care';
      } else if (age <= 23) {
        _selectedAvatar = 'rocket';
      } else if (age <= 55) {
        _selectedAvatar = 'account_circle';
      } else {
        _selectedAvatar = 'volunteer_activism';
      }
    });
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final age = int.tryParse(ageStr);

    if (name.isEmpty || ageStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una edad válida')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_age', age);
    await prefs.setString('user_avatar', _selectedAvatar);
    await prefs.setBool('profile_completed', true);

    if (mounted) {
      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EditorScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo animado sutil (reutilizando partículas)
          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileBackgroundPainter(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TU IDENTIDAD',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        if (widget.isEditing)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white54),
                          ),
                        const SizedBox(height: 30),
                        // Avatar dinámico
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Icon(
                            _getAvatarIcon(_selectedAvatar),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          controller: _nameController,
                          label: 'NOMBRE',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _ageController,
                          label: 'EDAD',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          onChanged: _updateAvatar,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 10,
                            shadowColor: Colors.cyanAccent.withOpacity(0.5),
                          ),
                          child: Text(
                            widget.isEditing ? 'GUARDAR' : 'COMENZAR',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
      ),
    );
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyanAccent.withOpacity(0.03);
    for (var i = 0; i < 15; i++) {
      canvas.drawCircle(
        Offset(size.width * (i / 15), size.height * (i / 15)),
        100 + (i * 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
