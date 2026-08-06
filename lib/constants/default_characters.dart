import '../models/story.dart';

class DefaultCharacters {
  static List<StoryCharacter> get baCharacters => [
        StoryCharacter(
          id: 'ba_001',
          name: '星野',
          colorValue: 0xFF60A5FA,
        ),
        StoryCharacter(
          id: 'ba_002',
          name: '白子',
          colorValue: 0xFFF472B6,
        ),
        StoryCharacter(
          id: 'ba_003',
          name: '野乃美',
          colorValue: 0xFF34D399,
        ),
        StoryCharacter(
          id: 'ba_004',
          name: '茜',
          colorValue: 0xFFFBBF24,
        ),
        StoryCharacter(
          id: 'ba_005',
          name: '优香',
          colorValue: 0xFFA78BFA,
        ),
        StoryCharacter(
          id: 'ba_006',
          name: '晴',
          colorValue: 0xFFFB7185,
        ),
        StoryCharacter(
          id: 'ba_007',
          name: '莲见',
          colorValue: 0xFF22D3EE,
        ),
        StoryCharacter(
          id: 'ba_008',
          name: '芹香',
          colorValue: 0xFFF97316,
        ),
        StoryCharacter(
          id: 'ba_009',
          name: '绫音',
          colorValue: 0xFF818CF8,
        ),
        StoryCharacter(
          id: 'ba_010',
          name: '惠',
          colorValue: 0xFFA3E635,
        ),
      ];

  static List<StoryCharacter> get allCharacters => baCharacters;
}
