import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cognitive_tests/cognitive_tests.dart';
import 'dart:math';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StroopTest Logic Tests', () {
    test('original sequence reconstructs all pages in every language',
        () async {
      const colors = [Colors.red, Colors.green, Colors.blue];
      for (final language in StroopLanguage.values) {
        final stroop = StroopTest(
          enableAudioRecording: false,
          itemCount: 100,
          language: language,
          random: Random(42),
        );
        await stroop.initialize();
        final words = StroopLanguageWords.getWordsForLanguage(language);

        expect(stroop.sequence, hasLength(100));
        for (var i = 0; i < stroop.sequence.length; i++) {
          final entry = stroop.sequence[i];
          expect(stroop.page0Words[i].text, words[entry.wordIndex]);
          expect(stroop.page0Words[i].color, Colors.black);
          expect(stroop.page1Colors[i].text, isNull);
          expect(stroop.page1Colors[i].color, colors[entry.colorIndex]);
          expect(stroop.page2Words[i].text, words[entry.wordIndex]);
          expect(stroop.page2Words[i].color, colors[entry.colorIndex]);
        }
        expect(() => stroop.sequence.clear(), throwsUnsupportedError);
        await stroop.dispose();
      }
    });

    test('result keeps an immutable snapshot of the supplied sequence', () {
      final source = <StroopSequenceEntry>[
        (wordIndex: 0, colorIndex: 1),
      ];
      final result = StroopTestResult(
        audioFile: null,
        audioFilename: null,
        timestamps: [],
        audioRecordingEnabled: false,
        testDate: DateTime(2026),
        sequence: source,
        language: StroopLanguage.spanish,
      );
      source.clear();
      expect(result.sequence, [(wordIndex: 0, colorIndex: 1)]);
      expect(() => result.sequence.clear(), throwsUnsupportedError);
    });

    testWidgets('finish delivers the generated sequence and language unchanged',
        (tester) async {
      final handler = _CapturingResultHandler();
      final stroop = StroopTest(
        enableAudioRecording: false,
        resultHandler: handler,
        language: StroopLanguage.spanish,
        random: Random(42),
      );
      await stroop.initialize();
      final original = List<StroopSequenceEntry>.of(stroop.sequence);
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
        context = value;
        return const SizedBox.shrink();
      })));
      await stroop.startTest();
      stroop.goToNextPage();
      stroop.goToNextPage();
      await stroop.finishTest(context);

      expect(handler.result!.sequence, original);
      expect(handler.result!.language, StroopLanguage.spanish);
      expect(handler.result!.timestamps, isEmpty);
      expect(handler.result!.audioRecordingEnabled, isFalse);
      await stroop.dispose();
    });

    test('should generate items without errors', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 10,
        language: StroopLanguage.english,
        random: Random(42), // Fixed seed for reproducibility
      );

      expect(() => test.initialize(), returnsNormally);
      expect(test.page0Words.length, equals(10));
      expect(test.page1Colors.length, equals(10));
      expect(test.page2Words.length, equals(10));
    });

    test('should have no adjacent identical words in page 0', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 20,
        language: StroopLanguage.english,
        random: Random(42),
      );

      test.initialize();

      for (int i = 1; i < test.page0Words.length; i++) {
        expect(
          test.page0Words[i].text,
          isNot(equals(test.page0Words[i - 1].text)),
          reason: 'Adjacent words should be different at position $i',
        );
      }
    });

    test('should have no adjacent identical colors in page 1', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 20,
        language: StroopLanguage.english,
        random: Random(42),
      );

      test.initialize();

      for (int i = 1; i < test.page1Colors.length; i++) {
        expect(
          test.page1Colors[i].color,
          isNot(equals(test.page1Colors[i - 1].color)),
          reason: 'Adjacent colors should be different at position $i',
        );
      }
    });

    test('should have incongruent word-color pairs in page 2', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 20,
        language: StroopLanguage.english,
        random: Random(42),
      );

      test.initialize();

      // Map colors to their semantic indices
      final Map<Color, int> colorToIndex = {
        Colors.red: 0,
        Colors.green: 1,
        Colors.blue: 2,
      };
      final words = ['RED', 'GREEN', 'BLUE'];

      for (final item in test.page2Words) {
        final wordIndex = words.indexOf(item.text!);
        final colorIndex = colorToIndex[item.color];

        expect(
          wordIndex,
          isNot(equals(colorIndex)),
          reason: 'Word "${item.text}" should not have its semantic color',
        );
      }
    });

    test('should support multilanguage', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 10,
        language: StroopLanguage.spanish,
        random: Random(42),
      );

      test.initialize();

      final spanishWords = ['ROJO', 'VERDE', 'AZUL'];
      for (final item in test.page0Words) {
        expect(spanishWords.contains(item.text), isTrue);
      }
    });

    test('should handle page navigation correctly', () {
      final test = StroopTest(
        enableAudioRecording: false,
        itemCount: 10,
      );

      test.initialize();

      expect(test.testPage, equals(0));
      expect(test.isLastPage, isFalse);

      test.goToNextPage();
      expect(test.testPage, equals(1));
      expect(test.isLastPage, isFalse);

      test.goToNextPage();
      expect(test.testPage, equals(2));
      expect(test.isLastPage, isTrue);

      // Should not go beyond last page
      test.goToNextPage();
      expect(test.testPage, equals(2));
    });
  });
}

class _CapturingResultHandler implements TestResultHandler {
  StroopTestResult? result;

  @override
  Future<void> handleStroopTestResults(
      BuildContext context, StroopTestResult result) async {
    this.result = result;
  }

  @override
  Future<void> handleTrailMakingTestResults(
      BuildContext context, TrailMakingTestResult result) async {}
}
