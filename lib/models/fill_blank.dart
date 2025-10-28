// import 'package:flutter/material.dart';

class FillBlankQuestion {
  final String id;
  final String statement; // The sentence with a blank (represented as '_____')
  final String answer;
  final String topicId; // To associate with a specific topic
  final String? hint;
  
  FillBlankQuestion({
    required this.id,
    required this.statement,
    required this.answer,
    required this.topicId,
    this.hint,
  });
}

// Model for the user's answer to a fill-in-the-blanks question
class FillBlankResponse {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;
  
  FillBlankResponse({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });
}
