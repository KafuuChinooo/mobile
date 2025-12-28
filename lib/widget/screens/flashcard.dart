import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';

class FlashcardScreen extends StatelessWidget {
  final Deck deck;
  final bool showBottomNav;
  final bool showBackButton;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const FlashcardScreen({
    super.key,
    required this.deck,
    this.showBottomNav = false,
    this.showBackButton = true,
    this.onNavItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: deck.title,
      showBackButton: showBackButton,
      currentItem: BottomNavItem.decks,
      showBottomNav: showBottomNav,
      onNavItemSelected: onNavItemSelected,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: QuizScreenBody(deck: deck),
      ),
    );
  }
}

class QuizScreenBody extends StatefulWidget {
  final Deck deck;

  const QuizScreenBody({super.key, required this.deck});

  @override
  State<QuizScreenBody> createState() => _QuizScreenBodyState();
}

class _QuizScreenBodyState extends State<QuizScreenBody> {
  final FlipCardController _controller = FlipCardController();
  List<DeckCard> _cards = [];
  bool _isLoading = true;
  String? _error;
  bool _showLearned = true;
  int _currentQuestionIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.deck.lastStudiedIndex;
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await deckRepository.fetchCards(widget.deck.id);
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _isLoading = false;
        if (_currentQuestionIndex >= _cards.length) {
          _currentQuestionIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load cards: $e';
      });
    }
  }

  double _learnedProgress({bool completeIfNoneMarked = false}) {
    if (_cards.isEmpty) return 0.0;
    final learnedCount = _cards.where((c) => c.learned).length;
    if (learnedCount == 0 && completeIfNoneMarked) return 1.0;
    return learnedCount / _cards.length;
  }

  Future<void> _saveProgress({bool completeIfNoneMarked = false}) async {
    if (_cards.isEmpty) return;
    final progress = _learnedProgress(completeIfNoneMarked: completeIfNoneMarked);
    final lastIndex = _currentQuestionIndex.clamp(0, _cards.length - 1).toInt();
    await deckRepository.updateDeckProgress(
      widget.deck.id,
      progress,
      lastIndex,
    );
  }

  List<DeckCard> get _visibleCards {
    if (_showLearned) return _cards;
    return _cards.where((c) => !c.learned).toList();
  }

  Future<void> _toggleLearned(DeckCard card) async {
    final updated = card.copyWith(learned: !card.learned);
    setState(() {
      final idx = _cards.indexWhere((c) => c.id == card.id);
      if (idx != -1) _cards[idx] = updated;
    });
    await deckRepository.updateCardLearned(widget.deck.id, card.id, updated.learned);
    await _saveProgress();
  }

  void _onToggleAnswerVisibility() {
    setState(() {
      _controller.flipcard();
      _showAnswer = !_showAnswer;
    });
  }

  void _onPreviousQuestion() {
    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
        if (_showAnswer) {
          _controller.flipcard();
          _showAnswer = false;
        }
        _saveProgress();
      }
    });
  }

  void _onNextQuestion() {
    final total = _visibleCards.length;
    if (total == 0) return;
    if (_currentQuestionIndex < total - 1) {
      setState(() {
        _currentQuestionIndex++;
        if (_showAnswer) {
          _controller.flipcard();
          _showAnswer = false;
        }
      });
      _saveProgress();
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _finalizeCompletion() async {
    if (_cards.isEmpty) {
      await _saveProgress(completeIfNoneMarked: true);
      return;
    }

    final learnedCount = _cards.where((c) => c.learned).length;
    if (learnedCount == 0) {
      final updated = _cards.map((c) => c.copyWith(learned: true)).toList();
      setState(() {
        _cards = updated;
      });
      for (final card in updated) {
        await deckRepository.updateCardLearned(widget.deck.id, card.id, true);
      }
    }

    await _saveProgress(completeIfNoneMarked: true);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Congratulations!"),
          content: const Text("You have completed this deck."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentQuestionIndex = 0;
                  if (_showAnswer) {
                    _controller.flipcard();
                    _showAnswer = false;
                  }
                });
                _saveProgress();
              },
              child: const Text("Study Again"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _finalizeCompletion();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7233FE)),
              child: const Text("Finish", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_cards.isEmpty) {
      return const Center(
        child: Text('This deck has no cards.', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    final visible = _visibleCards;
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All cards are marked learned.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showLearned = true),
              child: const Text('Show learned cards'),
            ),
          ],
        ),
      );
    }
    if (_currentQuestionIndex >= visible.length) {
      _currentQuestionIndex = 0;
    }
    final currentCard = visible[_currentQuestionIndex];
    final totalCards = _cards.length;
    final learnedCount = _cards.where((c) => c.learned).length;
    final learnedProgress = _learnedProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ProgressBar(
          learnedCount: learnedCount,
          totalQuestions: totalCards,
          progressValue: learnedProgress,
        ),
        const SizedBox(height: 40),
        FlipCard(
          frontWidget: CardSection(
            text: currentCard.front,
            color: const Color(0xFFEED3FA),
          ),
          backWidget: CardSection(
            text: currentCard.back,
            color: const Color(0xFFE3E1F6),
          ),
          controller: _controller,
          animationDuration: const Duration(milliseconds: 300),
          rotateSide: RotateSide.bottom,
          onTapFlipping: false,
          axis: FlipAxis.horizontal,
        ),
        const SizedBox(height: 32),
        CardControllerSection(
          onPreviousQuestion: _onPreviousQuestion,
          onNextQuestion: _onNextQuestion,
          onToggleAnswerVisibility: _onToggleAnswerVisibility,
          currentQuestionIndex: _currentQuestionIndex,
          quizQuestionLength: visible.length,
          showAnswer: _showAnswer,
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: const Text('Show learned'),
                selected: _showLearned,
                onSelected: (v) => setState(() => _showLearned = v),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _toggleLearned(currentCard),
                icon: Icon(currentCard.learned ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(currentCard.learned ? 'Mark unlearned' : 'Mark learned'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: TextButton.icon(
            onPressed: () async {
              await _saveProgress();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save_alt, color: Colors.grey),
            label: const Text("Save & Exit", style: TextStyle(color: Colors.grey)),
          ),
        )
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double progressValue;
  final int learnedCount;
  final int totalQuestions;

  const ProgressBar({
    super.key,
    required this.progressValue,
    required this.learnedCount,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progressValue.clamp(0.0, 1.0).toDouble();
    final progressPercentage = (clampedProgress * 100).round();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7233FE)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$progressPercentage%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('$learnedCount of $totalQuestions learned', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class CardSection extends StatelessWidget {
  final String text;
  final Color color;

  const CardSection({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          softWrap: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ),
    );
  }
}

class CardControllerSection extends StatelessWidget {
  final VoidCallback onPreviousQuestion;
  final VoidCallback onNextQuestion;
  final VoidCallback onToggleAnswerVisibility;
  final int currentQuestionIndex;
  final int quizQuestionLength;
  final bool showAnswer;

  const CardControllerSection({
    super.key,
    required this.onPreviousQuestion,
    required this.onNextQuestion,
    required this.onToggleAnswerVisibility,
    required this.currentQuestionIndex,
    required this.quizQuestionLength,
    required this.showAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastCard = currentQuestionIndex >= (quizQuestionLength - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: currentQuestionIndex <= 0 ? null : onPreviousQuestion,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: const Color(0xFFF3EDFF),
            padding: const EdgeInsets.all(12),
            elevation: 0,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7233FE), size: 20),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onToggleAnswerVisibility,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7233FE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
          ),
          child: Text(
            showAnswer ? 'Hide Answer' : 'Show Answer',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: onNextQuestion,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: isLastCard ? const Color(0xFF7233FE) : const Color(0xFFF3EDFF),
            padding: const EdgeInsets.all(12),
            elevation: 0,
          ),
          child: Icon(
            isLastCard ? Icons.check : Icons.arrow_forward_ios,
            color: isLastCard ? Colors.white : const Color(0xFF7233FE),
            size: 20,
          ),
        ),
      ],
    );
  }
}
