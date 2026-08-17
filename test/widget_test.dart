import 'package:doce_equilibrio/core/di/service_locator.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doce_equilibrio/main.dart';

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    setupServiceLocator();
    await getIt.unregister<NotificationService>();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SweetBalanceApp());

    expect(find.text('Doce Equilíbrio'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
