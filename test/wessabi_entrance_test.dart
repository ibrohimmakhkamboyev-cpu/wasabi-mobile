import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/main.dart';
import 'package:wasabi_mobile/services/native_bridge.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';
import 'package:wasabi_mobile/theme/app_theme.dart';
import 'package:wasabi_mobile/ui/widgets/common.dart';
import 'package:wasabi_mobile/ui/widgets/wessabi_entrance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nativeChannel = MethodChannel('uz.wasabi.mobile/native');
  const entranceSeenKey = 'wasabi_mobile_entrance_seen_v1';
  late Map<String, String> nativeStore;
  late List<MethodCall> nativeCalls;

  setUp(() {
    nativeStore = <String, String>{};
    nativeCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, (call) async {
      nativeCalls.add(call);
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      final key = arguments['key'] as String;

      switch (call.method) {
        case 'getString':
          return nativeStore[key];
        case 'setString':
          nativeStore[key] = arguments['value'] as String;
          return null;
        case 'remove':
          nativeStore.remove(key);
          return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, null);
  });

  testWidgets('runs the Wessabi entrance on first launch', (tester) async {
    final state = AppState()..entranceSeen = false;

    await tester.pumpWidget(_testApp(state));
    await tester.pump();
    // Let the cached logo decode complete before measuring the animation.
    await tester.pump();

    expect(WessabiEntrance.duration, const Duration(milliseconds: 3200));
    expect(find.byKey(WessabiEntrance.overlayKey), findsOneWidget);
    expect(find.byKey(WessabiEntrance.taglineKey), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(WessabiEntrance.logoKey),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    await tester
        .pump(WessabiEntrance.duration - const Duration(milliseconds: 1));

    expect(find.byKey(WessabiEntrance.overlayKey), findsOneWidget);
    expect(state.entranceSeen, isFalse);

    await tester.pump(const Duration(milliseconds: 17));
    expect(find.byKey(WessabiEntrance.overlayKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();

    expect(state.entranceSeen, isTrue);
    expect(find.byKey(WessabiEntrance.overlayKey), findsNothing);
    expect(nativeStore[entranceSeenKey], '1');
  });

  testWidgets('does not replay the Wessabi entrance once it has been seen',
      (tester) async {
    final state = AppState()..entranceSeen = true;

    await tester.pumpWidget(_testApp(state));

    expect(find.byKey(WessabiEntrance.overlayKey), findsNothing);
  });

  testWidgets('entrance stays layout-safe on compact and landscape screens',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [
      Size(320, 568),
      Size(844, 390),
      Size(1024, 1366)
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const WessabiEntrance(
            animation: AlwaysStoppedAnimation<double>(0.66),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.byKey(WessabiEntrance.logoKey), findsOneWidget);
    }
  });

  test('successful logout resets and removes the entrance marker', () async {
    final api = _LogoutWasabiApi();
    final state = AppState(api: api)..entranceSeen = true;
    await NativeBridge.setString(entranceSeenKey, '1');

    await state.logout();

    expect(api.logoutCalls, 1);
    expect(state.entranceSeen, isFalse);
    expect(nativeStore.containsKey(entranceSeenKey), isFalse);
    expect(
      nativeCalls.where(
        (call) =>
            call.method == 'remove' &&
            (call.arguments as Map)['key'] == entranceSeenKey,
      ),
      hasLength(1),
    );
  });
}

Widget _testApp(AppState state) {
  state
    ..initialized = true
    ..onboardingDone = true;
  return AppScope(
    state: state,
    child: const WasabiApp(),
  );
}

class _LogoutWasabiApi extends WasabiApi {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}
