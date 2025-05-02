import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/workout.dart';
import '../providers/workout_chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import 'workout_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AIWorkoutChatScreen extends StatefulWidget {
  const AIWorkoutChatScreen({Key? key}) : super(key: key);

  @override
  State<AIWorkoutChatScreen> createState() => _AIWorkoutChatScreenState();
}

class _AIWorkoutChatScreenState extends State<AIWorkoutChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Get appropriate colors based on theme
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackgroundColor =
        isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
    final textPrimaryColor =
        isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondaryColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkCardBackground : backgroundColor,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        title: Row(
          children: [
            const SizedBox(width: 8),
            Image.asset(
              'assets/images/brands/trainova_v3.png',
              width: 38,
              height: 38,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                    size: 28,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Fitness Coach',
              style: TextStyle(
                color: textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimaryColor),
            tooltip: 'New conversation',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Start New Chat'),
                      content: const Text(
                        'Are you sure you want to start a new chat? Your current conversation will be lost.',
                      ),
                      backgroundColor: cardBackgroundColor,
                      titleTextStyle: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      contentTextStyle: TextStyle(color: textPrimaryColor),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<WorkoutChatProvider>(
                              context,
                              listen: false,
                            ).startNewSession();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Start New',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/workout1.png'),
                  opacity: 0.05,
                  fit: BoxFit.cover,
                ),
              ),
              child: Consumer<WorkoutChatProvider>(
                builder: (context, chatProvider, _) {
                  final messages = chatProvider.currentSession.messages;
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(
                        message,
                        isDarkMode,
                        textPrimaryColor,
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Input field and buttons - with a different background
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.darkCardBackground.withOpacity(0.8)
                      : cardBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Consumer<WorkoutChatProvider>(
              builder: (context, chatProvider, _) {
                final hasGeneratedWorkout = chatProvider.hasWorkoutReady;

                return Column(
                  children: [
                    // Save workout button if available
                    if (hasGeneratedWorkout)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Save Workout to Collection',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed:
                                chatProvider.isGenerating
                                    ? null
                                    : () async {
                                      final workout =
                                          await chatProvider
                                              .saveLastGeneratedWorkout();
                                      if (workout != null && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${workout.name} saved to your workouts!',
                                            ),
                                            backgroundColor: AppColors.primary,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(12),
                                            action: SnackBarAction(
                                              label: 'View',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            WorkoutDetailsScreen(
                                                              workout: workout,
                                                            ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                          ),
                        ),
                      ),

                    // Message input field and send button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Ask me about fitness or workouts...',
                                hintStyle: TextStyle(
                                  color: textSecondaryColor,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? AppColors.darkBackground
                                        : Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.chat_outlined,
                                  color: AppColors.primary.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                              style: TextStyle(color: textPrimaryColor),
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              enabled: !chatProvider.isGenerating,
                              onSubmitted:
                                  chatProvider.isGenerating
                                      ? null
                                      : (value) {
                                        if (value.trim().isNotEmpty) {
                                          chatProvider.sendMessage(value);
                                          _messageController.clear();
                                        }
                                      },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  chatProvider.isGenerating
                                      ? Colors.grey
                                      : AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap:
                                    chatProvider.isGenerating
                                        ? null
                                        : () {
                                          final message =
                                              _messageController.text;
                                          if (message.trim().isNotEmpty) {
                                            chatProvider.sendMessage(message);
                                            _messageController.clear();
                                          }
                                        },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    chatProvider.isGenerating
                                        ? Icons.hourglass_top
                                        : Icons.send,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isDarkMode,
    Color textColor,
  ) {
    final isAI = message.type == MessageType.ai;
    final isLoading = message.type == MessageType.loading;
    final isError = message.type == MessageType.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isAI || isLoading || isError
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI || isLoading || isError)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 18,
              ),
            ),

          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isAI ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color:
                    isError
                        ? Colors.red[100]
                        : isAI || isLoading
                        ? (isDarkMode
                            ? AppColors.primary.withOpacity(0.2)
                            : Color(0xFFEBEAFF))
                        : (isDarkMode
                            ? AppColors.darkCardBackground
                            : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child:
                  isLoading
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            message.content,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      )
                      : isAI
                      ? MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                          h2: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                          h3: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                          p: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextPrimary,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                          a: TextStyle(color: AppColors.primary),
                          blockquote: TextStyle(
                            fontStyle: FontStyle.italic,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                          listBullet: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                      )
                      : Text(
                        message.content,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                        ),
                      ),
            ),
          ),

          if (!isAI && !isLoading && !isError)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
