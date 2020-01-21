import 'package:scoreboard/models.dart';
import 'package:test/test.dart';

void main() {
  test('Diffie-Hellman Pre-Generated Secrets', () {
    VerificationKey alice = VerificationKey("4");
    VerificationKey bob = VerificationKey("3");

    BigInt aPubKey = alice.getPublicKey();
    BigInt bPubKey = bob.getPublicKey();

    VerificationKey aSharedSecret = alice.getSharedSecret(bPubKey);
    VerificationKey bSharedSecret = bob.getSharedSecret(aPubKey);

    expect(aSharedSecret.secret, bSharedSecret.secret);
  });

  test("Diffie-Hellman Generate", () {
    VerificationKey alice = VerificationKey.generate();
    VerificationKey bob = VerificationKey.generate();

    BigInt aPubKey = alice.getPublicKey();
    BigInt bPubKey = bob.getPublicKey();

    VerificationKey aSharedSecret = alice.getSharedSecret(bPubKey);
    VerificationKey bSharedSecret = bob.getSharedSecret(aPubKey);
    expect(aSharedSecret.secret, bSharedSecret.secret);
  });

  test("Diffie-Hellman Sign", () {
    VerificationKey alice = VerificationKey.generate();
    VerificationKey bob = VerificationKey.generate();

    BigInt aPubKey = alice.getPublicKey();
    BigInt bPubKey = bob.getPublicKey();

    VerificationKey aSharedSecret = alice.getSharedSecret(bPubKey);
    VerificationKey bSharedSecret = bob.getSharedSecret(aPubKey);

    String message = "Hello world, I am a secured message";
    String encrypted = aSharedSecret.encrypt(message);
    String decryptedMessage = bSharedSecret.decrypt(encrypted);

    expect(message, decryptedMessage);
  });
}
