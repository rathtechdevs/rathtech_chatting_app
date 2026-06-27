import 'package:flutter_test/flutter_test.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/phone_number.dart';

void main() {
  group('PhoneNumber', () {
    group('create — valid inputs', () {
      test('accepts E.164 number with country code', () {
        final result = PhoneNumber.create('+14155552671');
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (phone) => expect(phone.value, '+14155552671'),
        );
      });

      test('strips spaces and hyphens', () {
        final result = PhoneNumber.create('+1 415 555-2671');
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (phone) => expect(phone.value, '+14155552671'),
        );
      });

      test('accepts 8-digit number', () {
        final result = PhoneNumber.create('+12345678');
        expect(result.isRight(), isTrue);
      });

      test('accepts 15-digit number', () {
        final result = PhoneNumber.create('+123456789012345');
        expect(result.isRight(), isTrue);
      });
    });

    group('create — invalid inputs', () {
      test('rejects number without leading +', () {
        final result = PhoneNumber.create('14155552671');
        expect(result.isLeft(), isTrue);
      });

      test('rejects number that is too short', () {
        final result = PhoneNumber.create('+1234567');
        expect(result.isLeft(), isTrue);
      });

      test('rejects number that is too long', () {
        final result = PhoneNumber.create('+1234567890123456');
        expect(result.isLeft(), isTrue);
      });

      test('rejects empty string', () {
        final result = PhoneNumber.create('');
        expect(result.isLeft(), isTrue);
      });

      test('rejects letters in number', () {
        final result = PhoneNumber.create('+1abc5552671');
        expect(result.isLeft(), isTrue);
      });

      test('rejects number starting with +0', () {
        final result = PhoneNumber.create('+01234567890');
        expect(result.isLeft(), isTrue);
      });
    });

    group('equality', () {
      test('two PhoneNumbers with the same value are equal', () {
        final a = PhoneNumber.create('+14155552671').getRight().toNullable();
        final b = PhoneNumber.create('+14155552671').getRight().toNullable();
        expect(a, equals(b));
      });

      test('two PhoneNumbers with different values are not equal', () {
        final a = PhoneNumber.create('+14155552671').getRight().toNullable();
        final b = PhoneNumber.create('+14155552672').getRight().toNullable();
        expect(a, isNot(equals(b)));
      });
    });
  });
}
