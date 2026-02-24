class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType
  });

  Map<String, dynamic> toJson(){
    return {
      'id' : id,
      'text' : text,
      'isUser' : isUser,
      'timestamp' : timestamp.millisecondsSinceEpoch,
      'messageType' : messageType
    };
  }

  factory Message.fromJson(Map<String, dynamic> json){
    return Message(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      messageType: json['messageType']
    );
  }
}