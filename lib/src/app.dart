// lib/src/app.dart
import 'package:flutter/material.dart';
// import 'features/gallery/screens/gallery_screen.dart'; // Ya no se usa aquí
import 'screens/main_screen.dart'; // Importa la nueva pantalla principal

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diario de Entrenamiento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // Por defecto, cada pantalla puede tener su propio estilo
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(), // Usa MainScreen como pantalla de inicio
      // --------------------
      debugShowCheckedModeBanner: false,
    );
  }
}