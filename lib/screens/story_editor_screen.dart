import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/story.dart';
import 'story_player_screen.dart';

class StoryEditorScreen extends StatefulWidget {
  final Story story;

  const StoryEditorScreen({super.key, required this.story});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Story _story;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().updateStory(_story);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }

  void _addCharacter() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        int color = 0xFF2196F3;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('添加人物'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '人物名称'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    0xFFE91E63, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0,
                    0xFF00BCD4, 0xFF4CAF50, 0xFFF44336, 0xFFFFEB3B,
                  ].map((c) => GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == c ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              TextButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  _story.characters.add(StoryCharacter(
                    id: _uuid.v4(),
                    name: nameController.text.trim(),
                    colorValue: color,
                  ));
                  Navigator.pop(context);
                  this.setState(() {});
                },
                child: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addDialogue({String? afterId}) {
    if (_story.characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加至少一个人物')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        String selectedCharId = _story.characters.first.id;
        final textController = TextEditingController();
        bool isChoice = false;
        List<TextEditingController> choiceControllers = [TextEditingController(), TextEditingController()];
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('添加对话'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCharId,
                    items: _story.characters.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedCharId = v!),
                    decoration: const InputDecoration(labelText: '说话人物'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: '对话内容'),
                    maxLines: 3,
                  ),
                  SwitchListTile(
                    title: const Text('选项分支'),
                    value: isChoice,
                    onChanged: (v) => setState(() => isChoice = v),
                  ),
                  if (isChoice) ...[
                    ...choiceControllers.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(labelText: '选项 ${e.key + 1}'),
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              TextButton(
                onPressed: () {
                  final char = _story.characters.firstWhere((c) => c.id == selectedCharId);
                  final dialogueId = _uuid.v4();
                  final dialogue = StoryDialogue(
                    id: dialogueId,
                    characterId: char.id,
                    characterName: char.name,
                    text: textController.text.trim(),
                    isChoice: isChoice,
                    choices: isChoice
                        ? choiceControllers
                            .where((c) => c.text.trim().isNotEmpty)
                            .map((c) => StoryChoice(
                                  text: c.text.trim(),
                                  nextNodeId: _uuid.v4(),
                                ))
                            .toList()
                        : [],
                  );
                  _story.dialogues.add(dialogue);
                  Navigator.pop(context);
                  this.setState(() {});
                },
                child: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_story.title),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              _save();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryPlayerScreen(story: _story),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '人物'),
            Tab(text: '对话'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCharactersTab(),
          _buildDialoguesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addCharacter();
          } else {
            _addDialogue();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCharactersTab() {
    if (_story.characters.isEmpty) {
      return const Center(child: Text('暂无人物，点击右下角添加'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _story.characters.length,
      itemBuilder: (context, index) {
        final char = _story.characters[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(char.colorValue),
              child: Text(char.name[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(char.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => _story.characters.removeAt(index));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialoguesTab() {
    if (_story.dialogues.isEmpty) {
      return const Center(child: Text('暂无对话，点击右下角添加'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _story.dialogues.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _story.dialogues.removeAt(oldIndex);
          _story.dialogues.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final d = _story.dialogues[index];
        final char = _story.characters.firstWhere(
          (c) => c.id == d.characterId,
          orElse: () => StoryCharacter(id: '', name: '未知', colorValue: 0xFF999999),
        );
        return Card(
          key: ValueKey(d.id),
          color: d.isChoice ? Colors.amber.withOpacity(0.1) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(char.colorValue),
                      child: Text(char.name[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (d.isChoice)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('分支', style: TextStyle(fontSize: 10)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => setState(() => _story.dialogues.removeAt(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(d.text),
                if (d.isChoice && d.choices.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...d.choices.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16),
                        Text(c.text, style: const TextStyle(color: Colors.blue)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
