class CalculatorState {
  final String expression;
  final String result;
  final List<String> history;
  final String? error;

  CalculatorState({
    this.expression = "",
    this.result = "",
    this.history = const [],
    this.error,
  });

  CalculatorState copyWith({
    String? expression,
    String? result,
    List<String>? history,
    String? error,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      history: history ?? this.history,
      error: error,
    );
  }
}
