
import 'package:application_2/application_2.dart';
import 'package:test/test.dart';

void main() {
  group('Addition tests', () {
    test('Positive numbers', () {
      expect(add(1, 2), 3);
    });

    test('Negative numbers', () {
      expect(add(-1, -2), -3);
    });

    test('Positive and negative numbers', () {
      expect(add(1, -2), -1);
    });
  });
}