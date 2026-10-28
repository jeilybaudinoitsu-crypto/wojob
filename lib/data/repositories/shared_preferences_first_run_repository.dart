import 'package:shared_preferences/shared_preferences.dart';

import 'package:wojob/domain/repositories/repositories.dart';

class SharedPreferencesFirstRunRepository implements FirstRunRepository {
  static const _firstRunKey = 'is_first_run';

  @override
  Future<bool> isFirstRun() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_firstRunKey) ?? true;
  }

  @override
  Future<void> completeFirstRun() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_firstRunKey, false);
    if (!saved) {
      throw StateError('No se pudo guardar que el onboarding fue completado.');
    }
  }
}
