import 'dart:collection';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flash_card/quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';

void main() => runApp(const FlashcardApp());

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData(
          colorSchemeSeed: darkDynamic == null ? const Color(0xFFFFD60A) : null,
          colorScheme: darkDynamic,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        theme: ThemeData(
          colorSchemeSeed: lightDynamic == null ? const Color(0xFFFFD60A) : null,
          brightness: Brightness.light,
          colorScheme: lightDynamic,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        title: 'FlashCard',
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('FlashCard'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child:const Padding(
                  padding: EdgeInsets.all(16),
                  child: QuizScreenBody(),
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreenBody extends StatefulWidget {
  const QuizScreenBody({super.key});

  @override
  State<QuizScreenBody> createState() => _QuizScreenBodyState();
}

class _QuizScreenBodyState extends State<QuizScreenBody> {
  final FlipCardController _controller = FlipCardController();
  final List<QuizQuestion> _quizQuestions = UnmodifiableListView(quizQuestions);
  int _currentQuestionIndex = 0;
  bool _showAnswer = false;

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
        _showAnswer = false;
      }
    });
  }

  void _onNextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _showAnswer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.0,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressBar(
          currentIndex: _currentQuestionIndex,
          totalQuestions: _quizQuestions.length,
        ),
        FlipCard(
          frontWidget: CardSection(
            text: _quizQuestions[_currentQuestionIndex].question,
            containerColor: Theme.of(context).colorScheme.secondaryContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          backWidget: CardSection(
            text: _quizQuestions[_currentQuestionIndex].answer,
            containerColor: Theme.of(context).colorScheme.surfaceVariant,
            textColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          controller: _controller,
          animationDuration: Duration(milliseconds: 500),
          // NOTE: there is a bug in the package, so rotateSide is set to bottom for both sides
          rotateSide: _showAnswer ? RotateSide.bottom : RotateSide.bottom,
          onTapFlipping: false,
          axis: FlipAxis.horizontal,
        ),
        CardControllerSection(
          onPreviousQuestion: _onPreviousQuestion,
          onNextQuestion: _onNextQuestion,
          currentQuestionIndex: _currentQuestionIndex,
          onToggleAnswerVisibility: _onToggleAnswerVisibility,
          quizQuestionLength: _quizQuestions.length,
          showAnswer: _showAnswer,
        ),
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;

  const ProgressBar({super.key, required this.currentIndex, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    final progress = ((currentIndex + 1) / totalQuestions * 100).round();
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 8.0,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: (currentIndex + 1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              height: 16,
            ),
          ),
          Text(
            '$progress%',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          Expanded(
            flex: totalQuestions - (currentIndex + 1),
            child: const SizedBox(),
          ),
          Text(
            '${currentIndex + 1} of $totalQuestions',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class CardControllerSection extends StatelessWidget {
  final void Function() onPreviousQuestion;
  final void Function() onNextQuestion;
  final void Function() onToggleAnswerVisibility;
  final bool showAnswer;
  final int currentQuestionIndex;
  final int quizQuestionLength;

  const CardControllerSection({
    super.key,
    required this.onPreviousQuestion,
    required this.onNextQuestion,
    required this.onToggleAnswerVisibility,
    required this.showAnswer,
    required this.currentQuestionIndex,
    required this.quizQuestionLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            onPressed: currentQuestionIndex <= 0 ? null : onPreviousQuestion,
            child: const Text('Previous'),
          ),
          ElevatedButton(
            onPressed: onToggleAnswerVisibility,
            child: Text(showAnswer ? 'Hide Answer' : 'Show Answer'),
          ),
          ElevatedButton(
            onPressed: currentQuestionIndex >= (quizQuestions.length - 1) ? null : onNextQuestion,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class CardSection extends StatelessWidget {
  final String text;
  final Color containerColor;
  final Color textColor;

  const CardSection({super.key, required this.text, required this.containerColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        color: containerColor,
      ),
      child: Text(
        text,
        softWrap: true,
        overflow: TextOverflow.fade,
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
