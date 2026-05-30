import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatelessWidget {
  final double saldo;
  final double totalEnviado;
  final int qtdTransf;
  final String tipoGrafico;
  final List<String> tiposGraficos;
  final Function(String?) onGraficoChanged;
  final Widget graficoWidget;
  final Widget filtrosWidget;
  final Widget listaHistoricoWidget;
  final bool mostrarTransferencias;

  const DashboardContent({
    super.key,
    required this.saldo,
    required this.totalEnviado,
    required this.qtdTransf,
    required this.tipoGrafico,
    required this.tiposGraficos,
    required this.onGraficoChanged,
    required this.graficoWidget,
    required this.filtrosWidget,
    required this.listaHistoricoWidget,
    required this.mostrarTransferencias,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildInfoCard(
          title: 'Saldo atual',
          value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(saldo),
          valueStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Total transferido',
                value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalEnviado),
                valueStyle: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: 'Transferências',
                value: qtdTransf.toString(),
                valueStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildGraficoSection(),
        if (mostrarTransferencias) ...[
          const SizedBox(height: 32),
          const Text('Últimas transferências:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          filtrosWidget,
          const SizedBox(height: 16),
          listaHistoricoWidget,
        ],
        const SizedBox(height: 32), // Espaço extra para rolagem
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required TextStyle valueStyle,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumo financeiro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                DropdownButton<String>(
                  value: tipoGrafico,
                  items: tiposGraficos
                      .map((tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          ))
                      .toList(),
                  onChanged: onGraficoChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: graficoWidget,
            ),
          ],
        ),
      ),
    );
  }
}

class FiltrosWidget extends StatelessWidget {
  final String filtroDestinatario;
  final String filtroTipo;
  final DateTime? filtroDataInicio;
  final DateTime? filtroDataFim;
  final double? filtroValorMin;
  final double? filtroValorMax;
  final String? erroFiltroData;
  final Function(String) onDestinatarioChanged;
  final Function(String?) onTipoChanged;
  final Function() onLimparFiltros;
  final Function() onDataInicioPressed;
  final Function() onDataFimPressed;
  final Function(String) onValorMinChanged;
  final Function(String) onValorMaxChanged;

  const FiltrosWidget({
    super.key,
    required this.filtroDestinatario,
    required this.filtroTipo,
    required this.filtroDataInicio,
    required this.filtroDataFim,
    required this.filtroValorMin,
    required this.filtroValorMax,
    required this.erroFiltroData,
    required this.onDestinatarioChanged,
    required this.onTipoChanged,
    required this.onLimparFiltros,
    required this.onDataInicioPressed,
    required this.onDataFimPressed,
    required this.onValorMinChanged,
    required this.onValorMaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar destinatário',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: onDestinatarioChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: filtroTipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: ['Todos', 'Enviado', 'Recebido']
                  .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      ))
                  .toList(),
              onChanged: onTipoChanged,
            ),
          ),
          const SizedBox(width: 12),
          _buildDateField(
            label: 'Data início',
            value: filtroDataInicio,
            onTap: onDataInicioPressed,
          ),
          const SizedBox(width: 12),
          _buildDateField(
            label: 'Data fim',
            value: filtroDataFim,
            onTap: onDataFimPressed,
          ),
          const SizedBox(width: 12),
          _buildNumberField(
            label: 'Valor mínimo',
            value: filtroValorMin?.toString(),
            onChanged: onValorMinChanged,
          ),
          const SizedBox(width: 12),
          _buildNumberField(
            label: 'Valor máximo',
            value: filtroValorMax?.toString(),
            onChanged: onValorMaxChanged,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.red),
            tooltip: 'Limpar filtros',
            onPressed: onLimparFiltros,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: TextField(
        readOnly: true,
        controller: TextEditingController(
            text: value != null ? DateFormat('dd/MM/yyyy').format(value) : ''),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String? value,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: TextEditingController(text: value ?? ''),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          prefixIcon: const Icon(Icons.attach_money, size: 20),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class ListaHistoricoWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historicoFiltrado;
  final int itensExibidos;
  final bool carregandoMais;
  final Function() quandoChegarNoFinal;
  final Function(DateTime) formatarData;

  const ListaHistoricoWidget({
    super.key,
    required this.historicoFiltrado,
    required this.itensExibidos,
    required this.carregandoMais,
    required this.quandoChegarNoFinal,
    required this.formatarData,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          quandoChegarNoFinal();
        }
        return false;
      },
      child: Card(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            itemCount: itensExibidos < historicoFiltrado.length
                ? itensExibidos + 1
                : historicoFiltrado.length,
            itemBuilder: (context, index) {
              if (index < itensExibidos && index < historicoFiltrado.length) {
                final item = historicoFiltrado[index];
                final destinatario = item['destinatario']?.toString() ?? 'Desconhecido';
                final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
                final data = item['data'] is DateTime
                    ? item['data'] as DateTime
                    : DateTime.now();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.swap_horiz, color: Colors.blue),
                  ),
                  title: Text(
                    'Para: $destinatario',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor: R\$ ${valor.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Data: ${formatarData(data)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    item['tipo'] == 'Enviado' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: item['tipo'] == 'Enviado' ? Colors.red : Colors.green,
                  ),
                );
              } else if (carregandoMais) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('Não há mais itens para carregar')),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
