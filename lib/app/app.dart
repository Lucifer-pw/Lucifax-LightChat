import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/appearance_cubit.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/calls/presentation/bloc/incoming_call_cubit.dart';
import '../features/music/presentation/bloc/music_player_cubit.dart';
import '../features/status/presentation/bloc/status_bloc.dart';
import 'di/injection.dart';
import 'router.dart';

class LightChatApp extends StatelessWidget {
  const LightChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider<StatusBloc>(
          create: (context) => getIt<StatusBloc>(),
        ),
        BlocProvider<MusicPlayerCubit>(
          create: (context) => getIt<MusicPlayerCubit>(),
        ),
        BlocProvider<AppearanceCubit>(
          create: (context) => getIt<AppearanceCubit>(),
        ),
        BlocProvider<IncomingCallCubit>(
          create: (context) => getIt<IncomingCallCubit>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              debugPrint('[App] AuthBloc state changed: ${state.runtimeType}');
              if (state is AuthenticatedState) {
                debugPrint('[App] Authenticated uid=${state.user.uid}, starting IncomingCallCubit');
                getIt<IncomingCallCubit>().listenToIncomingCalls(state.user.uid);
              } else if (state is UnauthenticatedState) {
                getIt<IncomingCallCubit>().stopListening();
              }
            },
          ),
          BlocListener<IncomingCallCubit, IncomingCallState>(
            listener: (context, state) {
              debugPrint('[App] IncomingCallCubit state: ${state.runtimeType}');
              if (state is IncomingCallRinging) {
                debugPrint('[App] RINGING! callId=${state.call.callId}, navigating...');
                final authState = context.read<AuthBloc>().state;
                final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';
                appRouter.push('/incoming-call', extra: {
                  'call': state.call,
                  'currentUserId': currentUserId,
                });
              } else if (state is IncomingCallError) {
                debugPrint('[App] IncomingCallCubit ERROR: ${state.message}');
              }
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'Lucifax LightChat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
