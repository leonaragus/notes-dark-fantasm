import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // --- MEJORA: ID de producto actualizado a 3 USD ---
  static const String premiumId = 'premium_subscription_3usd';

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Manejar error
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // La UI ahora muestra su propio indicador de carga
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // La UI ahora muestra el error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // --- VALIDACIÓN DE RECIBO (Futura Mejora) ---
          // bool isValid = await _verifyPurchase(purchaseDetails.verificationData.serverVerificationData);
          // if (isValid) { ... }

          final sub = await UserSubscription.load();
          if (!sub.isPremium) {
            sub.upgradeToPremium();
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> buyPremium() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      throw 'La tienda de aplicaciones no está disponible.';
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails({premiumId});
    if (response.notFoundIDs.isNotEmpty) {
      throw 'El producto de suscripción no se encontró. Asegúrate de que esté configurado en la Play Console.';
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription.cancel();
  }
}
