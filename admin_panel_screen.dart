import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/database_service.dart';
import '../../data/models/collaborator.dart';
import '../../services/printer/thermal_printer_service.dart';
import '../../services/report/export_service.dart';
import '../controllers/kiosk_controller.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;

  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  String _selectedSector = "UTI Adulto";

  final List<String> _sectors = [
    "UTI Adulto",
    "Centro Cirurgico",
    "Pronto Socorro",
    "Enfermagem Geral",
    "Farmacia",
    "Administrativo",
    "Higienizacao"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final printer = Provider.of<KioskController>(context).printerService;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo & Gestao de Nutricao"),
        backgroundColor: const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: "Fechamento Cozinha"),
            Tab(icon: Icon(Icons.person_add), text: "Cadastrar Colaborador"),
            Tab(icon: Icon(Icons.print), text: "Impressora Bluetooth"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Fechamento Rapido de Refeicoes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Emita a fita termica para conferencia direta da nutricao ou exporte relatorios de auditoria.",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005691),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.print),
                      label: const Text("IMPRIMIR FITA TERMICA (Z)"),
                      onPressed: () async {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day, 0, 0);
                        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

                        final tickets = await _db.getTicketsBetween(start, end);
                        final sectors = await _db.getSectorCountsBetween(start, end);

                        await printer.printClosingReport(
                          start: start,
                          end: end,
                          totalMeals: tickets.length,
                          sectorBreakdown: sectors,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Fita de fechamento enviada para a impressora termica.")),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      icon: const Icon(Icons.table_view, color: Colors.green),
                      label: const Text("EXPORTAR CSV (EXCEL)"),
                      onPressed: () async {
                        final now = DateTime.now();
                        final tickets = await _db.getTicketsBetween(
                          DateTime(now.year, now.month, now.day, 0, 0),
                          now,
                        );
                        await ExportService.exportToCSV(tickets);
                      },
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text("GERAR PDF AUDITORIA"),
                      onPressed: () async {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day, 0, 0);
                        final tickets = await _db.getTicketsBetween(start, now);
                        final sectors = await _db.getSectorCountsBetween(start, now);
                        await ExportService.exportToPDF(tickets, sectors);
                      },
                    ),
                  ],
                ),
                const Divider(height: 48),
                const Text("Ultimos Registros do Dia:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: FutureBuilder(
                    future: _db.getTicketsBetween(DateTime.now().subtract(const Duration(hours: 12)), DateTime.now()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data as List;
                      if (list.isEmpty) return const Center(child: Text("Nenhuma refeicao registrada hoje."));

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final item = list[i];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                            title: Text("${item.collaboratorName} (${item.registration})"),
                            subtitle: Text("Setor: ${item.sector} • Refeicao: ${item.mealType}"),
                            trailing: Text(item.timestamp.toString().substring(11, 16)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Novo Colaborador", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _regCtrl,
                  decoration: const InputDecoration(labelText: "Matricula Hospitalar", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSector,
                  items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSector = val!),
                  decoration: const InputDecoration(labelText: "Setor de Lotacao", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("CAPTURAR FACE E CADASTRAR"),
                  onPressed: () async {
                    if (_nameCtrl.text.isEmpty || _regCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Preencha todos os campos antes de capturar.")),
                      );
                      return;
                    }

                    final mockEmbedding = List<double>.generate(12, (i) => (i + 1) * 2.5);
                    final colab = Collaborator(
                      id: _regCtrl.text.trim(),
                      name: _nameCtrl.text.trim(),
                      registration: _regCtrl.text.trim(),
                      sector: _selectedSector,
                      faceEmbedding: mockEmbedding,
                    );

                    await _db.insertCollaborator(colab);
                    _nameCtrl.clear();
                    _regCtrl.clear();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Colaborador cadastrado no banco criptografado com sucesso!")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          FutureBuilder(
            future: printer.getPairedDevices(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final devices = snapshot.data as List;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: devices.length,
                itemBuilder: (ctx, i) {
                  final dev = devices[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.print, color: Colors.blue),
                      title: Text(dev.name ?? "Dispositivo Desconhecido"),
                      subtitle: Text(dev.address ?? ""),
                      trailing: ElevatedButton(
                        child: const Text("Conectar"),
                        onPressed: () async {
                          final ok = await printer.connect(dev);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? "Conectado a impressora!" : "Falha na conexao.")),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
