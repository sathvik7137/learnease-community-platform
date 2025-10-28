import 'package:flutter/material.dart';
import '../models/fill_blank.dart';
import '../services/local_storage.dart';

class FillBlankExerciseScreen extends StatefulWidget {
  final String topicName;
  final List<FillBlankQuestion> questions;

  const FillBlankExerciseScreen({
    Key? key,
    required this.topicName,
    required this.questions,
  }) : super(key: key);

  @override
  State<FillBlankExerciseScreen> createState() => _FillBlankExerciseScreenState();
}

class _FillBlankExerciseScreenState extends State<FillBlankExerciseScreen> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  List<TextEditingController> controllers = [];
  List<String> userAnswers = [];
  List<bool?> answeredCorrectly = []; // null = not checked, true = correct, false = wrong
  late AnimationController _transitionController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and answers for each question
    controllers = List.generate(
      widget.questions.length,
      (index) => TextEditingController(),
    );
    userAnswers = List.filled(widget.questions.length, '');
    answeredCorrectly = List.filled(widget.questions.length, null);
    
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
    
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get isLastQuestion => currentQuestionIndex == widget.questions.length - 1;

  void _checkAnswer() {
    final userAnswer = controllers[currentQuestionIndex].text.trim().toLowerCase();
    final correctAnswer = widget.questions[currentQuestionIndex].answer.trim().toLowerCase();
    
    setState(() {
      userAnswers[currentQuestionIndex] = controllers[currentQuestionIndex].text.trim();
      answeredCorrectly[currentQuestionIndex] = (userAnswer == correctAnswer);
    });
  }

  void _nextQuestion() {
    // Only proceed if answer has been checked
    if (answeredCorrectly[currentQuestionIndex] == null) {
      return;
    }
    
    // Save current answer
    userAnswers[currentQuestionIndex] = controllers[currentQuestionIndex].text.trim();
    
    if (isLastQuestion) {
      // Calculate score and finish
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
      // Save current answer
      userAnswers[currentQuestionIndex] = controllers[currentQuestionIndex].text.trim();
      
      setState(() {
        currentQuestionIndex--;
        _transitionController.forward(from: 0.0);
      });
    }
  }

  void _showResults() {
    // Save current answer if not already checked
    if (answeredCorrectly[currentQuestionIndex] == null) {
      userAnswers[currentQuestionIndex] = controllers[currentQuestionIndex].text.trim();
      final userAnswer = userAnswers[currentQuestionIndex].toLowerCase().trim();
      final correctAnswer = widget.questions[currentQuestionIndex].answer.toLowerCase().trim();
      answeredCorrectly[currentQuestionIndex] = (userAnswer == correctAnswer);
    }
    
    // Calculate score from answeredCorrectly list
    int correctCount = answeredCorrectly.where((result) => result == true).length;
    
    // Calculate percentage
    final percentage = ((correctCount / widget.questions.length) * 100).round();
    
    // Save score
    LocalStorageService.saveExerciseScore(widget.topicName, 'fill-blanks', percentage);
    
    // Show results dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              percentage >= 70 ? Icons.celebration : Icons.info_outline,
              color: percentage >= 70 ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Exercise Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctCount / ${widget.questions.length}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C6BC0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              percentage >= 70
                  ? 'Great job! You\'ve mastered this topic!'
                  : 'Keep practicing to improve your score!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from Fill Blanks screen
              Navigator.of(context).pop(); // Go back from Quiz Results screen (if came from there)
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Reset and restart
              setState(() {
                currentQuestionIndex = 0;
                userAnswers = List.filled(widget.questions.length, '');
                answeredCorrectly = List.filled(widget.questions.length, null);
                for (var controller in controllers) {
                  controller.clear();
                }
                _transitionController.forward(from: 0.0);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BC0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / widget.questions.length;
    final answeredCount = userAnswers.where((a) => a.isNotEmpty).length;
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
              'Fill in the Blanks: ${widget.topicName.replaceFirst(RegExp(r'^\d+\.\s*'), '')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              // Progress indicator
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
                        '📝',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$answeredCount/${widget.questions.length}',
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
                      Colors.green.shade400,
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
                      Icon(Icons.edit_note, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Question ${currentQuestionIndex + 1} of ${widget.questions.length}',
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
                              colors: [Colors.white, Colors.green.shade50.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Statement with blank
                                Text(
                                  question.statement,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A237E),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                
                                // Answer input field
                                const Text(
                                  'Your Answer:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controllers[currentQuestionIndex],
                                  onChanged: (value) {
                                    setState(() {
                                      userAnswers[currentQuestionIndex] = value.trim();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer here...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: primaryColor, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textCapitalization: TextCapitalization.none,
                                  autocorrect: false,
                                  enabled: answeredCorrectly[currentQuestionIndex] == null,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Check Answer and Reveal Answer Buttons
                                if (answeredCorrectly[currentQuestionIndex] == null)
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: controllers[currentQuestionIndex].text.trim().isNotEmpty
                                              ? _checkAnswer
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF5C6BC0),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: const Text(
                                            'Check Answer',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            // Show the correct answer
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                title: Row(
                                                  children: [
                                                    Icon(Icons.visibility, color: Colors.blue.shade600, size: 28),
                                                    const SizedBox(width: 12),
                                                    const Text('Correct Answer'),
                                                  ],
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      question.statement,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade50,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: Colors.green.shade300,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              question.answer,
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green.shade800,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.visibility_outlined, size: 18),
                                          label: const Text(
                                            'Reveal Answer',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue.shade700,
                                            side: BorderSide(color: Colors.blue.shade300, width: 2),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                // Feedback after checking
                                if (answeredCorrectly[currentQuestionIndex] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: answeredCorrectly[currentQuestionIndex]!
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: answeredCorrectly[currentQuestionIndex]!
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          answeredCorrectly[currentQuestionIndex]!
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: answeredCorrectly[currentQuestionIndex]!
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                answeredCorrectly[currentQuestionIndex]!
                                                    ? 'Correct! Well done! 🎉'
                                                    : 'Incorrect',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: answeredCorrectly[currentQuestionIndex]!
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                              if (!answeredCorrectly[currentQuestionIndex]!) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Correct answer: ${widget.questions[currentQuestionIndex].answer}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Hint (if available)
                                if (question.hint != null && answeredCorrectly[currentQuestionIndex] == null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.shade300, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Hint: ${question.hint}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.amber.shade900,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                      
                    // Next/Finish button (only show if answer has been checked)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        borderRadius: BorderRadius.circular(14),
                        elevation: answeredCorrectly[currentQuestionIndex] != null ? 6 : 0,
                        shadowColor: primaryColor.withOpacity(0.4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: answeredCorrectly[currentQuestionIndex] != null
                              ? _nextQuestion
                              : null,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: answeredCorrectly[currentQuestionIndex] != null
                                  ? const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                    )
                                  : null,
                              color: answeredCorrectly[currentQuestionIndex] == null
                                  ? Colors.grey.shade300
                                  : null,
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
                                      color: answeredCorrectly[currentQuestionIndex] != null
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                                    size: 20,
                                    color: answeredCorrectly[currentQuestionIndex] != null
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
