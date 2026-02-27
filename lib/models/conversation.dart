import 'messages.dart';

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<Message> messages;
  final Map<String, dynamic> userContext;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
    required this.messages,
    required this.userContext,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'messages': messages.map((m) => m.toJson()).toList(),
      'userContext': userContext,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
      userContext: Map<String, dynamic>.from(json['userContext'] ?? {}),
    );
  }

  Conversation copyWith({
    String? title,
    DateTime? lastUpdated,
    List<Message>? messages,
    Map<String, dynamic>? userContext,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messages: messages ?? this.messages,
      userContext: userContext ?? this.userContext,
    );
  }
}