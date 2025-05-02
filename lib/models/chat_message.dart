import 'package:flutter/material.dart';

enum MessageType { user, ai, loading, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create a copy with modified properties
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class WorkoutChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  WorkoutChatSession({
    required this.id,
    required this.messages,
    DateTime? createdAt,
    this.lastUpdated,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy with modified properties
  WorkoutChatSession copyWith({
    String? id,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return WorkoutChatSession(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Add a message to the session
  WorkoutChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      lastUpdated: DateTime.now(),
    );
  }
}

class WorkoutGenerationResponse {
  final String id;
  final String prompt;
  final Map<String, dynamic>? generatedWorkout;
  final String? errorMessage;
  final DateTime timestamp;
  final bool isSuccess;

  WorkoutGenerationResponse({
    required this.id,
    required this.prompt,
    this.generatedWorkout,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       isSuccess = errorMessage == null && generatedWorkout != null;

  // Convert the AI response to a Workout model-compatible format
  Map<String, dynamic> toWorkoutJson() {
    if (!isSuccess || generatedWorkout == null) {
      throw Exception('Cannot convert failed response to workout');
    }

    return {
      'name': generatedWorkout!['name'] ?? 'AI Generated Workout',
      'description':
          generatedWorkout!['description'] ?? 'Created with AI Assistant',
      'type': generatedWorkout!['type'] ?? 'Mixed',
      'image_url': generatedWorkout!['image_url'] ?? '',
      'duration': generatedWorkout!['duration'] ?? '30 min',
      'difficulty': generatedWorkout!['difficulty'] ?? 'intermediate',
      'calories_burned': generatedWorkout!['calories_burned'] ?? 300,
      'is_public': false,
      'exercises': generatedWorkout!['exercises'] ?? [],
    };
  }
}
