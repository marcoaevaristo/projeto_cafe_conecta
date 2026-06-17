import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'utils/theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseService.db;
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const CafeConectaApp()));
}

class CafeConectaApp extends StatelessWidget {
  const CafeConectaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Café Conecta', debugShowCheckedModeBanner: false,
    theme: CafeTheme.theme, home: const LoginScreen());
}
