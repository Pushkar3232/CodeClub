# 🤖 Flutter AI Mentor Chatbot — Complete Implementation Guide

> Floating AI Icon → AI Mentor Screen → Live Chat with Hackathon AI
> API: `https://codeclub-api.vercel.app/api/hackathon`

---

## 📁 Files to Create / Modify

```
lib/
├── main.dart                          ← Add FloatingAIButton overlay
├── features/
│   └── ai_mentor/
│       ├── models/
│       │   └── chat_message.dart      ← Message model
│       ├── services/
│       │   └── hackathon_api.dart     ← API service
│       ├── widgets/
│       │   ├── chat_bubble.dart       ← Message bubble UI
│       │   ├── typing_indicator.dart  ← AI typing animation
│       │   └── floating_ai_button.dart ← Floating icon widget
│       └── screens/
│           └── ai_mentor_screen.dart  ← Main chat screen
└── core/
    └── theme/
        └── ai_mentor_theme.dart       ← Colors & styles
```

---

## 📦 Step 1 — Add Dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  flutter_markdown: ^0.6.22
  lottie: ^3.1.0
  shared_preferences: ^2.2.3
```

Then run:

```bash
flutter pub get
```

| Package | Purpose |
|---|---|
| `http` | API calls to Hackathon AI |
| `flutter_animate` | Smooth animations |
| `google_fonts` | Beautiful typography |
| `flutter_markdown` | Render AI markdown responses |
| `lottie` | AI loading animation |
| `shared_preferences` | Save chat history locally |

---

## 🎨 Step 2 — Theme & Colors

Create `lib/core/theme/ai_mentor_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AIMentorTheme {
  // Brand Colors
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color deepPurple = Color(0xFF4A44CC);
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color cardBg = Color(0xFF1A1A2E);
  static const Color cardBg2 = Color(0xFF16213E);
  static const Color userBubble = Color(0xFF6C63FF);
  static const Color aiBubble = Color(0xFF1E1E3A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C6);
  static const Color divider = Color(0xFF2A2A4A);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [darkBg, cardBg2],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Styles
  static TextStyle get headingStyle => GoogleFonts.spaceMono(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get messageStyle => GoogleFonts.inter(
    fontSize: 14,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle get subtitleStyle => GoogleFonts.inter(
    fontSize: 12,
    color: textSecondary,
  );

  // Floating Button Gradient
  static const List<Color> fabGradient = [primaryPurple, accentCyan];
}
```

---

## 💬 Step 3 — Chat Message Model

Create `lib/features/ai_mentor/models/chat_message.dart`:

```dart
enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  // Convert to/from JSON for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    content: json['content'],
    role: MessageRole.values.firstWhere((e) => e.name == json['role']),
    timestamp: DateTime.parse(json['timestamp']),
  );

  // Factory for user message
  factory ChatMessage.user(String content) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    content: content,
    role: MessageRole.user,
    timestamp: DateTime.now(),
  );

  // Factory for AI message
  factory ChatMessage.ai(String content) => ChatMessage(
    id: '${DateTime.now().millisecondsSinceEpoch}_ai',
    content: content,
    role: MessageRole.ai,
    timestamp: DateTime.now(),
  );

  // Factory for loading state
  factory ChatMessage.loading() => ChatMessage(
    id: 'loading',
    content: '',
    role: MessageRole.ai,
    timestamp: DateTime.now(),
    isLoading: true,
  );
}
```

---

## 🌐 Step 4 — Hackathon API Service

Create `lib/features/ai_mentor/services/hackathon_api.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class HackathonApiService {
  static const String _baseUrl = 'https://codeclub-api.vercel.app';
  static const String _endpoint = '/api/hackathon';

  /// Ask the Hackathon AI a question
  static Future<String> askQuestion(String question) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'question': question}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['answer'] != null) {
          return data['answer'] as String;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 400) {
        throw Exception('Please enter a valid question.');
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please wait a moment.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Unexpected error: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Something went wrong. Please try again.');
    }
  }

  /// Health check
  static Future<bool> isApiAlive() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_endpoint'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
```

---

## ✨ Step 5 — Typing Indicator Widget

Create `lib/features/ai_mentor/widgets/typing_indicator.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ai_mentor_theme.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AIMentorTheme.aiBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: AIMentorTheme.primaryPurple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // AI Avatar mini
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AIMentorTheme.accentCyan,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    delay: 0.ms,
                    duration: 600.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: 600.ms,
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AIMentorTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    delay: 200.ms,
                    duration: 600.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: 600.ms,
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AIMentorTheme.accentCyan,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    delay: 400.ms,
                    duration: 600.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: 600.ms,
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## 💬 Step 6 — Chat Bubble Widget

