import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: VoiceScribeApp()));
}

/// Widget principal do aplicativo
class VoiceScribeApp extends StatelessWidget {
  const VoiceScribeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceScribe',
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Tela inicial
      home: const HomeScreen(),

      // Rotas nomeadas
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}
