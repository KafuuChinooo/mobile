import 'dart:math';

import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/quiz_engine.dart';
import 'package:flutter/material.dart';

class WaterSortScreen extends StatefulWidget {
  final String deckName;
  final List<DeckCard> cards;
  final QuizEngine engine;

  const WaterSortScreen({
    super.key,
    required this.deckName,
    required this.cards,
    required this.engine,
  });

  @override
  State<WaterSortScreen> createState() => _WaterSortScreenState();
}

class _WaterSortScreenState extends State<WaterSortScreen> {
  static const int _tubeCapacity = 4;
  static const int _bonusMoves = 3;
  static const Color _accent = Color(0xFF9D90FF); // align with app purple
  static const Color _bg = Color(0xFFF7F7FB); // light app background
  static const Color _outline = Color(0xFFDAD2FF);
  final Random _rand = Random();

  // Fixed palette (3 colors) to mirror the reference look.
  static const List<Color> _palette = [
    Color(0xFF2D9CDB), // blue
    Color(0xFFD62828), // red
    Color(0xFFF2994A), // orange
  ];

  late List<List<Color>> _tubes;
  late List<QuizQuestion> _questions;
  int _questionIndex = 0;
  int _movesLeft = _bonusMoves;
  int? _selectedTube;
  bool _showingQuestion = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _questions = widget.engine.buildQuestions(widget.cards);
    _tubes = _buildRandomTubes();
    _movesLeft = _bonusMoves;
    _selectedTube = null;
    _questionIndex = 0;
    _won = false;
  }

  List<List<Color>> _buildRandomTubes() {
    // Build a bag of colors (4 of each) and shuffle
    final colorIndexes = <int>[];
    for (var i = 0; i < _palette.length; i++) {
      colorIndexes.addAll(List.filled(_tubeCapacity, i));
    }
    colorIndexes.shuffle(_rand);

    // Fill one tube per color count, then add two empties
    final tubes = <List<Color>>[];
    final filledTubeCount = _palette.length;
    for (var i = 0; i < filledTubeCount; i++) {
      final start = i * _tubeCapacity;
      final chunk = colorIndexes.sublist(start, start + _tubeCapacity);
      tubes.add(chunk.map((idx) => _palette[idx]).toList());
    }
    tubes.addAll(List.generate(2, (_) => <Color>[]));

    // Ensure at least one mixed tube so the puzzle isn't pre-solved
    final hasMixed = tubes.any((tube) => tube.length > 1 && tube.toSet().length > 1);
    if (!hasMixed) return _buildRandomTubes();

    tubes.shuffle(_rand);
    return tubes;
  }

  void _onTubeTap(int index) {
    if (_won) return;
    if (_movesLeft <= 0) {
      _askQuestion();
      return;
    }

    final source = _selectedTube;
    if (source == null) {
      if (_tubes[index].isEmpty) return;
      setState(() => _selectedTube = index);
      return;
    }

    if (source == index) {
      setState(() => _selectedTube = null);
      return;
    }

    _pour(source, index);
  }

  void _pour(int from, int to) {
    final fromTube = _tubes[from];
    final toTube = _tubes[to];
    if (fromTube.isEmpty || toTube.length == _tubeCapacity) return;

    final movingColor = fromTube.last;
    final space = _tubeCapacity - toTube.length;
    if (toTube.isNotEmpty && toTube.last != movingColor) return;

    var moveCount = 0;
    for (var i = fromTube.length - 1; i >= 0; i--) {
      if (fromTube[i] == movingColor && moveCount < space) {
        moveCount++;
      } else {
        break;
      }
    }

    if (moveCount == 0) return;

    setState(() {
      for (var i = 0; i < moveCount; i++) {
        fromTube.removeLast();
        toTube.add(movingColor);
      }
      _selectedTube = null;
      _movesLeft -= 1;
    });

    if (_isSolved(_tubes)) {
      setState(() => _won = true);
      _showWinDialog();
      return;
    }

    if (_movesLeft <= 0) {
      _askQuestion();
    }
  }

  bool _isSolved(List<List<Color>> tubes) {
    for (final tube in tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != _tubeCapacity) return false;
      if (!tube.every((c) => c == tube.first)) return false;
    }
    return true;
  }

  QuizQuestion? _nextQuestion() {
    if (_questions.isEmpty) return null;
    if (_questionIndex >= _questions.length) _questionIndex = 0;
    final q = _questions[_questionIndex];
    _questionIndex = (_questionIndex + 1) % _questions.length;
    return q;
  }

  Future<void> _askQuestion() async {
    if (_showingQuestion) return;
    final firstQuestion = _nextQuestion();
    if (firstQuestion == null) {
      setState(() => _movesLeft = _bonusMoves);
      return;
    }

    _showingQuestion = true;
    QuizQuestion current = firstQuestion;
    bool answeredCorrect = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('Answer to earn moves'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.term, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...current.options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          onPressed: () {
                            if (option == current.correctAnswer) {
                              answeredCorrect = true;
                              Navigator.of(context).pop();
                            } else {
                              final next = _nextQuestion();
                              if (next != null) {
                                setModalState(() => current = next);
                              }
                            }
                          },
                          child: Text(option),
                        ),
                      ),
                    ),
                    const Text(
                      'Wrong switches to another question. Correct answer gives +3 moves.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _showingQuestion = false;
        _movesLeft = answeredCorrect ? _bonusMoves : 0;
      });
    }
  }

  void _showWinDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Completed!'),
        content: const Text('You sorted all tubes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(_initGame);
            },
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deckName} - Water Sort'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: _bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _StatusChip(label: 'Moves left', value: _movesLeft.toString(), accent: _accent),
                const SizedBox(width: 8),
                _StatusChip(label: 'Tubes', value: '${_tubes.length}', accent: _accent),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(_initGame),
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.black87),
                  label: const Text('Reset', style: TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Every 3 moves a question appears. Answer correctly to gain 3 more moves.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.28,
                  ),
                  itemCount: _tubes.length,
                  itemBuilder: (context, index) {
                    final tube = _tubes[index];
                    final selected = _selectedTube == index;
                    return _TubeWidget(
                      capacity: _tubeCapacity,
                      colors: tube,
                      selected: selected,
                      accent: _accent,
                      outline: _outline,
                      onTap: () => _onTubeTap(index),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TubeWidget extends StatelessWidget {
  final int capacity;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color outline;

  const _TubeWidget({
    required this.capacity,
    required this.colors,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final slots = List<Color?>.filled(capacity, null);
    for (var i = 0; i < colors.length; i++) {
      slots[i] = colors[i];
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? accent : outline, width: 3),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(capacity, (i) {
              final color = slots[capacity - i - 1];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: color ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatusChip({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}
