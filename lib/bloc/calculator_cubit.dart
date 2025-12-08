import 'package:flutter_bloc/flutter_bloc.dart';
import 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  CalculatorCubit() : super(CalculatorState());

  void input(String value) {
    // Cegah operator berurutan
    if (isOperator(value) && state.expression.isNotEmpty) {
      if (isOperator(state.expression[state.expression.length - 1])) {
        return emit(state.copyWith(error: "Operator tidak boleh berurutan"));
      }
    }

    emit(state.copyWith(
      expression: state.expression + value,
      error: null,
    ));
  }

  bool isOperator(String v) {
    return v == "+" || v == "-" || v == "×" || v == "÷";
  }

  void backspace() {
    if (state.expression.isNotEmpty) {
      emit(
        state.copyWith(
          expression: state.expression.substring(
            0,
            state.expression.length - 1,
          ),
        ),
      );
    }
  }

  void clear() {
    emit(CalculatorState());
  }

  void calculate() {
    String exp = state.expression;

    if (exp.isEmpty) {
      return emit(state.copyWith(error: "Ekspresi kosong"));
    }

    if (isOperator(exp[exp.length - 1])) {
      return emit(state.copyWith(error: "Ekspresi tidak lengkap"));
    }

    String converted = exp.replaceAll("×", "*").replaceAll("÷", "/");

    try {
      double result = _evaluate(converted);
      String hasil = _formatResult(result);

      List<String> newHistory = List.from(state.history)..add("$exp = $hasil");

      emit(
        state.copyWith(
          result: hasil,
          expression: "",
          history: newHistory,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: "Kesalahan perhitungan"));
    }
  }

  double _evaluate(String expression) {
    expression = expression.replaceAll(' ', '');

    if (expression.contains('/0')) {
      throw Exception('Division by zero');
    }

    return _parseExpression(expression);
  }

  double _parseExpression(String expression) {
    // Tambah & Kurang (prioritas terendah)
    for (int i = expression.length - 1; i >= 0; i--) {
      if (expression[i] == '+' && i > 0) {
        double left = _parseExpression(expression.substring(0, i));
        double right = _parseExpression(expression.substring(i + 1));
        return left + right;
      }
      if (expression[i] == '-' && i > 0) {
        double left = _parseExpression(expression.substring(0, i));
        double right = _parseExpression(expression.substring(i + 1));
        return left - right;
      }
    }

    // Kali & Bagi (prioritas lebih tinggi)
    for (int i = expression.length - 1; i >= 0; i--) {
      if (expression[i] == '*' && i > 0) {
        double left = _parseExpression(expression.substring(0, i));
        double right = _parseExpression(expression.substring(i + 1));
        return left * right;
      }
      if (expression[i] == '/' && i > 0) {
        double left = _parseExpression(expression.substring(0, i));
        double right = _parseExpression(expression.substring(i + 1));

        if (right == 0) throw Exception('Division by zero');

        return left / right;
      }
    }

    // Handle angka negatif
    if (expression.startsWith('-')) {
      return -_parseExpression(expression.substring(1));
    }

    // Parsing angka biasa
    return double.parse(expression);
  }

  String _formatResult(double result) {
    // Jika hasil bilangan bulat → tanpa desimal
    if (result == result.toInt()) {
      return result.toInt().toString();
    }

    // Jika desimal → batasi dan hapus trailing zero
    return result.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0*$'), '');
  }

  void clearHistory() {
    emit(state.copyWith(history: []));
  }
}
