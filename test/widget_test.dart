import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/features/home/presentation/pages/home_page.dart';
import 'package:bsbschool/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  testWidgets('Dashboard renders feature sections', (tester) async {
    await tester.pumpWidget(const BsbSchoolApp());
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Bölmələr'), findsOneWidget);
    expect(find.text('Bufet'), findsOneWidget);
    expect(find.text('Kitabxana'), findsOneWidget);
  });
}
