class StoryCharacter {
  String id;
  String name;
  String avatarPath;
  int colorValue;

  StoryCharacter({
    required this.id, required this.name,
    this.avatarPath = '', this.colorValue = 0xFF60A5FA,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'avatarPath': avatarPath, 'colorValue': colorValue,
  };

  factory StoryCharacter.fromJson(Map<String, dynamic> j) => StoryCharacter(
    id: j['id'] ?? '', name: j['name'] ?? '', avatarPath: j['avatarPath'] ?? '',
    colorValue: j['colorValue'] ?? 0xFF60A5FA,
  );
}

class StoryChoice {
  String text;
  String targetNodeId;

  StoryChoice({required this.text, required this.targetNodeId});

  Map<String, dynamic> toJson() => {'text': text, 'targetNodeId': targetNodeId};

  factory StoryChoice.fromJson(Map<String, dynamic> j) => StoryChoice(
    text: j['text'] ?? '', targetNodeId: j['targetNodeId'] ?? '',
  );
}

class StoryNode {
  String id;
  String characterId;
  String text;
  String? backgroundPath;
  List<StoryChoice> choices;
  String? nextNodeId;
  bool isEnding;
  String? endingTitle;

  StoryNode({
    required this.id, required this.characterId, required this.text,
    this.backgroundPath, this.choices = const [], this.nextNodeId,
    this.isEnding = false, this.endingTitle,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'characterId': characterId, 'text': text,
    'backgroundPath': backgroundPath,
    'choices': choices.map((c) => c.toJson()).toList(),
    'nextNodeId': nextNodeId, 'isEnding': isEnding, 'endingTitle': endingTitle,
  };

  factory StoryNode.fromJson(Map<String, dynamic> j) => StoryNode(
    id: j['id'] ?? '', characterId: j['characterId'] ?? '', text: j['text'] ?? '',
    backgroundPath: j['backgroundPath'],
    choices: (j['choices'] as List? ?? []).map((c) => StoryChoice.fromJson(c)).toList(),
    nextNodeId: j['nextNodeId'], isEnding: j['isEnding'] ?? false,
    endingTitle: j['endingTitle'],
  );
}

class Story {
  String id;
  String title;
  String description;
  String coverPath;
  String startNodeId;
  List<StoryCharacter> characters;
  List<StoryNode> nodes;
  DateTime createdAt;

  Story({
    required this.id, required this.title, this.description = '',
    this.coverPath = '', required this.startNodeId,
    this.characters = const [], this.nodes = const [], required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'coverPath': coverPath,
    'startNodeId': startNodeId,
    'characters': characters.map((c) => c.toJson()).toList(),
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Story.fromJson(Map<String, dynamic> j) => Story(
    id: j['id'] ?? '', title: j['title'] ?? '', description: j['description'] ?? '',
    coverPath: j['coverPath'] ?? '', startNodeId: j['startNodeId'] ?? '',
    characters: (j['characters'] as List? ?? []).map((c) => StoryCharacter.fromJson(c)).toList(),
    nodes: (j['nodes'] as List? ?? []).map((n) => StoryNode.fromJson(n)).toList(),
    createdAt: DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}
