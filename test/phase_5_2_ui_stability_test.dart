import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/utils/theme.dart';
import 'package:groovy_chord_generator/widgets/chord_card.dart';
import 'package:groovy_chord_generator/widgets/control_dropdown.dart';

void main() {
  group('Phase 5.2 UI stability', () {
    testWidgets('generated chord cards render inside scrolling workspace',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChordCard(
                          chord: const Chord(
                            root: 'C',
                            type: ChordTypeName.major7,
                            degree: 'I',
                            numeral: 'I',
                          ),
                          index: 0,
                          onTap: () {},
                        ),
                        ChordCard(
                          chord: const Chord(
                            root: 'G',
                            type: ChordTypeName.dominant7,
                            degree: 'V',
                            numeral: 'V',
                          ),
                          index: 1,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('chordCard-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('chordCard-1')), findsOneWidget);
      expect(find.text('Cmaj7'), findsOneWidget);
      expect(find.text('G7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropdown does not red-screen when current key is missing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ControlDropdown<KeyName>(
                label: 'Key',
                value: KeyName.Fm,
                items: const [
                  DropdownMenuItem<KeyName>(
                    value: KeyName.C,
                    child: Text('C Major'),
                  ),
                  DropdownMenuItem<KeyName>(
                    value: KeyName.G,
                    child: Text('G Major'),
                  ),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Select Key'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
