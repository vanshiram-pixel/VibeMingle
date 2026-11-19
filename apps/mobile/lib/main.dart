import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // VibeMingle production Supabase project (publishable key is safe for client apps).
  // Build-time dart-define values can override these defaults for staging/local builds.
  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jkalrdnimvoqmggydeuv.supabase.co',
  );
  const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_1rNuqIxSjicVZANNQU7MbQ_jnNorHtV',
  );
  if (url.isNotEmpty && publishableKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
  runApp(const VibeMingleApp());
}
