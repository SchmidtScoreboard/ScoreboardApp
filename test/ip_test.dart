import 'package:scoreboard/models.dart';
import 'package:test/test.dart';

void main() {
  test('Validates ip codes', () {
    expect(isValidIpCode("ABCDEFGH"), true);
    expect(isValidIpCode("asdf"), false);
  });

  test("ipFromCode gets correct ip", () {
    expect(ipFromCode("AKJVKAAK"), "10.255.260.10");
    expect(ipFromCode("AAAAAAAA"), "0.0.0.0");
  });
}
