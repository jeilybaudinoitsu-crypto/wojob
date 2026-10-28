import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wojob/data/repositories/shared_preferences_first_run_repository.dart';
import 'package:wojob/data/repositories/shared_preferences_terms_acceptance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('el primer inicio se considera pendiente hasta completarlo', () async {
    final repository = SharedPreferencesFirstRunRepository();

    expect(await repository.isFirstRun(), isTrue);

    await repository.completeFirstRun();

    expect(await repository.isFirstRun(), isFalse);
  });

  test('la aceptación de términos se conserva localmente', () async {
    final repository = SharedPreferencesTermsAcceptanceRepository();

    expect(await repository.hasAcceptedTerms(), isFalse);

    await repository.acceptTerms();

    expect(await repository.hasAcceptedTerms(), isTrue);
  });
}
