// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/video_management/presentation/screens/main_screen.dart';
import 'features/video_management/presentation/providers/video_provider.dart';
import 'core/di/injection_container.dart' as di;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para gestión de videos
        ChangeNotifierProvider(
          create: (_) => di.sl<VideoProvider>(),
        ),
        // Aquí puedes añadir más providers según necesites
        // ChangeNotifierProvider(
        //   create: (_) => di.sl<InstructorProvider>(),
        // ),
      ],
      child: MaterialApp(
        title: 'Diario de Entrenamiento',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}