import 'package:math_expressions/math_expressions.dart';

class CalculatorService {
  double evaluate(String expression) {
    try {
      final parser = GrammarParser();
      final exp = parser.parse(expression);
      final result = exp.evaluate(EvaluationType.REAL, ContextModel());
      if (result is num) {
        return result.toDouble();
      }
      throw CalculatorServiceException(
          'Expression did not evaluate to a number.');
    } catch (e) {
      throw CalculatorServiceException('Could not evaluate "$expression": $e');
    }
  }
}

class CalculatorServiceException implements Exception {
  final String message;
  CalculatorServiceException(this.message);

  @override
  String toString() => message;
}
