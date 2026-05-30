import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;


class PdfUtils {
  /// Gera um arquivo PDF a partir de uma lista de mapas (histórico), usando fonte Roboto para suporte Unicode.
  static Future<Uint8List> toPdf(List<Map<String, dynamic>> data,
      {List<String>? headers}) async {
    final pdf = pw.Document();
    final keys = headers ?? (data.isNotEmpty ? data.first.keys.toList() : []);

    // Carrega a fonte Roboto dos assets
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Se for recibo de transferência (possui campos típicos)
    final isTransferencia = data.isNotEmpty && (
      data.first.containsKey('remetente') ||
      data.first.containsKey('destinatario') ||
      data.first.containsKey('valor')
    );

    if (isTransferencia) {
      // Gera recibo bonito para cada transferência
      for (final row in data) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Recibo de Transferência', style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 24),
                  if (row['remetente'] != null)
                    pw.Text('Remetente: ${row['remetente']}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  if (row['destinatario'] != null)
                    pw.Text('Destinatário: ${row['destinatario']}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  if (row['valor'] != null)
                    pw.Text('Valor: R\$ ${row['valor']}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  if (row['data'] != null)
                    pw.Text('Data: ${row['data']}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  if (row['id'] != null)
                    pw.Text('Código da transação: ${row['id']}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColor.fromInt(0xFF888888))),
                  pw.SizedBox(height: 24),
                  pw.Divider(),
                  pw.Text('Obrigado por usar o Papaleguas Pix!', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColor.fromInt(0xFF888888))),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      // Mantém tabela padrão para outros usos
      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray( 
            headers: keys,
            data: data
                .map((row) => keys.map((k) => row[k]?.toString() ?? '').toList())
                .toList(),
            cellStyle: pw.TextStyle(font: ttf),
            headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }
    return pdf.save();
  }
}
