import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Implement this contract with the SMS backend before production use.
abstract interface class AuthService {
  Future<void> sendCode(String phone);
  Future<bool> verifyCode(String phone, String code);
  String? get demoCode;
}

class DemoAuthService implements AuthService {
  @override
  String get demoCode => '123456';

  @override
  Future<void> sendCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> verifyCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return code == demoCode;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => DemoAuthService());
final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AuthState>(AuthController.new);

class AuthState {
  const AuthState({this.phone, this.isLoading = false, this.error});

  final String? phone;
  final bool isLoading;
  final String? error;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> sendCode(String phone) async {
    if (state.isLoading) return false;
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      state = const AuthState(error: 'Enter a valid 10-digit mobile number.');
      return false;
    }
    state = const AuthState(isLoading: true);
    try {
      await ref.read(authServiceProvider).sendCode('+91$phone');
      if (!ref.mounted) return false;
      state = AuthState(phone: phone);
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = const AuthState(
          error: 'Unable to send the code. Please try again.',
        );
      }
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    final phone = state.phone;
    if (state.isLoading || phone == null) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = AuthState(phone: phone, error: 'Enter the 6-digit code.');
      return false;
    }
    state = AuthState(phone: phone, isLoading: true);
    try {
      final verified = await ref
          .read(authServiceProvider)
          .verifyCode('+91$phone', code);
      if (!ref.mounted) return false;
      state = AuthState(
        phone: phone,
        error: verified ? null : 'Incorrect code. Please try again.',
      );
      return verified;
    } catch (_) {
      if (ref.mounted) {
        state = AuthState(
          phone: phone,
          error: 'Unable to verify the code. Please try again.',
        );
      }
      return false;
    }
  }

  void reset() => state = const AuthState();
}
