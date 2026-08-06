class StoryCharacter {
  String id;
  String name;
  String imagePath;
  int colorValue;

  StoryCharacter({
    required this.id,
    required this.name,
    this.imagePath = '',
    this.colorValue = 0xFF2196F3,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'colorValue': colorValue,
  };

  factory StoryCharacter.fromJson(Map<String, dynamic> json) => StoryCharacter(
    id: json['id'] as String,
    name: json['name'] as String,
    imagePath: json['imagePath'] as String? ?? '',
    colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
  );
}

class StoryChoice {
  String text;
  String nextNodeId;

  StoryChoice({
    required this.text,
    required this.nextNodeId,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'nextNodeId': nextNodeId,
  };

  factory StoryChoice.fromJson(Map<String, dynamic> json) => StoryChoice(
    text: json['text'] as String,
    nextNodeId: json['nextNodeId'] as String,
  );
}

class StoryDialogue {
  String id;
  String characterId;
  String characterName;
  String text;
  String? backgroundPath;
  bool isChoice;
  List<StoryChoice> choices;
  String? nextNodeId;

  StoryDialogue({
    required this.id,
    required this.characterId,
    required this.characterName,
    required this.text,
    this.backgroundPath,
    this.isChoice = false,
    this.choices = const [],
    this.nextNodeId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'characterId': characterId,
    'characterName': characterName,
    'text': text,
    'backgroundPath': backgroundPath,
    'isChoice': isChoice,
    'choices': choices.map((e) => e.toJson()).toList(),
    'nextNodeId': nextNodeId,
  };

  factory StoryDialogue.fromJson(Map<String, dynamic> json) => StoryDialogue(
    id: json['id'] as String,
    characterId: json['characterId'] as String,
    characterName: json['characterName'] as String,
    text: json['text'] as String,
    backgroundPath: json['backgroundPath'] as String?,
    isChoice: json['isChoice'] as bool? ?? false,
    choices: (json['choices'] as List<dynamic>?)
        ?.map((e) => StoryChoice.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    nextNodeId: json['nextNodeId'] as String?,
  );
}

class Story {
  String id;
  String title;
  String description;
  List<StoryCharacter> characters;
  List<StoryDialogue> dialogues;
  String? coverPath;
  DateTime createdAt;
  String startNodeId;

  Story({
    required this.id,
    required this.title,
    this.description = '',
    this.characters = const [],
    this.dialogues = const [],
    this.coverPath,
    required this.createdAt,
    required this.startNodeId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'characters': characters.map((e) => e.toJson()).toList(),
    'dialogues': dialogues.map((e) => e.toJson()).toList(),
    'coverPath': coverPath,
    'createdAt': createdAt.toIso8601String(),
    'startNodeId': startNodeId,
  };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    characters: (json['characters'] as List<dynamic>?)
        ?.map((e) => StoryCharacter.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    dialogues: (json['dialogues'] as List<dynamic>?)
        ?.map((e) => StoryDialogue.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    coverPath: json['coverPath'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    startNodeId: json['startNodeId'] as String,
  );
}
