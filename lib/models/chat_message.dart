enum MessageType {
  text,
  image,
  file,
  transfer,
  redPacket,
  system,
  emoji,
}

class ChatMessage {
  String id;
  String chatId;
  String senderId;
  String senderName;
  String content;
  DateTime timestamp;
  MessageType type;
  bool isMe;
  String? filePath;
  double? amount;
  bool isOpened;
  String? avatarPath;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isMe = false,
    this.filePath,
    this.amount,
    this.isOpened = false,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
    'isMe': isMe,
    'filePath': filePath,
    'amount': amount,
    'isOpened': isOpened,
    'avatarPath': avatarPath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    chatId: json['chatId'] as String,
    senderId: json['senderId'] as String,
    senderName: json['senderName'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: MessageType.values[json['type'] as int? ?? 0],
    isMe: json['isMe'] as bool? ?? false,
    filePath: json['filePath'] as String?,
    amount: (json['amount'] as num?)?.toDouble(),
    isOpened: json['isOpened'] as bool? ?? false,
    avatarPath: json['avatarPath'] as String?,
  );
}
