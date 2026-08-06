class Contact {
  String id;
  String name;
  String avatarPath;
  String systemPrompt;
  bool enableAI;
  bool isGroup;
  List<String> memberIds;
  int colorValue;
  String? soundPath;

  Contact({
    required this.id,
    required this.name,
    this.avatarPath = '',
    this.systemPrompt = '',
    this.enableAI = false,
    this.isGroup = false,
    this.memberIds = const [],
    this.colorValue = 0xFF2196F3,
    this.soundPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarPath': avatarPath,
    'systemPrompt': systemPrompt,
    'enableAI': enableAI,
    'isGroup': isGroup,
    'memberIds': memberIds,
    'colorValue': colorValue,
    'soundPath': soundPath,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarPath: json['avatarPath'] as String? ?? '',
    systemPrompt: json['systemPrompt'] as String? ?? '',
    enableAI: json['enableAI'] as bool? ?? false,
    isGroup: json['isGroup'] as bool? ?? false,
    memberIds: (json['memberIds'] as List<dynamic>?)?.cast<String>() ?? [],
    colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
    soundPath: json['soundPath'] as String?,
  );
}
