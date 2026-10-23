import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/models/meal_ticket.dart';

class ExportService {
  static Future<void> exportToCSV(List<MealTicket> tickets) async {
    List<List<dynamic>> rows = [
      ["ID Ticket", "Nome do Colaborador", "Matricula", "Setor", "Tipo Refeicao", "Data", "Hora", "Hash Antifraude"]
    ];

    for (var t in tickets) {
      rows.add([
        t.id,
        t.collaboratorName,
        t.registration,
        t.sector,
        t.mealType,
        DateFormat('dd/MM/yyyy').format(t.timestamp),
        DateFormat('HH:mm:ss').format(t.timestamp),
        t.securityHash,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/relatorio_refeicoes_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Exportacao de Registros de Refeitorio (Auditoria)');
  }

  static Future<void> exportToPDF(List<MealTicket> tickets, Map<String, int> sectorSummary) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Relatorio Oficial de Auditoria do Refeitorio', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Resumo Consolidado por Setor:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Setor', 'Refeicoes Entregues'],
              data: sectorSummary.entries.map((e) => [e.key, e.value.toString()]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Listagem Analitica Individual:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Matricula', 'Colaborador', 'Setor', 'Refeicao', 'Horario'],
              data: tickets.map((t) => [
                t.registration,
                t.collaboratorName,
                t.sector,
                t.mealType,
                DateFormat('dd/MM HH:mm').format(t.timestamp),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/auditoria_refeicoes_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Relatorio Executivo em PDF');
  }
}
