import 'package:flutter_test/flutter_test.dart';
import 'package:albmap/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty, and whitespace-only input', () {
      expect(Validators.required(null, 'req'), 'req');
      expect(Validators.required('', 'req'), 'req');
      expect(Validators.required('   ', 'req'), 'req');
    });

    test('accepts non-empty text, including with surrounding whitespace', () {
      expect(Validators.required('Jane', 'req'), isNull);
      expect(Validators.required('  Jane  ', 'req'), isNull);
    });
  });

  group('Validators.email', () {
    String? v(String? input) => Validators.email(input, requiredMessage: 'required', invalidMessage: 'invalid');

    test('rejects null/empty as required', () {
      expect(v(null), 'required');
      expect(v(''), 'required');
      expect(v('   '), 'required');
    });

    // This is the exact class of input the previous `v.contains('@')`
    // check across the app let straight through — the whole reason
    // Validators.email exists instead of every screen hand-rolling its
    // own check.
    test('rejects strings that merely contain an @ but are not real emails', () {
      expect(v('@'), 'invalid');
      expect(v('a@'), 'invalid');
      expect(v('@b.com'), 'invalid');
      expect(v('a@b'), 'invalid'); // no TLD
      expect(v('a@@b.com'), 'invalid');
      expect(v('a b@example.com'), 'invalid'); // embedded space
      expect(v('plainstring'), 'invalid');
    });

    test('accepts realistic valid addresses', () {
      expect(v('user@example.com'), isNull);
      expect(v('first.last+tag@sub.example.co.uk'), isNull);
      expect(v('  user@example.com  '), isNull); // trims surrounding whitespace
    });
  });

  group('Validators.optionalPhone', () {
    String? v(String? input) => Validators.optionalPhone(input, invalidMessage: 'invalid');

    test('empty/null is valid — phone is optional', () {
      expect(v(null), isNull);
      expect(v(''), isNull);
      expect(v('   '), isNull);
    });

    test('accepts common real-world formats', () {
      expect(v('+355 69 123 4567'), isNull);
      expect(v('069-123-4567'), isNull);
      expect(v('(069) 123 4567'), isNull);
      expect(v('+1 212 555 0100'), isNull);
      expect(v('069.123.4567'), isNull);
    });

    test('rejects letters and obviously-invalid input', () {
      expect(v('call me maybe'), 'invalid');
      expect(v('123'), 'invalid'); // too short
      expect(v('abc1234567'), 'invalid');
    });
  });

  group('Validators.requiredPhone', () {
    test('empty is rejected as required, not as invalid format', () {
      expect(
        Validators.requiredPhone(null, requiredMessage: 'required', invalidMessage: 'invalid'),
        'required',
      );
      expect(
        Validators.requiredPhone('', requiredMessage: 'required', invalidMessage: 'invalid'),
        'required',
      );
    });

    test('valid phone passes', () {
      expect(
        Validators.requiredPhone('+355691234567', requiredMessage: 'required', invalidMessage: 'invalid'),
        isNull,
      );
    });
  });

  group('Validators.password', () {
    String? v(String? input) => Validators.password(input, requiredMessage: 'required', tooShortMessage: 'short');

    test('rejects null/empty as required', () {
      expect(v(null), 'required');
      expect(v(''), 'required');
    });

    test('rejects passwords under the minimum length', () {
      expect(v('abc12'), 'short'); // 5 chars, default min is 6
    });

    test('accepts passwords meeting the minimum length', () {
      expect(v('abc123'), isNull);
    });

    test('respects a custom minLength', () {
      final result = Validators.password(
        'short1',
        requiredMessage: 'required',
        tooShortMessage: 'short',
        minLength: 8,
      );
      expect(result, 'short');
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty confirm value as required', () {
      expect(
        Validators.confirmPassword(null, 'secret1', requiredMessage: 'required', mismatchMessage: 'mismatch'),
        'required',
      );
      expect(
        Validators.confirmPassword('', 'secret1', requiredMessage: 'required', mismatchMessage: 'mismatch'),
        'required',
      );
    });

    test('rejects a non-matching confirmation', () {
      expect(
        Validators.confirmPassword('secret2', 'secret1', requiredMessage: 'required', mismatchMessage: 'mismatch'),
        'mismatch',
      );
    });

    test('accepts a matching confirmation', () {
      expect(
        Validators.confirmPassword('secret1', 'secret1', requiredMessage: 'required', mismatchMessage: 'mismatch'),
        isNull,
      );
    });
  });

  group('Validators.otp', () {
    test('rejects null/empty as required', () {
      expect(Validators.otp(null, requiredMessage: 'required', invalidMessage: 'invalid'), 'required');
      expect(Validators.otp('', requiredMessage: 'required', invalidMessage: 'invalid'), 'required');
      expect(Validators.otp('   ', requiredMessage: 'required', invalidMessage: 'invalid'), 'required');
    });

    test('rejects anything that is not exactly 6 digits', () {
      expect(Validators.otp('12345', requiredMessage: 'required', invalidMessage: 'invalid'), 'invalid');
      expect(Validators.otp('1234567', requiredMessage: 'required', invalidMessage: 'invalid'), 'invalid');
      expect(Validators.otp('12345a', requiredMessage: 'required', invalidMessage: 'invalid'), 'invalid');
      expect(Validators.otp('123 456', requiredMessage: 'required', invalidMessage: 'invalid'), 'invalid');
    });

    test('accepts exactly 6 digits, trimming surrounding whitespace', () {
      expect(Validators.otp('123456', requiredMessage: 'required', invalidMessage: 'invalid'), isNull);
      expect(Validators.otp('  123456  ', requiredMessage: 'required', invalidMessage: 'invalid'), isNull);
      expect(Validators.otp('000000', requiredMessage: 'required', invalidMessage: 'invalid'), isNull);
    });
  });
}
