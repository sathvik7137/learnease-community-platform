import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/course.dart';
import 'quiz_screen.dart';
import '../utils/app_theme.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  final List<Animation<double>> _cardAnimations = [];
  bool _showScrollToTop = false;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Setup staggered animations for cards
    final sectionCount = 3 + (widget.topic.conceptSections?.length ?? 0) + 1;
    for (int i = 0; i < sectionCount; i++) {
      final start = i * 0.1;
      final end = start + 0.5;
      _cardAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );
    }
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    setState(() {
      _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      _showScrollToTop = currentScroll > 300;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5C6BC0);
    const accentColor = Color(0xFF7E57C2);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.white : Color(0xFF374151);
    final cardBgColor = isDark ? Color(0xFF2A2A3E) : Colors.white;
    final surfaceColor = isDark ? Color(0xFF1E1E2E) : Color(0xFFF9FAFB);
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
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
              widget.topic.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A2E) : Color(0xFFF9FAFB),
              gradient: isDark 
                ? LinearGradient(
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E).withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(
                    colors: [
                      Color(0xFFF9FAFB),
                      Colors.indigo.shade50.withOpacity(0.3),
                      Colors.purple.shade50.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            ),
          ),
          
          // Content
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explanation Section
                if (widget.topic.explanation.isNotEmpty)
                  _buildAnimatedCard(
                    0,
                    _buildSectionCard(
                      'Explanation',
                      Icons.description,
                      widget.topic.explanation,
                      context,
                      cardBgColor,
                      textColor,
                      isDark,
                    ),
                  ),

                // Concept Sections
                if (widget.topic.conceptSections != null)
                  ...widget.topic.conceptSections!.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final concept = entry.value;
                    return _buildAnimatedCard(
                      index,
                      _buildConceptCard(concept, context, cardBgColor, textColor, isDark),
                    );
                  }),

                // Revision Points
                _buildAnimatedCard(
                  _cardAnimations.length - 2,
                  _buildRevisionCard(widget.topic.revisionPoints, context, cardBgColor, textColor, isDark),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                _buildAnimatedCard(
                  _cardAnimations.length - 1,
                  _buildActionButtons(context),
                ),
              ],
            ),
          ),

          // Scroll to top button
          if (_showScrollToTop)
            Positioned(
              bottom: 140,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                color: colorScheme.primary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _scrollToTop,
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(14),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    final animation = index < _cardAnimations.length
        ? _cardAnimations[index]
        : const AlwaysStoppedAnimation(1.0);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, String content, BuildContext context, Color cardBgColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isDark ? 2 : 4,
        shadowColor: const Color(0xFF5C6BC0).withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardBgColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                ? [Color(0xFF2A2A3E), Color(0xFF3A3A52).withOpacity(0.5)]
                : [Colors.white, Colors.indigo.shade50.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: content,
                styleSheet: _buildMarkdownStyleSheet(context, cardBgColor, textColor, isDark),
                selectable: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConceptCard(dynamic concept, BuildContext context, Color cardBgColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isDark ? 2 : 4,
        shadowColor: const Color(0xFF7E57C2).withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardBgColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                ? [Color(0xFF2A2A3E), Color(0xFF3A3A52).withOpacity(0.5)]
                : [Colors.white, Colors.purple.shade50.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  concept.heading,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: concept.explanation,
                styleSheet: _buildMarkdownStyleSheet(context, cardBgColor, textColor, isDark),
              ),
              if (concept.codeSnippet.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.code, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Code Example',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E57C2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200, width: 1.5),
                  ),
                  child: Text(
                    concept.codeSnippet,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Color(0xFF7DD3FC),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevisionCard(List<String> points, BuildContext context, Color cardBgColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isDark ? 2 : 4,
        shadowColor: Colors.amber.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardBgColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                ? [Color(0xFF2A2A3E), Color(0xFF3A3A52).withOpacity(0.5)]
                : [Colors.white, Colors.amber.shade50.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade600, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stars, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Key Points to Remember',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...points.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF3A3A52) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.amber.shade900 : Colors.amber.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context, Color cardBgColor, Color textColor, bool isDark) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: isDark ? Colors.white70 : Color(0xFF374151),
      ),
      h1: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Color(0xFF1A237E),
      ),
      h2: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Color(0xFF5C6BC0),
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Color(0xFF374151),
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Color(0xFF1A237E),
      ),
      listBullet: TextStyle(
        fontSize: 18,
        color: isDark ? Colors.white : Color(0xFF5C6BC0),
      ),
      code: TextStyle(
        backgroundColor: isDark ? Color(0xFF2A2A3E) : Colors.indigo.shade50,
        color: isDark ? Color(0xFF7DD3FC) : Color(0xFF1A237E),
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E2E) : Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.purple.shade200 : Colors.indigo.shade100,
          width: 1.5,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C6BC0).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(topic: widget.topic),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.quiz, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Take Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
