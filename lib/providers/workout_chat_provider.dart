import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/workout.dart';
import '../services/ai_workout_service.dart';

class WorkoutChatProvider with ChangeNotifier {
  WorkoutChatSession _currentSession;
  bool _isGenerating = false;
  WorkoutGenerationResponse? _lastResponse;
  bool _hasWorkoutReady = false;

  WorkoutChatProvider()
    : _currentSession = WorkoutChatSession(
        id: const Uuid().v4(),
        messages: [
          ChatMessage(
            id: const Uuid().v4(),
            content:
                'Hi! I\'m your AI fitness coach. I can help create personalized workout plans or answer questions about fitness and health. What can I help you with today?',
            type: MessageType.ai,
          ),
        ],
      );

  WorkoutChatSession get currentSession => _currentSession;
  bool get isGenerating => _isGenerating;
  WorkoutGenerationResponse? get lastResponse => _lastResponse;
  bool get hasWorkoutReady => _hasWorkoutReady;

  // Add a user message and generate a response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      type: MessageType.user,
    );

    _currentSession = _currentSession.addMessage(userMessage);

    // Add loading message
    final loadingMessageId = const Uuid().v4();
    final loadingMessage = ChatMessage(
      id: loadingMessageId,
      content: 'Thinking...',
      type: MessageType.loading,
    );

    _currentSession = _currentSession.addMessage(loadingMessage);
    _isGenerating = true;
    notifyListeners();

    try {
      // Determine if this is likely a workout request
      final isWorkoutRequest = AIWorkoutService.isWorkoutRequest(content);

      if (isWorkoutRequest) {
        // Generate workout with AI
        final response = await AIWorkoutService.generateWorkout(content);
        _lastResponse = response;
        _hasWorkoutReady = response.isSuccess;

        // Replace loading message with AI response
        final messages =
            _currentSession.messages.map((message) {
              if (message.id == loadingMessageId) {
                if (response.isSuccess) {
                  return ChatMessage(
                    id: const Uuid().v4(),
                    content: _formatAIResponse(response),
                    type: MessageType.ai,
                  );
                } else {
                  return ChatMessage(
                    id: const Uuid().v4(),
                    content:
                        'Sorry, I had trouble creating that workout plan. ${response.errorMessage}',
                    type: MessageType.error,
                  );
                }
              }
              return message;
            }).toList();

        _currentSession = _currentSession.copyWith(messages: messages);
      } else {
        // Handle regular conversation
        final conversationResponse =
            await AIWorkoutService.generateConversation(content);
        _hasWorkoutReady = false;
        _lastResponse = null;

        // Replace loading message with conversation response
        final messages =
            _currentSession.messages.map((message) {
              if (message.id == loadingMessageId) {
                return ChatMessage(
                  id: const Uuid().v4(),
                  content: conversationResponse,
                  type: MessageType.ai,
                );
              }
              return message;
            }).toList();

        _currentSession = _currentSession.copyWith(messages: messages);
      }
    } catch (e) {
      // Handle errors
      final messages =
          _currentSession.messages.map((message) {
            if (message.id == loadingMessageId) {
              return ChatMessage(
                id: const Uuid().v4(),
                content: 'Something went wrong. Please try again.',
                type: MessageType.error,
              );
            }
            return message;
          }).toList();

      _currentSession = _currentSession.copyWith(messages: messages);
      _hasWorkoutReady = false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Format AI response for display in chat
  String _formatAIResponse(WorkoutGenerationResponse response) {
    if (!response.isSuccess || response.generatedWorkout == null) {
      return 'Sorry, I couldn\'t create a workout plan based on your request.';
    }

    final workout = response.generatedWorkout!;
    final exercises = workout['exercises'] as List;

    // Create a formatted message with workout details
    final buffer = StringBuffer();
    buffer.writeln('# ${workout['name']}');
    buffer.writeln('');
    buffer.writeln('${workout['description']}');
    buffer.writeln('');
    buffer.writeln('**Type:** ${workout['type']}');
    buffer.writeln('**Difficulty:** ${workout['difficulty']}');
    buffer.writeln('**Est. Calories:** ${workout['calories_burned']}');
    buffer.writeln('');
    buffer.writeln('## Exercises:');
    buffer.writeln('');

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      buffer.writeln('### ${i + 1}. ${exercise['name']}');
      buffer.writeln('');
      buffer.writeln('${exercise['description']}');
      buffer.writeln('');
      buffer.writeln('- **Sets:** ${exercise['sets']}');
      buffer.writeln('- **Reps:** ${exercise['reps']}');

      final muscles = List<String>.from(exercise['target_muscles']);
      buffer.writeln('- **Target Muscles:** ${muscles.join(', ')}');
      buffer.writeln('');
    }

    buffer.writeln('');
    buffer.writeln(
      'Would you like to save this workout to your collection or make any changes to it?',
    );

    return buffer.toString();
  }

  // Start a new chat session
  void startNewSession() {
    _currentSession = WorkoutChatSession(
      id: const Uuid().v4(),
      messages: [
        ChatMessage(
          id: const Uuid().v4(),
          content:
              'Hi! I\'m your AI fitness coach. I can help create personalized workout plans or answer questions about fitness and health. What can I help you with today?',
          type: MessageType.ai,
        ),
      ],
    );
    _lastResponse = null;
    _hasWorkoutReady = false;
    notifyListeners();
  }

  // Save the last generated workout to the user's collection
  Future<Workout?> saveLastGeneratedWorkout() async {
    if (_lastResponse == null || !_lastResponse!.isSuccess) {
      return null;
    }

    final workout = await AIWorkoutService.saveGeneratedWorkout(_lastResponse!);

    if (workout != null) {
      // Add a message about the saved workout
      final saveMessage = ChatMessage(
        id: const Uuid().v4(),
        content:
            'Great! I\'ve saved "${workout.name}" to your workouts collection.',
        type: MessageType.ai,
      );

      _currentSession = _currentSession.addMessage(saveMessage);
      _hasWorkoutReady = false;
      notifyListeners();
    }

    return workout;
  }
}
