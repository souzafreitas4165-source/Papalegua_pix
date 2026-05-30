import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:papaleguas_pix/utils/csv_utils.dart';
import 'package:papaleguas_pix/utils/pdf_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:papaleguas_pix/screens/transfer_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  const HistoryScreen({super.key, required this.history});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _FiltroAvancadoBottomSheet extends StatefulWidget {
  final DateTime? initialDateStart;
  final DateTime? initialDateEnd;
  final double? initialValorMin;
  final double? initialValorMax;
  final String? initialTipo;
  const _FiltroAvancadoBottomSheet({this.initialDateStart, this.initialDateEnd, this.initialValorMin, this.initialValorMax, this.initialTipo});

  @override
  State<_FiltroAvancadoBottomSheet> createState() => _FiltroAvancadoBottomSheetState();
}

class _FiltroAvancadoBottomSheetState extends State<_FiltroAvancadoBottomSheet> {
  late DateTime? _dateStart = widget.initialDateStart;
  late DateTime? _dateEnd = widget.initialDateEnd;
  late TextEditingController _valorMinController;
  late TextEditingController _valorMaxController;
  String? _tipo;

  @override
  void initState() {
    super.initState();
    _valorMinController = TextEditingController(text: widget.initialValorMin?.toString() ?? '');
    _valorMaxController = TextEditingController(text: widget.initialValorMax?.toString() ?? '');
    _tipo = widget.initialTipo;
  }

