import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// V4.1 local device-key bootstrap scaffold.
///
/// IMPORTANT: This is NOT an E2EE protocol implementation. It deliberately
/// does not generate, persist, upload, or use cryptographic private keys.
/// Use a reviewed protocol package + platform secure storage before enabling
/// encrypted messaging in product UI.
class DeviceKeyBootstrap {
  DeviceKeyBootstrap._();

  /// Creates a non-secret installation identifier for local diagnostics only.
  /// This is NOT a cryptographic device identity and must not authenticate a
  /// device or be used as a key.
  static String createInstallReference() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// E2EE remains disabled until a reviewed protocol and secure storage adapter
  /// are wired. Calling this guard makes accidental "encrypt" claims explicit.
  static Never requireProtocolImplementation() {
    throw StateError(
      'E2EE is not enabled: audited protocol and secure key storage are pending.',
    );
  }
}
