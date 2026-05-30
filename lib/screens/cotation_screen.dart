import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:papaleguas_pix/services/api_service.dart'
    show ApiService, logDebug;
import 'package:papaleguas_pix/widgets/currency_card.dart';

class CotationScreen extends StatefulWidget {
  const CotationScreen({super.key});

  @override
  State<CotationScreen> createState() => _CotationScreenState();
}

class _CotationScreenState extends State<CotationScreen>
    with SingleTickerProviderStateMixin {
  double? _dollarRate;
  double? _euroRate;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastUpdated;
  final TextEditingController _realController = TextEditingController();
  late AnimationController _refreshController;
  Timer? _buttonTimer;
  bool _isButtonDisabled = false;
  double? _amountInReais;
  final Map<String, bool> _hoverStates = {
    'dollar': false,
    'euro': false,
  };

  // Formatters
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Estado para armazenar o histórico de cotações
  Map<String, List<MapEntry<DateTime, double>>> _rateHistory = {
    'USD': [],
    'EUR': [],
  };
  bool _isLoadingHistory = false;

  // Carrega o histórico de cotações
  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;

    logDebug('Iniciando carregamento do histórico...');
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      logDebug('Carregando histórico de cotações...');
      final history = await ApiService.getExchangeRateHistory();

      // O histórico já vem no formato correto: Map<String, List<MapEntry<DateTime, double>>>
      logDebug(
          'Histórico carregado - USD: ${history['USD']?.length ?? 0} itens, EUR: ${history['EUR']?.length ?? 0} itens');

      setState(() {
        _rateHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e, stackTrace) {
      logDebug('Erro ao carregar histórico: $e');
      logDebug('Stack trace: $stackTrace');

      // Usar dados de exemplo em caso de erro
      logDebug('Usando dados de exemplo devido ao erro');
      final now = DateTime.now();
      final exampleData = <String, List<MapEntry<DateTime, double>>>{
        'USD': [
          MapEntry(now.subtract(const Duration(days: 6)), 5.1),
          MapEntry(now.subtract(const Duration(days: 5)), 5.2),
          MapEntry(now.subtract(const Duration(days: 4)), 5.0),
          MapEntry(now.subtract(const Duration(days: 3)), 5.3),
          MapEntry(now.subtract(const Duration(days: 2)), 5.2),
          MapEntry(now.subtract(const Duration(days: 1)), 5.4),
          MapEntry(now, 5.5),
        ],
        'EUR': [
          MapEntry(now.subtract(const Duration(days: 6)), 5.5),
          MapEntry(now.subtract(const Duration(days: 5)), 5.6),
          MapEntry(now.subtract(const Duration(days: 4)), 5.4),
          MapEntry(now.subtract(const Duration(days: 3)), 5.7),
          MapEntry(now.subtract(const Duration(days: 2)), 5.6),
          MapEntry(now.subtract(const Duration(days: 1)), 5.8),
          MapEntry(now, 5.9),
        ],
      };

      setState(() {
        _rateHistory = exampleData;
        _isLoadingHistory = false;
      });

      // Mostrar mensagem de erro para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Dados de exemplo carregados devido a um erro na conexão'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('CotationScreen: initState');
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fetchCotacoes();
    _loadHistory();
  }

  @override
  void dispose() {
    debugPrint('CotationScreen: dispose');
    _realController.dispose();
    _refreshController.dispose();
    _buttonTimer?.cancel();
    super.dispose();
  }

  final ApiService _apiService = ApiService();

  Future<void> _fetchCotacoes() async {
    if ((_isLoading && _isRefreshing) || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      debugPrint('Buscando cotações...');
      final rates = await _apiService.getExchangeRates();

      if (!mounted) return;

      setState(() {
        _dollarRate = rates['USD'];
        _euroRate = rates['EUR'];
        _isLoading = false;
        _isRefreshing = false;
        _lastUpdated = DateTime.now();
      });

      debugPrint('Cotações carregadas: USD=$_dollarRate, EUR=$_euroRate');
    } catch (e) {
      debugPrint('Erro ao buscar cotações: $e');
      if (!mounted) return;

      setState(() {
        _error = 'Erro ao carregar cotações. Tente novamente.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _onRefresh() {
    if (_isButtonDisabled) return;

    _disableButtonTemporarily();
    _refreshController.reset();
    _refreshController.forward();
    _fetchCotacoes();
    _loadHistory();
  }

  void _disableButtonTemporarily() {
    setState(() => _isButtonDisabled = true);
    _buttonTimer?.cancel();
    _buttonTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isButtonDisabled = false);
      }
    });
  }

  String _getConvertedAmount(double rate) {
    if (_amountInReais == null) return '0.00';
    final converted = _amountInReais! / rate;
    return converted.toStringAsFixed(2);
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) {
      setState(() => _amountInReais = null);
      return;
    }

    final amount =
        double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() => _amountInReais = amount / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isButtonDisabled,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_isButtonDisabled) {
          debugPrint('PopScope: voltando...');
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Câmbio'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isButtonDisabled
                ? null
                : () {
                    debugPrint('Botão voltar pressionado');
                    Navigator.of(context).pop();
                  },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar cotações',
              onPressed: () {
                final dolar = _dollarRate != null
                    ? 'R\$ ${_dollarRate!.toStringAsFixed(2)}'
                    : 'indisponível';
                final euro = _euroRate != null
                    ? 'R\$ ${_euroRate!.toStringAsFixed(2)}'
                    : 'indisponível';
                SharePlus.instance.share(ShareParams(
                  text:
                      '💱 Cotações do dia:\n🇺🇸 Dólar: $dolar\n🇪🇺 Euro: $euro\n\nVia Papaleguas Pix',
                ));
              },
            ),
            IconButton(
              icon: RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_refreshController),
                child: const Icon(Icons.refresh),
              ),
              onPressed: _isButtonDisabled ? null : _onRefresh,
            ),
          ],
        ),
        body: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchCotacoes,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de valor em reais
            TextField(
              controller: _realController,
              decoration: InputDecoration(
                labelText: 'Valor em Reais',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _realController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _realController.clear();
                          _onAmountChanged('');
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _RealInputFormatter(),
              ],
              onChanged: _onAmountChanged,
            ),

            const SizedBox(height: 24.0),

            // Cards de cotações
            _buildDollarCard(theme),
            const SizedBox(height: 16.0),
            _buildEuroCard(theme),

            if (_error != null) ...[
              const SizedBox(height: 16.0),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (_lastUpdated != null) ...[
              const SizedBox(height: 16.0),
              Text(
                'Atualizado em ${DateFormat('HH:mm:ss').format(_lastUpdated!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withAlpha((255 * 0.6).round()),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Constrói o gráfico de variação
  Widget _buildChart(String currency, ThemeData theme) {
    logDebug('_buildChart chamado para $currency');
    logDebug('_isLoadingHistory: $_isLoadingHistory');
    logDebug('_rateHistory.keys: ${_rateHistory.keys.toList()}');
    logDebug(
        '_rateHistory[$currency]: ${_rateHistory[currency]?.length ?? 0} pontos');

    if (_isLoadingHistory) {
      logDebug('Mostrando indicador de carregamento para $currency');
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                'Carregando histórico...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final history = _rateHistory[currency] ?? [];
    logDebug('Construindo gráfico para $currency - ${history.length} pontos');

    // Log detalhado dos pontos de dados
    for (var i = 0; i < history.length; i++) {
      logDebug('Ponto $i: ${history[i].key} = ${history[i].value}');
    }

    if (history.isEmpty) {
      logDebug('Sem histórico disponível para $currency');
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dados de histórico não disponíveis',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Log detalhado dos pontos do gráfico
    logDebug('Preparando pontos do gráfico para $currency');
    final spots = history.asMap().entries.map((entry) {
      final date = entry.value.key;
      final value = entry.value.value;
      logDebug('Ponto ${entry.key}: ${date.toIso8601String()} = $value');
      return FlSpot(
        entry.key.toDouble(),
        value,
      );
    }).toList();

    // Encontra os valores mínimo e máximo para o eixo Y
    final minY =
        (history.map((e) => e.value).reduce((a, b) => a < b ? a : b) * 0.99);
    final maxY =
        (history.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.01);

    logDebug('Valores Y - Mínimo: $minY, Máximo: $maxY');

    // Verifica se os valores são válidos
    if (minY.isNaN || maxY.isNaN || minY.isInfinite || maxY.isInfinite) {
      logDebug('Valores de Y inválidos - minY: $minY, maxY: $maxY');
      return Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                'Dados de histórico inválidos',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // Prepara os títulos do eixo X (datas)
    final bottomTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, _) {
          final index = value.toInt();
          if (index >= 0 && index < history.length) {
            final date = history[index].key;
            final formattedDate = DateFormat('dd/MM').format(date);
            logDebug('Rótulo do eixo X: índice $index = $formattedDate');
            return Text(
              formattedDate,
              style: theme.textTheme.bodySmall!.copyWith(fontSize: 10),
            );
          }
          logDebug(
              'Índice fora do intervalo: $index (tamanho: ${history.length})');
          return const SizedBox.shrink();
        },
        reservedSize: 40, // Aumentado para garantir que as datas caibam
        interval: 1,
      ),
    );

    // Cores do gráfico
    final lineColor = currency == 'USD' ? Colors.green : Colors.blue;
    final fillColor = lineColor.withAlpha((255 * 0.1).round());

    logDebug('Renderizando gráfico com ${spots.length} pontos');

    try {
      return Container(
        height: 200,
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 24,
          left: 8,
          right: 8,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: bottomTitles,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: fillColor,
                ),
              ),
            ],
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      'R\$${spot.y.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      logDebug('Erro ao renderizar gráfico: $e');
      logDebug('Stack trace: $stackTrace');

      return Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              const Text(
                'Erro ao carregar o gráfico',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Usar memoization para evitar reconstruções desnecessárias
  Widget _buildDollarCard(ThemeData theme) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              onTap: () {},
              onHover: (isHovered) {
                if (!mounted || _isButtonDisabled) return;
                setState(() => _hoverStates['dollar'] = isHovered);
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hoverStates['dollar']! ? 0.9 : 1.0,
                child: CurrencyCard(
                  key: const ValueKey('card-dolar'),
                  currencyName: 'Dólar Americano',
                  currencyCode: 'USD',
                  amount: _dollarRate != null
                      ? '1 USD = ${_currencyFormat.format(_dollarRate)}'
                      : '--',
                  convertedAmount: _amountInReais != null && _dollarRate != null
                      ? '${_getConvertedAmount(_dollarRate!)} USD'
                      : '0.00 USD',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  isLoading: _isLoading,
                ),
              ),
            ),
            _buildChart('USD', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEuroCard(ThemeData theme) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              onTap: () {},
              onHover: (isHovered) {
                if (!mounted || _isButtonDisabled) return;
                setState(() => _hoverStates['euro'] = isHovered);
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hoverStates['euro']! ? 0.9 : 1.0,
                child: CurrencyCard(
                  key: const ValueKey('card-euro'),
                  currencyName: 'Euro',
                  currencyCode: 'EUR',
                  amount: _euroRate != null
                      ? '1 EUR = ${_currencyFormat.format(_euroRate!)}'
                      : '--',
                  convertedAmount: _amountInReais != null && _euroRate != null
                      ? '${_getConvertedAmount(_euroRate!)} EUR'
                      : '0.00 EUR',
                  icon: Icons.euro,
                  color: Colors.blue,
                  isLoading: _isLoading,
                ),
              ),
            ),
            _buildChart('EUR', theme),
          ],
        ),
      ),
    );
  }
}

class _RealInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove todos os caracteres não numéricos
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Converte para inteiro para evitar problemas com zeros à esquerda
    final value = int.tryParse(cleanText) ?? 0;

    // Formata como moeda brasileira (R$ 0,00)
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );

    final newText = formatter.format(value / 100);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
