import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wojob/data/models/empresa.dart';

/// Starts a subscription checkout without exposing Stripe credentials to Flutter.
class StripeCheckoutRepository {
  StripeCheckoutRepository(this._client);

  final SupabaseClient _client;

  Future<Uri> createCheckoutSession(PlanSuscripcion plan) async {
    if (plan == PlanSuscripcion.free) {
      throw ArgumentError.value(
        plan,
        'plan',
        'El plan gratuito no requiere pago.',
      );
    }

    final response = await _client.functions.invoke(
      'create-checkout-session',
      body: {'plan': plan.dbValue},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Supabase no pudo iniciar el pago.');
    }

    final data = response.data;
    if (data is! Map || data['url'] is! String) {
      throw const FormatException('Respuesta inválida al crear el pago.');
    }

    final checkoutUri = Uri.tryParse(data['url'] as String);
    if (checkoutUri == null ||
        checkoutUri.scheme != 'https' ||
        checkoutUri.host != 'checkout.stripe.com') {
      throw const FormatException('Stripe devolvió una URL de pago inválida.');
    }

    return checkoutUri;
  }
}
