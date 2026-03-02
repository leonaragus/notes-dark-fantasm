import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();

    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    }, onDone: () {
      _purchaseSubscription.cancel();
    }, onError: (error) {
      _showErrorSnackbar('Ocurrió un error en el stream de compras.');
    });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _showSuccessSnackbar('¡Suscripción activada! Bienvenido a Premium.');
        _loadSubscription();
      } else if (purchase.status == PurchaseStatus.error) {
        _showErrorSnackbar('Error durante la compra.');
      }
    }
    if (_isLoading) {
        setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadSubscription() async {
    final sub = await UserSubscription.load();
    if (mounted) {
      setState(() {
        _subscription = sub;
        _isLoading = false;
      });
    }
  }

  Future<void> _upgrade() async {
    setState(() => _isLoading = true);
    try {
      await PaymentService().buyPremium();
    } catch (e) {
      _showErrorSnackbar('No se pudo iniciar el proceso de compra.');
    } finally {
      if(mounted && _isLoading) {
          Future.delayed(const Duration(milliseconds: 500), () => setState(() => _isLoading = false));
      }
    }
  }

  Future<void> _restorePurchases() async {
      setState(() => _isLoading = true);
      try {
        await InAppPurchase.instance.restorePurchases();
      } catch (e) {
        _showErrorSnackbar('Error al intentar restaurar las compras.');
      } finally {
          if(mounted && _isLoading) {
            Future.delayed(const Duration(milliseconds: 500), () => setState(() => _isLoading = false));
        }
      }
  }

  void _showErrorSnackbar(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
  }

  void _showSuccessSnackbar(String message) {
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: CyberTheme.neonPurple),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !this.mounted) {
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
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: const Text('Restaurar', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCurrentPlanCard(),
                const SizedBox(height: 30),
                // --- MEJORA: Textos del plan gratuito actualizados ---
                _buildPlanOption(
                  title: 'FREE',
                  price: 'GRATIS',
                  color: CyberTheme.neonCyan,
                  features: [
                    'Ver todo el inventario de objetos',
                    'Coloca hasta 4 objetos por escena',
                    'Crea tus 2 primeros mensajes sin anuncios',
                    'Requiere un anuncio para cada nuevo mensaje',
                  ],
                  isCurrent: !_subscription.isPremium,
                ),
                const SizedBox(height: 20),
                // --- MEJORA: Precio y textos del plan premium actualizados ---
                _buildPlanOption(
                  title: 'PREMIUM',
                  price: '\$3 / MES',
                  color: CyberTheme.neonPurple,
                  features: [
                    'Habitaciones y objetos ilimitados',
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: CyberTheme.neonPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (_subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan, width: 2),
        boxShadow: [
          BoxShadow(
            color: (_subscription.isPremium ? CyberTheme.neonPurple : CyberTheme.neonCyan).withOpacity(0.2),
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
              'Objetos colocados: 0/4', // Esto es un ejemplo, la lógica real está en el editor
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              'Mensajes sin anuncios creados: ${_subscription.notesCreatedCount}/2',
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
          color: Colors.white.withOpacity(0.05),
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
