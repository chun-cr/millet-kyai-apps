import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/widgets/country_code_picker.dart';
import 'package:millet_kyai_apps/main.dart';

Future<void> _pumpLoginPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  setPreviewAuthenticated(false);
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pump(const Duration(milliseconds: 900));
  expect(find.byType(LoginPage), findsOneWidget);
}

Future<void> _openCountrySelector(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('country_code_menu_trigger')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

class _PopoverHost extends StatefulWidget {
  const _PopoverHost({super.key});

  @override
  State<_PopoverHost> createState() => _PopoverHostState();
}

class _PopoverHostState extends State<_PopoverHost> {
  String code = '+86';
  String flag = '🇨🇳';
  int rebuilds = 0;

  void triggerRebuild() {
    setState(() => rebuilds++);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            CountryCodePopoverPicker(
              flag: flag,
              code: code,
              options: authCountryCodeOptions,
              onSelected: (selected) {
                setState(() {
                  code = selected.code;
                  flag = selected.flag;
                });
              },
            ),
            Text('$rebuilds', key: const ValueKey('popover_host_rebuilds')),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'country selector prefix is visible before focusing phone field',
    (tester) async {
      await _pumpLoginPage(tester);

      expect(
        find.byKey(const ValueKey('country_code_menu_trigger')),
        findsOneWidget,
      );
      expect(find.text('+86'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('country selector opens as anchored popover', (tester) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('country_code_popover_surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('country_code_popover_list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('country_code_picker_item_+44')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('selecting a country updates the prefix and closes the popover', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);
    await tester.tap(
      find.byKey(const ValueKey('country_code_picker_item_+44')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey('country_code_popover_surface')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('country_code_menu_trigger')),
        matching: find.text('+44'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping outside dismisses the popover', (tester) async {
    await _pumpLoginPage(tester);

    await _openCountrySelector(tester);
    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey('country_code_popover_surface')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('country_code_menu_trigger')),
        matching: find.text('+86'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('parent rebuild does not throw while popover is open', (
    tester,
  ) async {
    final hostKey = GlobalKey<_PopoverHostState>();
    await tester.pumpWidget(_PopoverHost(key: hostKey));

    await tester.tap(find.text('+86'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(
      find.byKey(const ValueKey('country_code_popover_surface')),
      findsOneWidget,
    );

    hostKey.currentState!.triggerRebuild();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('country_code_popover_surface')),
      findsOneWidget,
    );
  });
}
