import 'package:flutter/material.dart';
import '../models/course.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Topic topic;
  final bool isMockTest;

  const QuizScreen({
    Key? key,
    required this.topic,
    this.isMockTest = false,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  late AnimationController _transitionController;
  late AnimationController _selectController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int? _lastSelectedIndex;
  
  @override
  void initState() {
    super.initState();
    // Initialize selected answers list with nulls
    selectedAnswers = List<int?>.filled(widget.topic.quizQuestions.length, null);
    
    // Page transition animation
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeIn),
    );
    
    // Selection animation
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;
      _lastSelectedIndex = answerIndex;
    });
    _selectController.forward(from: 0.0);
  }

  bool get isLastQuestion => currentQuestionIndex == widget.topic.quizQuestions.length - 1;

  void _nextQuestion() {
    if (isLastQuestion) {
      // Calculate score and navigate to results
      _showResults();
    } else {
      setState(() {
        currentQuestionIndex++;
        _transitionController.forward(from: 0.0);
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        _transitionController.forward(from: 0.0);
      });
    }
  }

  void _showResults() {
    int score = 0;
    for (int i = 0; i < widget.topic.quizQuestions.length; i++) {
      if (selectedAnswers[i] == widget.topic.quizQuestions[i].correctIndex) {
        score++;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: score,
          totalQuestions: widget.topic.quizQuestions.length,
          topic: widget.topic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.topic.quizQuestions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / widget.topic.quizQuestions.length;
    final answeredCount = selectedAnswers.where((a) => a != null).length;
    const primaryColor = Color(0xFF5C6BC0);
    const accentColor = Color(0xFF7E57C2);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            title: Text(
              widget.isMockTest ? 'Mock Test' : 'Quiz: ${widget.topic.title}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              // Streak indicator
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🎯',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$answeredCount/${widget.topic.quizQuestions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.amber.shade400,
                      Colors.white.withOpacity(0.3),
                    ],
                    stops: [0.0, progress, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50.withOpacity(0.3),
              Colors.blue.shade50.withOpacity(0.3),
              Colors.indigo.shade50.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.15), accentColor.withOpacity(0.15)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Question ${currentQuestionIndex + 1} of ${widget.topic.quizQuestions.length}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Question Card with animation
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question text
                              Text(
                                question.question,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              
                              // Options
                              Expanded(
                                child: ListView.builder(
                                  itemCount: question.options.length,
                                  itemBuilder: (context, index) {
                                    final isSelected = selectedAnswers[currentQuestionIndex] == index;
                                    final isLastSelected = _lastSelectedIndex == index;
                                    
                                    return AnimatedBuilder(
                                      animation: _selectController,
                                      builder: (context, child) {
                                        final scale = isLastSelected && _selectController.isAnimating
                                            ? 1.0 - (_selectController.value * 0.05)
                                            : 1.0;
                                        
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 14.0),
                                        child: Material(
                                          elevation: isSelected ? 4 : 1,
                                          shadowColor: isSelected ? primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          child: InkWell(
                                            onTap: () => _selectAnswer(index),
                                            borderRadius: BorderRadius.circular(16),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeOutCubic,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? LinearGradient(
                                                        colors: [
                                                          primaryColor.withOpacity(0.15),
                                                          accentColor.withOpacity(0.1),
                                                        ],
                                                      )
                                                    : null,
                                                border: Border.all(
                                                  color: isSelected ? primaryColor : Colors.grey.shade300,
                                                  width: isSelected ? 2.5 : 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                color: isSelected ? null : Colors.white,
                                              ),
                                              child: Row(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 300),
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [primaryColor, accentColor],
                                                            )
                                                          : null,
                                                      border: Border.all(
                                                        color: isSelected ? Colors.transparent : Colors.grey.shade400,
                                                        width: 2,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: primaryColor.withOpacity(0.4),
                                                                blurRadius: 8,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: isSelected
                                                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Text(
                                                      question.options[index],
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                        color: isSelected ? primaryColor : const Color(0xFF374151),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: primaryColor.withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.done,
                                                        size: 16,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (currentQuestionIndex > 0)
                      Material(
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _previousQuestion,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_back, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                      
                    // Next/Finish button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        borderRadius: BorderRadius.circular(14),
                        elevation: selectedAnswers[currentQuestionIndex] != null ? 6 : 0,
                        shadowColor: primaryColor.withOpacity(0.4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: selectedAnswers[currentQuestionIndex] != null ? _nextQuestion : null,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: selectedAnswers[currentQuestionIndex] != null
                                  ? const LinearGradient(
                                      colors: [primaryColor, accentColor],
                                    )
                                  : null,
                              color: selectedAnswers[currentQuestionIndex] == null ? Colors.grey.shade300 : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              child: Row(
                                children: [
                                  Text(
                                    isLastQuestion ? 'Finish' : 'Next',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: selectedAnswers[currentQuestionIndex] != null
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                                    size: 20,
                                    color: selectedAnswers[currentQuestionIndex] != null
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