Create `lib/features/ai_mentor/widgets/chat_bubble.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../../../core/theme/ai_mentor_theme.dart';
import 'typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;

  const ChatBubble({
    super.key,
    required this.message,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAIAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.isLoading)
                  const TypingIndicator()
                else
                  _buildBubble(context, isUser),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: AIMentorTheme.subtitleStyle.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied to clipboard',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AIMentorTheme.primaryPurple,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AIMentorTheme.primaryPurple, AIMentorTheme.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : AIMentorTheme.aiBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AIMentorTheme.primaryPurple.withOpacity(0.25),
                ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AIMentorTheme.primaryPurple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                message.content,
                style: AIMentorTheme.messageStyle,
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: AIMentorTheme.messageStyle,
                  strong: AIMentorTheme.messageStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AIMentorTheme.accentCyan,
                  ),
                  code: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: AIMentorTheme.accentCyan,
                    backgroundColor: AIMentorTheme.darkBg,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AIMentorTheme.darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AIMentorTheme.primaryPurple.withOpacity(0.3),
                    ),
                  ),
                  listBullet: AIMentorTheme.messageStyle.copyWith(
                    color: AIMentorTheme.accentCyan,
                  ),
                  h1: AIMentorTheme.headingStyle.copyWith(fontSize: 18),
                  h2: AIMentorTheme.headingStyle.copyWith(fontSize: 16),
                  h3: AIMentorTheme.headingStyle.copyWith(fontSize: 14),
                ),
              ),
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AIMentorTheme.primaryPurple, AIMentorTheme.accentCyan],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AIMentorTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg,
        shape: BoxShape.circle,
        border: Border.all(color: AIMentorTheme.divider),
      ),
      child: const Icon(Icons.person, color: AIMentorTheme.textSecondary, size: 16),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
```

---

## 🚀 Step 7 — Floating AI Button Widget

Create `lib/features/ai_mentor/widgets/floating_ai_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ai_mentor_theme.dart';
import '../screens/ai_mentor_screen.dart';

class FloatingAIButton extends StatefulWidget {
  const FloatingAIButton({super.key});

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton> {
  bool _isExpanded = false;

  void _openAIMentor() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AIMentorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        Future.delayed(const Duration(milliseconds: 150), _openAIMentor);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isExpanded ? 140 : 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AIMentorTheme.fabGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AIMentorTheme.primaryPurple.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2000.ms, color: Colors.white54),
            if (_isExpanded) ...[
              const SizedBox(width: 8),
              const Text(
                'AI Mentor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}
```

---

## 📱 Step 8 — AI Mentor Main Screen

