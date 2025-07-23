import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(SimpleCalculator());

class SimpleCalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: CalculatorHomePage(),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  @override
  _CalculatorHomePageState createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  String input = '';
  String result = '';
  bool showAdvanced = false;
  bool showHistory = true;
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void numClick(String text) {
    setState(() {
      final operators = ['+', '-', '×', '÷'];
      if (operators.contains(text)) {
        if (input.isEmpty) {
          if (text == '-') {
            input += text;
          }
        } else {
          if (operators.contains(input[input.length - 1])) {
            input = input.substring(0, input.length - 1) + text;
          } else {
            input += text;
          }
        }
      } else {
        input += text;
      }
    });
  }

  void clear() {
    setState(() {
      input = '';
      result = '';
    });
  }

  void calculate() async {
    if (input.trim().isEmpty) return;

    final operators = ['+', '-', '×', '÷', '^', '%'];
    final hasOperator = operators.any((op) => input.contains(op));

    if (!hasOperator) {
      double singleVal = double.tryParse(input) ?? 0;
      String finalResult = (singleVal == singleVal.toInt())
          ? singleVal.toInt().toString()
          : singleVal.toString();

      setState(() {
        result = '= $finalResult';
        history.insert(0, '$input = $finalResult');
      });
      await saveHistory();
      return;
    }

    try {
      String finalInput = input
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.141592653589793')
          .replaceAll('%', 'mod');

      finalInput = finalInput.replaceAllMapped(
        RegExp(r'lg\((.*?)\)'),
        (match) => 'log(10, ${match.group(1)})',
      );
      finalInput = finalInput.replaceAllMapped(
        RegExp(r'sin\((.*?)\)'),
        (match) => 'sin((${match.group(1)}) * ${3.141592653589793} / 180)',
      );
      finalInput = finalInput.replaceAllMapped(
        RegExp(r'cos\((.*?)\)'),
        (match) => 'cos((${match.group(1)}) * ${3.141592653589793} / 180)',
      );
      finalInput = finalInput.replaceAllMapped(
        RegExp(r'tan\((.*?)\)'),
        (match) => 'tan((${match.group(1)}) * ${3.141592653589793} / 180)',
      );
      finalInput = finalInput.replaceAllMapped(
        RegExp(r'(\d+)!'),
        (match) {
          int n = int.parse(match.group(1)!);
          int f = 1;
          for (int i = 1; i <= n; i++) f *= i;
          return f.toString();
        },
      );

      if (RegExp(r'/\s*0([^\d]|$)').hasMatch(finalInput)) {
        setState(() {
          result = 'Can’t divide by 0.';
        });
        return;
      }

      int open = '('.allMatches(finalInput).length;
      int close = ')'.allMatches(finalInput).length;
      if (open > close) {
        finalInput += ')' * (open - close);
      }

      Parser p = Parser();
      Expression exp = p.parse(finalInput);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval.isInfinite || eval.isNaN) {
        setState(() {
          result = 'Error';
        });
      } else {
        String finalResult =
            (eval == eval.toInt()) ? eval.toInt().toString() : eval.toString();
        setState(() {
          result = '$finalResult';
          history.insert(0, '$input = $finalResult');
        });
        await saveHistory();
      }
    } catch (e) {
      setState(() {
        result = 'Error';
      });
    }
  }

  void clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    setState(() {
      history.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History Cleared!')),
    );
  }

  Future<void> saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      history = prefs.getStringList('history') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Calculator'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                showHistory = !showHistory;
              });
            },
            onLongPress: () {
              clearHistory();
            },
            child: IconButton(
              icon: Icon(
                showHistory ? Icons.history : Icons.history_toggle_off,
              ),
              tooltip: showHistory ? 'Hide History' : 'Show History',
              onPressed: null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;

            final basicButtons = [
              '7',
              '8',
              '9',
              '÷',
              '4',
              '5',
              '6',
              '×',
              '1',
              '2',
              '3',
              '-',
              'C',
              '0',
              '=',
              '+',
            ];

            final advancedButtons = [
              'sin(',
              'cos(',
              'tan(',
              'π',
              'lg(',
              'ln(',
              '1/(',
              '!',
              '(',
              ')',
              '^',
              '%',
              'BACK',
            ];

            final buttons = showAdvanced
                ? [...basicButtons, ...advancedButtons]
                : basicButtons;

            return Column(
              children: [
                if (showHistory && history.isNotEmpty)
                  Column(
                    children: [
                      Container(
                        height: 100,
                        padding: const EdgeInsets.all(8),
                        child: ListView.builder(
                          reverse: true,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return Text(
                              history[index],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton.icon(
                        onPressed: clearHistory,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text(
                          'Clear History',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            input,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result,
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAdvanced = !showAdvanced;
                    });
                  },
                  child: Text(
                    showAdvanced ? 'Back to Basic' : 'Show Advanced',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: buttons.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isPortrait ? 4 : 6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final text = buttons[index];
                        return CalculatorButton(
                          text: text,
                          onTap: () {
                            if (text == 'C') {
                              clear();
                            } else if (text == '=') {
                              calculate();
                            } else if (text == 'BACK') {
                              setState(() => showAdvanced = false);
                            } else {
                              numClick(text);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CalculatorButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final basicOperators = ['+', '-', '×', '÷', 'C'];
    final advancedOperators = [
      'sin(',
      'cos(',
      'tan(',
      'π',
      'ln(',
      'lg(',
      '1/(',
      '!',
      'BACK',
      '(',
      ')',
      '^',
      '%',
    ];
    final isEqual = text == '=';
    final isAdvanced = advancedOperators.contains(text);
    final isBasicOperator = basicOperators.contains(text);

    Color buttonColor;
    Color textColor;

    if (isEqual) {
      buttonColor = Colors.orange;
      textColor = Colors.white;
    } else if (isAdvanced || isBasicOperator) {
      buttonColor = Colors.white;
      textColor = Colors.orange;
    } else {
      buttonColor = Colors.grey.shade200;
      textColor = Colors.black;
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.zero,
        elevation: 2,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
