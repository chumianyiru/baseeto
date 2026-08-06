import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/story.dart';
import 'story_editor_screen.dart';
import 'story_player_screen.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final stories = appState.stories;
        return Scaffold(
          appBar: AppBar(
            title: const Text('剧情'),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'new', child: Text('新建剧情')),
                  const PopupMenuItem(value: 'preset', child: Text('加载蔚蓝档案预设')),
                ],
                onSelected: (value) async {
                  if (value == 'new') {
                    _showCreateDialog(context, appState);
                  } else if (value == 'preset') {
                    await _loadPresetStories(context, appState);
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context, appState),
            child: const Icon(Icons.add),
          ),
          body: stories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('还没有剧情', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('点击右上角创建或加载预设剧情', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    return _StoryCard(story: stories[index]);
                  },
                ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建剧情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '剧情名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '简介（可选）'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final story = await appState.createStory(
                title: titleController.text.trim(),
                description: descController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryEditorScreen(story: story),
                  ),
                );
              }
            },
            child: const Text('创建并编辑'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPresetStories(BuildContext context, AppState appState) async {
    final presetCharacters = [
      StoryCharacter(id: 'char_hoshino', name: '星野', colorValue: 0xFFE91E63),
      StoryCharacter(id: 'char_shiroko', name: '白子', colorValue: 0xFF2196F3),
      StoryCharacter(id: 'char_nonomi', name: '野宫', colorValue: 0xFFFF9800),
      StoryCharacter(id: 'char_serika', name: '芹香', colorValue: 0xFF9C27B0),
      StoryCharacter(id: 'char_yuka', name: '优香', colorValue: 0xFF00BCD4),
      StoryCharacter(id: 'char_noa', name: '诺亚', colorValue: 0xFF4CAF50),
      StoryCharacter(id: 'char_hina', name: '日奈', colorValue: 0xFFF44336),
      StoryCharacter(id: 'char_arisu', name: '爱丽丝', colorValue: 0xFF607D8B),
      StoryCharacter(id: 'char_mutsuki', name: '睦月', colorValue: 0xFFFFEB3B),
      StoryCharacter(id: 'char_kayoko', name: '佳代子', colorValue: 0xFF795548),
    ];

    final startId = 'node_start';
    final branchId = 'node_branch';
    final end1Id = 'node_end1';
    final end2Id = 'node_end2';

    final dialogues = [
      StoryDialogue(
        id: startId,
        characterId: 'char_hoshino',
        characterName: '星野',
        text: '老师~今天也辛苦了。要不要来一杯咖啡提提神？',
        nextNodeId: branchId,
      ),
      StoryDialogue(
        id: branchId,
        characterId: 'char_hoshino',
        characterName: '星野',
        text: '那么，老师今天想做什么呢？',
        isChoice: true,
        choices: [
          StoryChoice(text: '和星野一起休息', nextNodeId: end1Id),
          StoryChoice(text: '去工作', nextNodeId: end2Id),
        ],
      ),
      StoryDialogue(
        id: end1Id,
        characterId: 'char_hoshino',
        characterName: '星野',
        text: '嘿嘿，那就一起偷懒吧~老师的肩膀借我靠一下哦。',
      ),
      StoryDialogue(
        id: end2Id,
        characterId: 'char_yuka',
        characterName: '优香',
        text: '老师！您终于来了！文件已经堆积如山了，请立刻开始工作！',
      ),
    ];

    final story = Story(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '蔚蓝档案 - 日常篇',
      description: '基沃托斯的平凡一天，与学生们的温馨日常。',
      characters: presetCharacters,
      dialogues: dialogues,
      createdAt: DateTime.now(),
      startNodeId: startId,
    );

    appState.stories.add(story);
    await appState.updateStory(story);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加载蔚蓝档案预设剧情，包含10个角色')),
      );
    }
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryPlayerScreen(story: story),
            ),
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('编辑剧情'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryEditorScreen(story: story),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('播放剧情'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryPlayerScreen(story: story),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('删除', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      context.read<AppState>().deleteStory(story.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Color(story.characters.isNotEmpty ? story.characters.first.colorValue : 0xFF3B82F6).withOpacity(0.2),
                child: Center(
                  child: story.coverPath != null
                      ? Image.network(story.coverPath!, fit: BoxFit.cover)
                      : Icon(Icons.auto_stories, size: 48, color: Colors.grey[600]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.description.isNotEmpty ? story.description : '${story.dialogues.length} 段对话',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MM/dd HH:mm').format(story.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
