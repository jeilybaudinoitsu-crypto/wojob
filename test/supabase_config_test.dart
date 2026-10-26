import 'package:flutter_test/flutter_test.dart';
import 'package:wojob/core/config/supabase_config.dart';

void main() {
  test('redacted Supabase keys are not treated as configured', () {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      anonKey: '******',
    );

    expect(config.isConfigured, isFalse);
  });

  test('valid Supabase config is accepted', () {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      anonKey: 'valid-anon-key',
    );

    expect(config.isConfigured, isTrue);
  });
}
