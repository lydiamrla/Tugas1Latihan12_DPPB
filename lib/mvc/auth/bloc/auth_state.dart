part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? message;

  const AuthState({required this.status, this.user, this.message});
  const AuthState.initial() : status = AuthStatus.initial, user = null, message = null;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? message}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}