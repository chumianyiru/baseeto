enum MessageType { text, image, sticker, file, transfer, redPacket, system }

class ChatMessage {
  String id;
  String chatId;
  String senderId;
  String senderName;
  String content;
  DateTime timestamp;
  bool isMe;
  MessageType type;
  String? extraData;
  bool isOpened;

  ChatMessage({
    required this.id, required this.chatId, required this.senderId,
    required this.senderName, required this.content, required this.timestamp,
    required this.isMe, this.type = MessageType.text, this.extraData,
    this.isOpened = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'chatId': chatId, 'senderId': senderId, 'senderName': senderName,
    'content': content, 'timestamp': timestamp.toIso8601String(),
    'isMe': isMe, 'type': type.index, 'extraData': extraData, 'isOpened': isOpened,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? '', chatId: j['chatId'] ?? '', senderId: j['senderId'] ?? '',
    senderName: j['senderName'] ?? '', content: j['content'] ?? '',
    timestamp: DateTime.parse(j['timestamp'] ?? DateTime.now().toIso8601String()),
    isMe: j['isMe'] ?? false, type: MessageType.values[j['type'] ?? 0],
    extraData: j['extraData'], isOpened: j['isOpened'] ?? false,
  );
}
