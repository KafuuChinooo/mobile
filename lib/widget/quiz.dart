class QuizQuestion {
  final String question;
  final String answer;
  final String category;

  QuizQuestion({
    required this.question,
    required this.answer,
    required this.category,
  });
}

final List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    question: "Natural disaster (n)",
    answer:
        "Thảm họa thiên nhiên",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Greenhouse effect (n)",
    answer:
        "Hiệu ứng nhà kính",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Rising sea levels (n. phr.)",
    answer:
        "Mực nước biển dâng",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Habitat loss (n)",
    answer:
        "Mất môi trường sống",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Climate change (n)",
    answer:
        "Biến đổi khí hậu",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Global warming (n)",
    answer:
        "Sự nóng lên toàn cầu",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Air pollution (n)",
    answer:
        "Ô nhiễm không khí",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Water contamination (n)",
    answer:
        "Ô nhiễm nguồn nước",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Deforestation (n)",
    answer:
        "Nạn phá rừng",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Overfishing (n)",
    answer:
        "Đánh bắt cá quá mức",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Desertification (n)",
    answer:
        "Sa mạc hóa",
    category: "Environment",
  ),
  QuizQuestion(
    question: "Ozone depletion (n)",
    answer:
        "Sự suy giảm tầng ozone",
    category: "Environment",
  ),
];
