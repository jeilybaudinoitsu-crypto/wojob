import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:wojob/data/models/empresa.dart';

class StripeCheckoutException implements Exception {
  const StripeCheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

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

    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'create-checkout-session',
        body: {'plan': plan.dbValue, 'platform': kIsWeb ? 'web' : 'android'},
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : error.status == 0
          ? 'No se pudo conectar con la función de pago de Supabase.'
          : 'La función de pago respondió con HTTP ${error.status}.';
      throw StripeCheckoutException(message);
    }
    if (response.status < 200 || response.status >= 300) {
      throw const StripeCheckoutException('Supabase no pudo iniciar el pago.');
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
