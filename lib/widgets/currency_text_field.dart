import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String currencySymbol;
  final double? maxValue;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.currencySymbol = 'R\$',
    this.maxValue,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  final _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Configura o valor inicial formatado se houver valor no controlador
    if (widget.controller.text.isNotEmpty) {
      _formatValue(widget.controller.text);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _formatValue(String value) {
    // Remove todos os caracteres não numéricos
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Se não houver dígitos, limpa o campo
    if (digits.isEmpty) {
      widget.controller.clear();
      return;
    }

    // Converte para número e formata como moeda
    double number = int.parse(digits) / 100;
    
    // Aplica o valor máximo, se definido
    if (widget.maxValue != null && number > widget.maxValue!) {
      number = widget.maxValue!;
    }
    
    String newValue = _formatter.format(number);
    
    // Atualiza o controlador com o valor formatado
    widget.controller.text = newValue.trim();
    // Move o cursor para o final do texto
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixText: '${widget.currencySymbol} ',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: (value) {
        _formatValue(value);
        widget.onChanged?.call(value);
      },
    );
  }
}

// Extensão para converter o valor formatado para double
extension CurrencyTextExtension on String {
  double toCurrencyValue() {
    if (trim().isEmpty) return 0.0;
    final cleanString = replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return 0.0;
    return (int.parse(cleanString)) / 100;
  }
}
