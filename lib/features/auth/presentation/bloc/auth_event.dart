import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SendPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  const SendPhoneOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;
  const VerifyOtpEvent({required this.verificationId, required this.smsCode});

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class SaveProfileEvent extends AuthEvent {
  final String displayName;
  final String bio;
  final File? imageFile;
  const SaveProfileEvent({
    required this.displayName,
    required this.bio,
    this.imageFile,
  });

  @override
  List<Object?> get props => [displayName, bio, imageFile];
}

class SignOutEvent extends AuthEvent {}
