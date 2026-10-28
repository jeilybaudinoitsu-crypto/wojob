import 'package:shared_preferences/shared_preferences.dart';

import 'package:wojob/domain/repositories/repositories.dart';

class SharedPreferencesTermsAcceptanceRepository
    implements TermsAcceptanceRepository {
  static const _acceptedKey = 'terminos_aceptados';

  @override
  Future<bool> hasAcceptedTerms() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_acceptedKey) ?? false;
  }

  @override
  Future<void> acceptTerms() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_acceptedKey, true);
    if (!saved) {
      throw StateError('No se pudo guardar la aceptación de los términos.');
    }
  }
}
