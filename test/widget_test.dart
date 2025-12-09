import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sipesantren/main.dart';

void main() {
  setUpAll(() async {
    // TestWidgetsFlutterBinding.ensureInitialized(); 
  });

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    final fakeFirestore = FakeFirebaseFirestore();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          firebaseServicesProvider.overrideWithValue(FirebaseServices(firestore: fakeFirestore)),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);
  });
}