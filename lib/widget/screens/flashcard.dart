import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';

// --- 1. WIDGET MÀN HÌNH CHÍNH ---
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

// --- 2. WIDGET NỘI DUNG FLASHCARD ---
class QuizScreenBody extends StatefulWidget {
  final Deck deck;

  const QuizScreenBody({super.key, required this.deck});

  @override
  State<QuizScreenBody> createState() => _QuizScreenBodyState();
}

class _QuizScreenBodyState extends State<QuizScreenBody> {
  // --- Biến Trạng Thái ---
  final FlipCardController _controller = FlipCardController();
  List<DeckCard> _cards = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await deckRepository.fetchCards(widget.deck.id);
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error loading cards: $e");
    }
  }

  // --- Phương Thức Hỗ Trợ ---
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
      }
    });
  }

  void _onNextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _cards.length - 1) {
        _currentQuestionIndex++;
        if (_showAnswer) {
          _controller.flipcard();
          _showAnswer = false;
        }
      }
    });
  }

  // --- Giao Diện ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cards.isEmpty) {
      return const Center(
        child: Text('This deck has no cards.', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    final currentCard = _cards[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ProgressBar(
          currentIndex: _currentQuestionIndex,
          totalQuestions: _cards.length,
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
          quizQuestionLength: _cards.length,
          showAnswer: _showAnswer,
        ),
        const Spacer(),
      ],
    );
  }
}

// --- 3. CÁC WIDGET PHỤ ---

class ProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;

  const ProgressBar({super.key, required this.currentIndex, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    final progressValue = totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;
    final progressPercentage = (progressValue * 100).round();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
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
            Text('${currentIndex + 1} of $totalQuestions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
  final void Function() onPreviousQuestion;
  final void Function() onNextQuestion;
  final void Function() onToggleAnswerVisibility;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: currentQuestionIndex <= 0 ? null : onPreviousQuestion,
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: const Color(0xFFF3EDFF),
              padding: const EdgeInsets.all(12), 
              elevation: 0),
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
          child: Text(showAnswer ? 'Hide Answer' : 'Show Answer', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: currentQuestionIndex >= (quizQuestionLength - 1) ? null : onNextQuestion,
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: const Color(0xFFF3EDFF),
              padding: const EdgeInsets.all(12),
              elevation: 0),
          child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF7233FE), size: 20),
        ),
      ],
    );
  }
}