Create `lib/features/ai_mentor/screens/ai_mentor_screen.dart`:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/hackathon_api.dart';
import '../widgets/chat_bubble.dart';
import '../../../core/theme/ai_mentor_theme.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  State<AIMentorScreen> createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends State<AIMentorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Suggested starter questions
  final List<String> _suggestions = [
    '⚡ Best tech stack for a hackathon website?',
    '📱 Flutter vs React Native for hackathon?',
    '🏆 How to impress hackathon judges?',
    '⏰ How to build MVP in 24 hours?',
    '🔌 Best free APIs for hackathons?',
    '🗂️ How to structure hackathon project?',
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(ChatMessage.ai(
          "👋 Hey! I'm your **AI Hackathon Mentor**.\n\n"
          "I can help you with:\n"
          "- 🛠️ Tech stack recommendations\n"
          "- 🏗️ Project architecture\n"
          "- 🚀 MVP planning & execution\n"
          "- 🏆 Pitching to judges\n"
          "- ⏱️ Time management during hackathons\n\n"
          "Ask me anything about hackathons! 🎯",
        ));
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getStringList('ai_mentor_chat') ?? [];
      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages = savedMessages
              .map((s) => ChatMessage.fromJson(jsonDecode(s)))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _messages
          .where((m) => !m.isLoading)
          .map((m) => jsonEncode(m.toJson()))
          .toList();
      await prefs.setStringList('ai_mentor_chat', encoded);
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage.user(text.trim());
    final loadingMessage = ChatMessage.loading();

    setState(() {
      _messages.add(userMessage);
      _messages.add(loadingMessage);
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final answer = await HackathonApiService.askQuestion(text.trim());

      setState(() {
        _messages.remove(loadingMessage);
        _messages.add(ChatMessage.ai(answer));
        _isLoading = false;
      });

      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.remove(loadingMessage);
        _messages.add(ChatMessage.ai(
          '❌ **Oops!** ${e.toString().replaceAll('Exception: ', '')}\n\n'
          'Please check your connection and try again.',
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_mentor_chat');
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIMentorTheme.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AIMentorTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildChatList(),
              if (_messages.length <= 1) _buildSuggestions(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AIMentorTheme.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AIMentorTheme.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AIMentorTheme.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          // AI Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AIMentorTheme.primaryPurple, AIMentorTheme.accentCyan],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AIMentorTheme.primaryPurple.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2500.ms, color: AIMentorTheme.accentCyan.withOpacity(0.4)),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Hackathon Mentor', style: AIMentorTheme.headingStyle.copyWith(fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF88),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(begin: 0.4, end: 1.0, duration: 1000.ms),
                    const SizedBox(width: 5),
                    Text(
                      _isLoading ? 'Thinking...' : 'Online • Powered by Groq',
                      style: AIMentorTheme.subtitleStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clear chat
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AIMentorTheme.cardBg,
                title: Text('Clear Chat',
                    style: GoogleFonts.inter(color: Colors.white)),
                content: Text('This will delete all messages.',
                    style: GoogleFonts.inter(color: AIMentorTheme.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: AIMentorTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearChat();
                    },
                    child: Text('Clear',
                        style: GoogleFonts.inter(color: Colors.red)),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AIMentorTheme.divider),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AIMentorTheme.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  // ── Chat List ──────────────────────────────────────────────────────────────
  Widget _buildChatList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _messages.length,
        itemBuilder: (context, index) => ChatBubble(
          message: _messages[index],
          index: index,
        ),
      ),
    );
  }

  // ── Suggestion Chips ───────────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(
              _suggestions[index].replaceAll(RegExp(r'^[^\w]+'), '').trim(),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AIMentorTheme.primaryPurple.withOpacity(0.4),
                ),
              ),
              child: Text(
                _suggestions[index],
                style: GoogleFonts.inter(
                  color: AIMentorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: index * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.3, end: 0);
        },
      ),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: AIMentorTheme.cardBg.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: AIMentorTheme.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AIMentorTheme.cardBg2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AIMentorTheme.primaryPurple
                      : AIMentorTheme.divider,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AIMentorTheme.messageStyle,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _isLoading ? null : _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about hackathons...',
                        hintStyle: AIMentorTheme.subtitleStyle,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send Button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: AIMentorTheme.fabGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading ? AIMentorTheme.divider : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AIMentorTheme.primaryPurple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AIMentorTheme.primaryPurple,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
  }
}
```

---

## 🏠 Step 9 — Add Floating Button to Your Existing Screen

In any existing screen where you want the floating AI button, wrap the `Scaffold` body with a `Stack`:

```dart
import 'package:flutter/material.dart';
import 'features/ai_mentor/widgets/floating_ai_button.dart';

class YourExistingScreen extends StatelessWidget {
  const YourExistingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          // ── Your existing page content here ──
          YourExistingContent(),

          // ── Floating AI Mentor Button (bottom-right) ──
          Positioned(
            bottom: 24,
            right: 20,
            child: const FloatingAIButton(),
          ),
        ],
      ),
    );
  }
}
```

### If you have a `BottomNavigationBar`, adjust the bottom offset:

```dart
Positioned(
  bottom: 80,  // ← Raise it above the nav bar
  right: 20,
  child: const FloatingAIButton(),
),
```

---

## 🌐 Step 10 — Add Internet Permission

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Add this line -->
  <uses-permission android:name="android.permission.INTERNET"/>

  <application
    android:label="your_app"
    ...>
  </application>
</manifest>
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

---

## ✅ Final File Checklist

```
✅ pubspec.yaml            → http, flutter_animate, google_fonts, flutter_markdown
✅ ai_mentor_theme.dart    → Colors, gradients, text styles
✅ chat_message.dart       → Message model with JSON support
✅ hackathon_api.dart      → POST to /api/hackathon with error handling
✅ typing_indicator.dart   → Animated 3-dot bouncing indicator
✅ chat_bubble.dart        → User + AI bubbles with Markdown support
✅ floating_ai_button.dart → Animated floating icon with gradient
✅ ai_mentor_screen.dart   → Full chat screen with history
✅ YourScreen.dart         → Stack with FloatingAIButton positioned
✅ AndroidManifest.xml     → INTERNET permission
✅ Info.plist              → iOS network permission
```

---

## 🧪 Test These Scenarios

| Scenario | Expected Behavior |
|---|---|
| Tap floating AI button | Slides up to AI Mentor screen |
| Type a question & send | Loading dots → AI answer appears |
| Tap suggestion chip | Auto-sends that question |
| Long press a bubble | Copies text to clipboard |
| No internet | Shows friendly error message |
| Reopen app | Chat history restored |
| Tap clear icon | Confirms & clears history |
| Swipe down / back | Returns to previous screen |

---

## 🎯 Quick API Reference

```
POST https://codeclub-api.vercel.app/api/hackathon

Body:  { "question": "Your hackathon question" }

Response:
{
  "success": true,
  "question": "...",
  "answer": "AI response in markdown"
}
```

---

> Built with ❤️ — **Flutter · Groq AI · LangChain · Next.js**
