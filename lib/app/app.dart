import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/appearance_cubit.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
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
      ],
      child: MaterialApp.router(
        title: 'Lucifax LightChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // Dark theme as default
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
