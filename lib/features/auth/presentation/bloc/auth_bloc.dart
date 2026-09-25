import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/save_user_profile.dart';
import '../../domain/usecases/send_phone_otp.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final SendPhoneOtp sendPhoneOtp;
  final VerifyOtp verifyOtp;
  final SaveUserProfile saveUserProfile;
  final SignOut signOut;

  AuthBloc({
    required this.getCurrentUser,
    required this.sendPhoneOtp,
    required this.verifyOtp,
    required this.saveUserProfile,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SaveProfileEvent>(_onSaveProfile);
    on<SignOutEvent>(_onSignOut);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading('Checking login status...'));
    final result = await getCurrentUser();

    result.fold(
      (failure) => emit(UnauthenticatedState()),
      (user) {
        if (user == null) {
          emit(UnauthenticatedState());
        } else if (user.displayName.isEmpty) {
          emit(NeedsProfileSetupState(user));
        } else {
          emit(AuthenticatedState(user));
        }
      },
    );
  }

  Future<void> _onSendPhoneOtp(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading('Sending verification code...'));
    final result = await sendPhoneOtp(event.phoneNumber);

    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (verificationId) => emit(OtpSentState(
        verificationId: verificationId,
        phoneNumber: event.phoneNumber,
      )),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading('Verifying code...'));
    final result = await verifyOtp(
      verificationId: event.verificationId,
      smsCode: event.smsCode,
    );

    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (user) {
        if (user.displayName.isEmpty) {
          emit(NeedsProfileSetupState(user));
        } else {
          emit(AuthenticatedState(user));
        }
      },
    );
  }

  Future<void> _onSaveProfile(
    SaveProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final previousUser = state is AuthenticatedState ? (state as AuthenticatedState).user : null;
    emit(const AuthLoading('Saving profile...'));
    final result = await saveUserProfile(
      displayName: event.displayName,
      bio: event.bio,
      imageFile: event.imageFile,
    );

    result.fold(
      (failure) {
        emit(AuthErrorState(failure.message));
        if (previousUser != null) {
          emit(AuthenticatedState(previousUser));
        }
      },
      (user) => emit(AuthenticatedState(user)),
    );
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading('Logging out...'));
    await signOut();
    emit(UnauthenticatedState());
  }
}
