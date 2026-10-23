import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/kiosk_controller.dart';
import '../widgets/admin_pin_dialog.dart';
import 'face_scan_screen.dart';
import 'admin_panel_screen.dart';

class TotemHomeScreen extends StatelessWidget {
  const TotemHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KioskController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 24,
              left: 32,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF005691),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HOSPITAL CENTRAL",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        "Terminal de Acesso e Refeitorio • ${controller.getCurrentMealType()}",
                        style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 24,
              right: 32,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8), size: 32),
                tooltip: "Area Restrita (TI/Nutricao)",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AdminPinDialog(
                      onSuccess: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: _getStatusColor(controller.status),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(controller.status).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      controller.message,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: controller.status == KioskStatus.idle
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FaceScanScreen()),
                            );
                          }
                        : null,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0072CE), Color(0xFF004080)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF005691).withOpacity(0.4),
                            blurRadius: 36,
                            spreadRadius: 8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.face_retouching_natural, size: 84, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            "TOQUE PARA\nRETIRAR TICKET",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Sistema em conformidade com a LGPD • Reconhecimento facial seguro sem retencao de imagem",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(KioskStatus status) {
    switch (status) {
      case KioskStatus.idle:
        return const Color(0xFF334155);
      case KioskStatus.validating:
      case KioskStatus.printing:
        return const Color(0xFF0284C7);
      case KioskStatus.success:
        return const Color(0xFF16A34A);
      case KioskStatus.error:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF334155);
    }
  }
}
