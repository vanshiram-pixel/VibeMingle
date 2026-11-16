import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_mingle/src/app.dart';

void main() {
  testWidgets('shows actionable configuration error without secrets',
      (tester) async {
    await tester.pumpWidget(const VibeMingleApp(configurationError: true));
    expect(find.textContaining('configuration is missing'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
