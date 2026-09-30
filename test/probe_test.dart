import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:mediarescueadmin/theme/glass_theme.dart';

import 'glass_test_helpers.dart';

Future<void> probe(WidgetTester tester, String name, Widget child) async {
  await tester.pumpWidget(
    hostApp(
      Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: 360,
          height: 780,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 30));
  final Object? error = tester.takeException();
  debugPrint('PROBE $name -> ${error ?? 'ok'}');
}

void main() {
  testWidgets('probe individual glass pieces', (tester) async {
    usePhoneViewport(tester);

    await probe(
      tester,
      'column of padding',
      const Padding(padding: EdgeInsets.all(10), child: SizedBox(height: 40)),
    );

    await probe(
      tester,
      'GlassField',
      const Padding(padding: EdgeInsets.all(20), child: GlassField(hint: 'x')),
    );

    await probe(
      tester,
      'GlassSelectField',
      Padding(
        padding: const EdgeInsets.all(20),
        child: GlassSelectField<String>(
          label: 'App Version',
          value: null,
          options: const <GlassSelectOption<String>>[],
          onChanged: (_) {},
        ),
      ),
    );

    await probe(
      tester,
      'column field+selects',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            const GlassField(hint: 'search'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: GlassSelectField<String>(
                    label: 'App Version',
                    value: null,
                    options: const <GlassSelectOption<String>>[],
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassSelectField<String>(
                    label: 'Android OS',
                    value: null,
                    options: const <GlassSelectOption<String>>[],
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await probe(
      tester,
      'GlassField long hint',
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassField(
          hint: 'Search by Installation UUID or Device Model…',
          prefixIcon: Icons.search_rounded,
        ),
      ),
    );

    await probe(
      tester,
      'GlassField maxLines 4',
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassField(
          hint: 'token1, token2, token3…',
          prefixIcon: Icons.vpn_key_rounded,
          maxLines: 4,
        ),
      ),
    );

    await probe(
      tester,
      'column with expanded list',
      Column(
        children: <Widget>[
          const Padding(padding: EdgeInsets.all(10), child: GlassField(hint: 's')),
          const Padding(padding: EdgeInsets.all(10), child: Text('count')),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, i) => const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(height: 60, child: Text('row')),
              ),
            ),
          ),
        ],
      ),
    );

    await probe(
      tester,
      'LiquidGlassLite zero blur surface',
      const Padding(
        padding:  EdgeInsets.all(20),
        child: LiquidGlassLite(
          shape: GlassStyles.liteFieldShape,
          color: GlassTints.field,
          // blur:  LiquidGlassBlur(),
          pickup: LiquidGlassLitePickup.surface,
          child:  TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'hint',
              isDense: true,
            ),
          ),
        ),
      ),
    );
  });
}
