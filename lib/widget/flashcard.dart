import 'dart:collection';

import 'package:flash_card/widget/app_bottom_nav.dart';
import 'package:flash_card/widget/app_scaffold.dart';
import 'package:flash_card/widget/quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';

// --- 1. WIDGET MÀN HÌNH CHÍNH ---
// Widget này chứa cấu trúc cơ bản của màn hình (Scaffold, AppBar).
class FlashcardScreen extends StatelessWidget {
  final bool showBottomNav;
  final bool showBackButton;
  final ValueChanged<BottomNavItem>? onNavItemSelected;

  const FlashcardScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
    this.onNavItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Flashcard',
      showBackButton: showBackButton,
      currentItem: BottomNavItem.flashcard,
      showBottomNav: showBottomNav,
      onNavItemSelected: onNavItemSelected,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: QuizScreenBody(),
      ),
    );
  }
}

// --- 2. WIDGET NỘI DUNG FLASHCARD ---
// Widget này quản lý trạng thái và giao diện của phần flashcard.
class QuizScreenBody extends StatefulWidget {
  const QuizScreenBody({super.key});

  @override
  State<QuizScreenBody> createState() => _QuizScreenBodyState();
}

class _QuizScreenBodyState extends State<QuizScreenBody> {
  // --- Biến Trạng Thái ---
  final FlipCardController _controller = FlipCardController();
  final List<QuizQuestion> _quizQuestions = UnmodifiableListView(quizQuestions);
  int _currentQuestionIndex = 0;
  bool _showAnswer = false;

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
      if (_currentQuestionIndex < _quizQuestions.length - 1) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ProgressBar(
          currentIndex: _currentQuestionIndex,
          totalQuestions: _quizQuestions.length,
        ),
        const SizedBox(height: 40),
        FlipCard(
          frontWidget: CardSection(
            text: _quizQuestions[_currentQuestionIndex].question,
            color: const Color(0xFFEED3FA), // Màu thẻ câu hỏi
          ),
          backWidget: CardSection(
            text: _quizQuestions[_currentQuestionIndex].answer,
            color: const Color(0xFFE3E1F6), // Màu thẻ đáp án
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
          quizQuestionLength: _quizQuestions.length,
          showAnswer: _showAnswer,
        ),
        const Spacer(),
      ],
    );
  }
}

// --- 3. CÁC WIDGET PHỤ ---

// Widget hiển thị thanh tiến trình.
class ProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;

  const ProgressBar({super.key, required this.currentIndex, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    final progressValue = (currentIndex + 1) / totalQuestions;
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

// Widget hiển thị nội dung của thẻ.
class CardSection extends StatelessWidget {
  final String text;
  final Color color;

  const CardSection({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // Tăng chiều cao
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: color, // Sử dụng màu được truyền vào
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        softWrap: true,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }
}

// Widget chứa các nút điều khiển.
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
