import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../theme/cyber_theme.dart';
import '../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late UserSubscription _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final sub = await UserSubscription.load();
    setState(() {
      _subscription = sub;
      _isLoading = false;
    });
  }

  Future<void> _upgrade() async {
    setState(() => _isLoading = true);
    
    try {
      // Intentamos usar el servicio de Play Store
      final payment = PaymentService();
      await payment.buyPremium();
      
      // Nota: El cambio a Premium se manejará en el stream del PaymentService
      // pero por ahora dejamos esta simulación para que puedas probarlo sin la consola:
      await Future.delayed(const Duration(seconds: 1));
      _subscription.upgradeToPremium();
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡BIENVENIDO AL NIVEL PREMIUM!'),
            backgroundColor: CyberTheme.neonPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR EN LA TIENDA: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: CyberTheme.neonPurple)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('UPGRADE SYSTEM', style: TextStyle(fontFamily: 'Orbitron', letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCurrentPlanCard(),
            const SizedBox(height: 30),
            _buildPlanOption(
              title: 'FREE',
              price: 'GRATIS',
              color: CyberTheme.neonCyan,
              features: [
                '1 Habitación',
                '4 Objetos base',
                'Desbloquea objetos con anuncios',
                'Anuncios al crear notas',
              ],
              isCurrent: !_subscription.isPremium,
            ),
            const SizedBox(height: 20),
            _buildPlanOption(
              title: 'PREMIUM',
              price: '\$2 / MES',
              color: CyberTheme.neonPurple,
              features: [
                'Habitaciones ilimitadas',
                'Objetos ilimitados',
                'SIN ANUNCIOS',
                'Botón de compartir (IG, TikTok, WA)',
                'Soporte prioritario',
              ],
              isCurrent: _subscription.isPremium,
              onTap: _subscription.isPremium ? null : _upgrade,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (_subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan, width: 2),
        boxShadow: [
          BoxShadow(
            color: (_subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('ESTADO ACTUAL', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(
            _subscription.plan.name.toUpperCase(),
            style: TextStyle(
              color: _subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          if (!_subscription.isPremium) ...[
            const SizedBox(height: 15),
            Text(
              'Objetos: ${_subscription.baseObjects + _subscription.unlockedObjectsCount}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              'Anuncios para próximo objeto: ${_subscription.adsWatchedForUnlock}/3',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required Color color,
    required List<String> features,
    bool isCurrent = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isCurrent ? color : Colors.white10, width: isCurrent ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                Text(price, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: color, size: 16),
                  const SizedBox(width: 10),
                  Text(f, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            )),
            if (onTap != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'ACTIVAR AHORA',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                  ),
                ),
              ),
            ] else if (isCurrent) ...[
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'PLAN ACTUAL',
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
