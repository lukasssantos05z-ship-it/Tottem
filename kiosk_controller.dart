import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/database_service.dart';
import '../../data/models/collaborator.dart';
import '../../data/models/meal_ticket.dart';
import '../../services/printer/thermal_printer_service.dart';

enum KioskStatus { idle, scanning, validating, printing, success, error }

class KioskController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final ThermalPrinterService printerService;

  KioskStatus status = KioskStatus.idle;
  String message = "Toque no botao central para iniciar";
  Collaborator? authenticatedCollaborator;
  MealTicket? lastTicket;

  KioskController({required this.printerService});

  String getCurrentMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 9) return "Desjejum";
    if (hour >= 11 && hour < 15) return "Almoco";
    if (hour >= 18 && hour < 21) return "Jantar";
    if (hour >= 23 || hour < 3) return "Ceia Noturna";
    return "Refeicao Especial / Lanche";
  }

  DateTimeRange getCurrentMealWindow() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> onFaceIdentified(Collaborator collaborator) async {
    status = KioskStatus.validating;
    message = "Verificando permissoes de refeicao...";
    notifyListeners();

    try {
      final window = getCurrentMealWindow();
      final alreadyEaten = await _db.hasAlreadyEatenInWindow(collaborator.id, window.start, window.end);

      if (alreadyEaten) {
        status = KioskStatus.error;
        message = "Refeicao ja retirada hoje para o colaborador ${collaborator.name}!";
        notifyListeners();
        _scheduleReset();
        return;
      }

      status = KioskStatus.printing;
      message = "Imprimindo seu ticket...";
      notifyListeners();

      final now = DateTime.now();
      final ticketId = const Uuid().v4();
      final hash = ThermalPrinterService.generateSecurityHash(ticketId, collaborator.registration, now);

      final ticket = MealTicket(
        id: ticketId,
        collaboratorId: collaborator.id,
        collaboratorName: collaborator.name,
        registration: collaborator.registration,
        sector: collaborator.sector,
        mealType: getCurrentMealType(),
        timestamp: now,
        securityHash: hash,
      );

      await _db.registerTicket(ticket);
      await printerService.printMealTicket(ticket);

      authenticatedCollaborator = collaborator;
      lastTicket = ticket;
      status = KioskStatus.success;
      message = "Ticket impresso! Bom apetite, ${collaborator.name}.";
      notifyListeners();
    } catch (e) {
      status = KioskStatus.error;
      message = "Falha no processo: $e";
      notifyListeners();
    } finally {
      _scheduleReset();
    }
  }

  void _scheduleReset() {
    Future.delayed(const Duration(seconds: 5), () {
      status = KioskStatus.idle;
      message = "Toque no botao central para iniciar";
      authenticatedCollaborator = null;
      lastTicket = null;
      notifyListeners();
    });
  }
}
