import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/story.dart';
import 'story_editor_screen.dart';
import 'story_player_screen.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('剧情'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ctrl = TextEditingController();
          final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
            title: const Text('新建剧情'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '剧情名称')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('创建'))],
          ));
          if (name != null && name.isNotEmpty) {
            final s = await app.createStory(name);
            if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => StoryEditorScreen(story: s)));
          }
        },
        icon: const Icon(Icons.add), label: const Text('新建剧情'),
      ),
      body: app.stories.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('还没有剧情', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('创建你的第一个剧情吧', style: TextStyle(color: Colors.grey[400])),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: app.stories.length,
            itemBuilder: (_, i) {
              final s = app.stories[i];
              return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                onTap: () => _showOptions(context, s),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: Container(color: const Color(0xFFE8F0FE),
                    child: s.coverPath.isNotEmpty ? Image.network(s.coverPath, fit: BoxFit.cover) : Center(child: Icon(Icons.book, size: 48, color: Colors.blue[300])))),
                  Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${s.nodes.length}个节点', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ])),
                ]),
              ));
            },
          ),
    );
  }

  void _showOptions(BuildContext context, Story s) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.play_arrow), title: const Text('播放剧情'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => StoryPlayerScreen(story: s))); }),
      ListTile(leading: const Icon(Icons.edit), title: const Text('编辑剧情'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => StoryEditorScreen(story: s))); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('删除', style: TextStyle(color: Colors.red)), onTap: () { context.read<AppState>().deleteStory(s.id); Navigator.pop(context); }),
    ])));
  }
}
