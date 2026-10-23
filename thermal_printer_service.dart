import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:crypto/crypto.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../../data/models/meal_ticket.dart';

class ThermalPrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;

  bool get isConnected => _connectedDevice != null;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    try {
      bool? isConnected = await _bluetooth.isConnected;
      if (isConnected == true) {
        await _bluetooth.disconnect();
      }
      await _bluetooth.connect(device);
      _connectedDevice = device;
      return true;
    } catch (e) {
      _connectedDevice = null;
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> printMealTicket(MealTicket ticket) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text('HOSPITAL GERAL',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('SERVICO DE NUTRICAO E DIETETICA',
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
      bytes += generator.hr();

      bytes += generator.text('REFEICAO: ${ticket.mealType.toUpperCase()}',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.feed(1);

      bytes += generator.text('COLABORADOR:', styles: const PosStyles(bold: true));
      bytes += generator.text(ticket.collaboratorName, styles: const PosStyles(bold: true));
      bytes += generator.text('MATRICULA: ${ticket.registration}');
      bytes += generator.text('SETOR: ${ticket.sector}');
      bytes += generator.text('DATA/HORA: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(ticket.timestamp)}');

      bytes += generator.feed(1);
      bytes += generator.text('CODIGO DE VALIDACAO:', styles: const PosStyles(fontType: PosFontType.fontB));
      bytes += generator.text(ticket.securityHash.substring(0, 16).toUpperCase(),
          styles: const PosStyles(fontType: PosFontType.fontB, bold: true));

      bytes += generator.qrcode(ticket.securityHash, size: QRSize.size4);
      bytes += generator.feed(2);
      bytes += generator.cut();

      await _bluetooth.writeBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printClosingReport({
    required DateTime start,
    required DateTime end,
    required int totalMeals,
    required Map<String, int> sectorBreakdown,
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text('FECHAMENTO DE TURNO',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text('RELATORIO COZINHA/GESTAO', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      bytes += generator.text('PERIODO DE APURACAO:');
      bytes += generator.text('DE: ${DateFormat('dd/MM/yy HH:mm').format(start)}');
      bytes += generator.text('ATE: ${DateFormat('dd/MM/yy HH:mm').format(end)}');
      bytes += generator.hr();

      bytes += generator.text('TOTAL DE REFEICOES: $totalMeals',
          styles: const PosStyles(bold: true, height: PosTextSize.size2));
      bytes += generator.hr();

      bytes += generator.text('CONSUMO POR SETOR:', styles: const PosStyles(bold: true));
      sectorBreakdown.forEach((sector, count) {
        bytes += generator.row([
          PosColumn(text: sector, width: 8, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: count.toString().padLeft(4), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      });

      bytes += generator.hr();
      bytes += generator.text('IMPRESSO EM: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
          styles: const PosStyles(fontType: PosFontType.fontB));
      bytes += generator.feed(2);
      bytes += generator.cut();

      await _bluetooth.writeBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  static String generateSecurityHash(String id, String registration, DateTime time) {
    final raw = '$id-$registration-${time.millisecondsSinceEpoch}-HOSPITAL-SECRET-KEY';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
