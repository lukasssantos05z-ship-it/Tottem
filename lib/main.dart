import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/database/database_service.dart';
import 'presentation/controllers/kiosk_controller.dart';
import 'presentation/screens/totem_home_screen.dart';
import 'services/printer/thermal_printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modo Imersivo Kiosk: Oculta barras de navegacao do sistema Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Inicializa Banco de Dados SQLCipher
  await DatabaseService.instance.database;

  final printerService = ThermalPrinterService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => KioskController(printerService: printerService),
        ),
      ],
      child: const HospitalKioskApp(),
    ),
  );
}

class HospitalKioskApp extends StatelessWidget {
  const HospitalKioskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Totem Kiosk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF005691),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: 'Roboto',
      ),
      home: const TotemHomeScreen(),
    );
  }
}