  @override
  void dispose() {
    _valorMinController.dispose();
    _valorMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateStart ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _dateStart = picked);
                  },
                  child: Text(_dateStart != null ? 'De: ${_dateStart!.day}/${_dateStart!.month}/${_dateStart!.year}' : 'Data início'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateEnd ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _dateEnd = picked);
                  },
                  child: Text(_dateEnd != null ? 'Até: ${_dateEnd!.day}/${_dateEnd!.month}/${_dateEnd!.year}' : 'Data fim'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valorMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor mínimo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _valorMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor máximo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo de destinatário'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'cpf', child: Text('CPF')),
              DropdownMenuItem(value: 'celular', child: Text('Celular')),
              DropdownMenuItem(value: 'email', child: Text('E-mail')),
              DropdownMenuItem(value: 'aleatoria', child: Text('Aleatória')),
            ],
            onChanged: (v) => setState(() => _tipo = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'dataInicio': _dateStart,
                    'dataFim': _dateEnd,
                    'valorMin': double.tryParse(_valorMinController.text),
                    'valorMax': double.tryParse(_valorMaxController.text),
                    'tipo': _tipo,
                  });
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _filtroDataInicio;
  DateTime? _filtroDataFim;
  double? _filtroValorMin;
  double? _filtroValorMax;
  String? _filtroTipo;

  List<Map<String, dynamic>> _filteredHistory() {
    final base = _search.isEmpty ? widget.history : widget.history.where((item) {
      final destinatario = item['destinatario']?.toString().toLowerCase() ?? '';
      final valor = item['valor']?.toString().toLowerCase() ?? '';
      final data = item['data']?.toString().toLowerCase() ?? '';
      return destinatario.contains(_search.toLowerCase()) ||
        valor.contains(_search.toLowerCase()) ||
        data.contains(_search.toLowerCase());
    }).toList();
    return base.where((item) {
      final dataItem = DateTime.tryParse(item['data'].toString());
      final valorItem = double.tryParse(item['valor'].toString());
      final tipoItem = _tipoDestinatario(item['destinatario'].toString());
      if (_filtroDataInicio != null && (dataItem == null || dataItem.isBefore(_filtroDataInicio!))) return false;
      if (_filtroDataFim != null && (dataItem == null || dataItem.isAfter(_filtroDataFim!))) return false;
      if (_filtroValorMin != null && (valorItem == null || valorItem < _filtroValorMin!)) return false;
      if (_filtroValorMax != null && (valorItem == null || valorItem > _filtroValorMax!)) return false;
      if (_filtroTipo != null && _filtroTipo!.isNotEmpty && tipoItem != _filtroTipo) return false;
      return true;
    }).toList();
  }

  String _tipoDestinatario(String destinatario) {
    if (destinatario.contains('@')) return 'email';
    if (destinatario.length == 11 && int.tryParse(destinatario) != null) return 'cpf';
    if (destinatario.length >= 10 && destinatario.contains(RegExp(r'^[0-9()+\s-]+$'))) return 'celular';
    return 'aleatoria';
  }

  Future<void> _exportarHistoricoCSV() async {
    try {
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Destinatário,Valor,Data');
      for (final item in _filteredHistory()) {
        final destinatario = item['destinatario'].toString().replaceAll(',', '');
        final valor = item['valor'].toString().replaceAll(',', '.');
        final data = item['data'].toString();
        csvBuffer.writeln('"$destinatario",$valor,"$data"');
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/historico_pix.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString(), flush: true);
      await SharePlus.instance.share(ShareParams(
          text: csvBuffer.toString(), subject: 'Exportação CSV - Papaleguas Pix'));
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    }
  }

  Future<void> _exportarHistoricoPDF() async {
    try {
      final pdfData = await PdfUtils.toPdf(_filteredHistory(), headers: ['destinatario', 'valor', 'data']);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/historico_pix.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfData, flush: true);
      await SharePlus.instance.share(ShareParams(
          text: 'Histórico de transferências (PDF)',
          files: [XFile(path)]));
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao exportar PDF: $e')),
      );
    }
  }

  String _search = '';
  bool _isFiltering = false;
  Future<void>? _filterFuture;
  Set<String> _favoritos = {};

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  Future<void> _loadFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritos = (prefs.getStringList('favoritos') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorito(String destinatario) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoritos.contains(destinatario)) {
        _favoritos.remove(destinatario);
      } else {
        _favoritos.add(destinatario);
      }
      prefs.setStringList('favoritos', _favoritos.toList());
    });
  }

  String _formatFriendlyDate(DateTime? date, String fallback) {
    if (date == null) return fallback;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;
    if (difference == 0) {
      return 'Hoje, ${DateFormat('HH:mm').format(date)}';
    } else if (difference == 1) {
      return 'Ontem, ${DateFormat('HH:mm').format(date)}';
    } else if (now.year == date.year) {
      return DateFormat('dd/MM, HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transferências'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _exportarHistoricoPDF,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Exportar histórico',
            onPressed: _exportarHistoricoCSV,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final csv = CsvUtils.toCsv(widget.history);
              await SharePlus.instance.share(ShareParams(
                  text: csv, subject: 'Exportação CSV - Papaleguas Pix'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('CSV exportado e compartilhado com sucesso!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'Exportar PDF',
            onPressed: () async {
              final pdfBytes = await PdfUtils.toPdf(widget.history);
              final tempDir = await getTemporaryDirectory();
              final file = await File('${tempDir.path}/historico_urubupix.pdf')
                  .writeAsBytes(pdfBytes);
              await SharePlus.instance.share(ShareParams(
                  files: [XFile(file.path)],
                  subject: 'Exportação PDF - Papaleguas Pix'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('PDF exportado e compartilhado com sucesso!')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    hintText: 'Digite para buscar por destinatário, valor ou data',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isFiltering = true;
                    });
                    _filterFuture?.ignore(); // cancela o delay anterior, se houver
                    _filterFuture = Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _search = value.trim().toLowerCase();
                          _isFiltering = false;
                        });
                      }
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt),
                tooltip: 'Filtros avançados',
                onPressed: () async {
                  final result = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => _FiltroAvancadoBottomSheet(
                      initialDateStart: _filtroDataInicio,
                      initialDateEnd: _filtroDataFim,
                      initialValorMin: _filtroValorMin,
                      initialValorMax: _filtroValorMax,
                      initialTipo: _filtroTipo,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _filtroDataInicio = result['dataInicio'];
                      _filtroDataFim = result['dataFim'];
                      _filtroValorMin = result['valorMin'];
                      _filtroValorMax = result['valorMax'];
                      _filtroTipo = result['tipo'];
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isFiltering
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Nenhuma transferência encontrada.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final date = DateTime.tryParse(item['data'].toString());
                        final formattedDate = _formatFriendlyDate(date, item['data'].toString());
                        return ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Row(
                            children: [
                              Text('Para: ${item['destinatario']}'),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _toggleFavorito(item['destinatario'].toString()),
                                child: Icon(
                                  _favoritos.contains(item['destinatario'].toString())
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.orange,
                                  semanticLabel: _favoritos.contains(item['destinatario'].toString())
                                      ? 'Remover dos favoritos'
                                      : 'Adicionar aos favoritos',
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('Valor: R\$ ${item['valor'].toStringAsFixed(2)}'),
                          onLongPress: () async {
                            final copied = await showModalBottomSheet<String>(
                              context: context,
                              builder: (context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.copy),
                                        title: const Text('Copiar destinatário'),
                                        onTap: () => Navigator.pop(context, 'destinatario'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.copy),
                                        title: const Text('Copiar valor'),
                                        onTap: () => Navigator.pop(context, 'valor'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.close),
                                        title: const Text('Cancelar'),
                                        onTap: () => Navigator.pop(context, null),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                            if (copied == 'destinatario') {
                              await Clipboard.setData(ClipboardData(text: item['destinatario'].toString()));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Destinatário copiado!')),
                                );
                              }
                            } else if (copied == 'valor') {
                              await Clipboard.setData(ClipboardData(text: item['valor'].toString()));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Valor copiado!')),
                                );
                              }
                            }
                          },
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formattedDate),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.info_outline, color: Colors.amber, semanticLabel: 'Ver detalhes da transferência'),
                                    label: const Text('Detalhes', style: TextStyle(color: Colors.amber)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.amber),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TransferDetailScreen(transferencia: item),
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.repeat, color: Colors.blue, semanticLabel: 'Repetir transferência'),
                                    label: const Text('Repetir', style: TextStyle(color: Colors.blue)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/transfer',
                                        arguments: {
                                          'destinatario': item['destinatario'],
                                          'valor': item['valor'],
                                        },
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Tela de transferência aberta.'),
                                            action: SnackBarAction(
                                              label: 'Desfazer',
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Ação desfeita.')),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.share, color: Colors.green, semanticLabel: 'Compartilhar transferência'),
                                    label: const Text('Compartilhar', style: TextStyle(color: Colors.green)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                                    onPressed: () async {
                                      final msg =
                                          'Transferência de R\$ ${item['valor'].toStringAsFixed(2)} para ${item['destinatario']} em ${item['data']} via Papaleguas Pix.';
                                      await SharePlus.instance.share(ShareParams(text: msg));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Transferência compartilhada!')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
