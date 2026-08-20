import 'package:doce_equilibrio/core/utils/encryption_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valida apenas a senha correspondente ao hash com salt', () {
    const salt = 'salt-de-teste';
    final hash = EncryptionUtils.generateSaltedHash('senha-correta', salt);

    expect(
      EncryptionUtils.validatePassword(
        enteredPassword: 'senha-correta',
        storedHash: hash,
        salt: salt,
      ),
      isTrue,
    );
    expect(
      EncryptionUtils.validatePassword(
        enteredPassword: 'senha-incorreta',
        storedHash: hash,
        salt: salt,
      ),
      isFalse,
    );
  });
}
