class Contact {
  String id;
  String name;
  String avatarPath;
  String systemPrompt;
  bool aiEnabled;
  bool isGroup;
  List<String> memberIds;
  int colorValue;

  Contact({
    required this.id,
    required this.name,
    this.avatarPath = '',
    this.systemPrompt = '你是一个友好的聊天伙伴。',
    this.aiEnabled = true,
    this.isGroup = false,
    this.memberIds = const [],
    this.colorValue = 0xFF3B82F6,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'avatarPath': avatarPath,
    'systemPrompt': systemPrompt, 'aiEnabled': aiEnabled,
    'isGroup': isGroup, 'memberIds': memberIds, 'colorValue': colorValue,
  };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: j['id'] ?? '', name: j['name'] ?? '', avatarPath: j['avatarPath'] ?? '',
    systemPrompt: j['systemPrompt'] ?? '你是一个友好的聊天伙伴。',
    aiEnabled: j['aiEnabled'] ?? true, isGroup: j['isGroup'] ?? false,
    memberIds: List<String>.from(j['memberIds'] ?? []),
    colorValue: j['colorValue'] ?? 0xFF3B82F6,
  );
}
