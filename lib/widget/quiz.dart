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
    question: "Natural disaster",
    answer:
        "Thảm họa thiên nhiên",
    category: "dart",
  ),
  QuizQuestion(
    question: "Greenhouse effect",
    answer:
        "Hiệu ứng nhà kính",
    category: "dart",
  ),
  QuizQuestion(
    question: "Rising sea levels",
    answer:
        "Mực nước biển dâng",
    category: "dart",
  ),
  QuizQuestion(
    question: "Habitat loss",
    answer:
        "Mất môi trường sống",
    category: "dart",
  ),

  // Golang Questions
  QuizQuestion(
    question: "Climate change",
    answer:
        "Biến đổi khí hậu",
    category: "golang",
  ),
  QuizQuestion(
    question: "Global warming",
    answer:
        "Sự nóng lên toàn cầu",
    category: "golang",
  ),
  QuizQuestion(
    question: "Air pollution",
    answer:
        "Ô nhiễm không khí",
    category: "golang",
  ),
  QuizQuestion(
    question: "Water contamination",
    answer:
        "Ô nhiễm nguồn nước",
    category: "golang",
  ),
  QuizQuestion(
    question: "Deforestation",
    answer:
        "Nạn phá rừng",
    category: "golang",
  ),
  QuizQuestion(
    question: "Overfishing",
    answer:
        "Đánh bắt cá quá mức",
    category: "golang",
  ),
  QuizQuestion(
    question: "Desertification",
    answer:
        "Sa mạc hóa",
    category: "golang",
  ),
  QuizQuestion(
    question: "Ozone depletion",
    answer:
        "Sự suy giảm tầng ozone",
    category: "golang",
  ),
];
