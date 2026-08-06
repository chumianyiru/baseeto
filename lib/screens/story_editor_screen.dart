import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late TabController _tab;
  late Story _story;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_story.title), bottom: TabBar(controller: _tab, tabs: const [
        Tab(text: '基本信息'), Tab(text: '人物'), Tab(text: '对话节点'),
      ]), actions: [
        IconButton(icon: const Icon(Icons.play_arrow), onPressed: _story.startNodeId.isEmpty ? null : () {
          context.read<AppState>().updateStory(_story);
          Navigator.push(context, MaterialPageRoute(builder: (_) => StoryPlayerScreen(story: _story)));
        }),
      ]),
      body: TabBarView(controller: _tab, children: [
        _buildBasic(), _buildCharacters(), _buildNodes(),
      ]),
    );
  }

  Widget _buildBasic() {
    final titleCtrl = TextEditingController(text: _story.title);
    final descCtrl = TextEditingController(text: _story.description);
    final coverCtrl = TextEditingController(text: _story.coverPath);
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '剧情名称', border: OutlineInputBorder()), onChanged: (v) => _story.title = v),
      const SizedBox(height: 12),
      TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '简介', border: OutlineInputBorder()), maxLines: 3, onChanged: (v) => _story.description = v),
      const SizedBox(height: 12),
      TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: '封面URL', border: OutlineInputBorder()), onChanged: (v) => _story.coverPath = v),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () => context.read<AppState>().updateStory(_story), icon: const Icon(Icons.save), label: const Text('保存')),
    ]);
  }

  Widget _buildCharacters() {
    return Stack(children: [
      ListView.builder(padding: const EdgeInsets.all(16), itemCount: _story.characters.length, itemBuilder: (_, i) {
        final c = _story.characters[i];
        return Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: Color(c.colorValue), child: c.avatarPath.isNotEmpty ? null : Text(c.name[0], style: const TextStyle(color: Colors.white)), backgroundImage: c.avatarPath.isNotEmpty ? NetworkImage(c.avatarPath) : null),
          title: Text(c.name),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _story.characters.removeAt(i))),
          onTap: () => _editCharacter(c),
        ));
      }),
      Positioned(bottom: 16, right: 16, child: FloatingActionButton(onPressed: _addCharacter, child: const Icon(Icons.add))),
    ]);
  }

  Future<void> _addCharacter() async {
    final nameCtrl = TextEditingController();
    final avatarCtrl = TextEditingController();
    int color = 0xFF60A5FA;
    await showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      title: const Text('添加人物'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '人物名称')),
        TextField(controller: avatarCtrl, decoration: const InputDecoration(labelText: '头像URL(可选)')),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [0xFF60A5FA, 0xFFEC4899, 0xFF10B981, 0xFFF59E0B, 0xFF8B5CF6, 0xFFEF4444].map((c) => GestureDetector(
          onTap: () => setSt(() => color = c), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: color == c ? Border.all(width: 2) : null)),
        )).toList()),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), TextButton(onPressed: () {
        if (nameCtrl.text.isNotEmpty) {
          setState(() => _story.characters.add(StoryCharacter(id: context.read<AppState>().newId(), name: nameCtrl.text, avatarPath: avatarCtrl.text, colorValue: color)));
        }
        Navigator.pop(ctx);
      }, child: const Text('添加'))],
    )));
  }

  Future<void> _editCharacter(StoryCharacter c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final avatarCtrl = TextEditingController(text: c.avatarPath);
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑人物'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
        TextField(controller: avatarCtrl, decoration: const InputDecoration(labelText: '头像URL')),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), TextButton(onPressed: () {
        setState(() { c.name = nameCtrl.text; c.avatarPath = avatarCtrl.text; });
        Navigator.pop(ctx);
      }, child: const Text('保存'))],
    ));
  }

  Widget _buildNodes() {
    return Stack(children: [
      _story.nodes.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.format_list_bulleted, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('添加第一个对话节点', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            if (_story.characters.isEmpty) Text('请先在"人物"标签添加人物', style: TextStyle(color: Colors.red[300], fontSize: 12)),
          ]))
        : ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _story.nodes.length,
            onReorder: (o, n) => setState(() { if (n > o) n--; final item = _story.nodes.removeAt(o); _story.nodes.insert(n, item); }),
            itemBuilder: (_, i) {
              final node = _story.nodes[i];
              final char = _story.characters.firstWhere((c) => c.id == node.characterId, orElse: () => StoryCharacter(id: '', name: '旁白', colorValue: 0xFF999999));
              return Card(key: ValueKey(node.id), child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: Color(char.colorValue), radius: 16, child: Text(char.name[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(node.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (i == 0 || _story.startNodeId == node.id) Tooltip(message: '起始节点', child: Icon(Icons.start, size: 18, color: Colors.green[600])),
                  if (node.isEnding) Tooltip(message: '结局', child: Icon(Icons.flag, size: 18, color: Colors.orange[600])),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => setState(() => _story.nodes.removeAt(i))),
                ]),
                children: [_nodeEditor(node)],
              ));
            },
          ),
      Positioned(bottom: 16, right: 16, child: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(onPressed: _addNode, heroTag: 'addnode', child: const Icon(Icons.add)),
        const SizedBox(height: 8),
        FloatingActionButton.small(onPressed: _story.nodes.isNotEmpty ? () => setState(() => _story.startNodeId = _story.nodes.first.id) : null, heroTag: 'setstart', child: const Icon(Icons.start), tooltip: '设第一个为起始'),
      ])),
    ]);
  }

  Widget _nodeEditor(StoryNode node) {
    final textCtrl = TextEditingController(text: node.text);
    final bgCtrl = TextEditingController(text: node.backgroundPath ?? '');
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<String>(
        value: _story.characters.any((c) => c.id == node.characterId) ? node.characterId : null,
        decoration: const InputDecoration(labelText: '说话人物'),
        items: [const DropdownMenuItem(value: '', child: Text('旁白/系统')), ..._story.characters.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
        onChanged: (v) => setState(() => node.characterId = v ?? ''),
      ),
      const SizedBox(height: 8),
      TextField(controller: textCtrl, decoration: const InputDecoration(labelText: '对话文本', border: OutlineInputBorder()), maxLines: 3, onChanged: (v) => node.text = v),
      const SizedBox(height: 8),
      TextField(controller: bgCtrl, decoration: const InputDecoration(labelText: '背景图URL(可选)'), onChanged: (v) => node.backgroundPath = v.isEmpty ? null : v),
      const SizedBox(height: 8),
      Row(children: [
        FilterChip(label: const Text('结局'), selected: node.isEnding, onSelected: (v) => setState(() => node.isEnding = v)),
        const SizedBox(width: 8),
        if (node.isEnding) Expanded(child: TextField(
          decoration: const InputDecoration(labelText: '结局标题', isDense: true),
          controller: TextEditingController(text: node.endingTitle ?? ''),
          onChanged: (v) => node.endingTitle = v,
        )),
      ]),
      const SizedBox(height: 12),
      const Text('选项分支', style: TextStyle(fontWeight: FontWeight.bold)),
      ...node.choices.asMap().entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
        Expanded(child: TextField(
          decoration: InputDecoration(labelText: '选项${e.key + 1}', isDense: true),
          controller: TextEditingController(text: e.value.text),
          onChanged: (v) => e.value.text = v,
        )),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _story.nodes.any((n) => n.id == e.value.targetNodeId) ? e.value.targetNodeId : null,
          hint: const Text('目标'), items: _story.nodes.map((n) {
            final ch = _story.characters.firstWhere((c) => c.id == n.characterId, orElse: () => StoryCharacter(id: '', name: '旁白'));
            return DropdownMenuItem(value: n.id, child: Text('${ch.name}: ${n.text.substring(0, n.text.length > 10 ? 10 : n.text.length)}', overflow: TextOverflow.ellipsis));
          }).toList(), onChanged: (v) => setState(() => e.value.targetNodeId = v ?? ''),
        ),
        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => node.choices.removeAt(e.key))),
      ]))),
      TextButton.icon(onPressed: () => setState(() => node.choices.add(StoryChoice(text: '', targetNodeId: ''))), icon: const Icon(Icons.add), label: const Text('添加选项')),
      const SizedBox(height: 8),
      if (node.choices.isEmpty) DropdownButtonFormField<String>(
        value: _story.nodes.any((n) => n.id == node.nextNodeId) ? node.nextNodeId : null,
        decoration: const InputDecoration(labelText: '下一节点(无选项时)'),
        items: _story.nodes.map((n) {
          final ch = _story.characters.firstWhere((c) => c.id == n.characterId, orElse: () => StoryCharacter(id: '', name: '旁白'));
          return DropdownMenuItem(value: n.id, child: Text('${ch.name}: ${n.text.substring(0, n.text.length > 15 ? 15 : n.text.length)}'));
        }).toList(), onChanged: (v) => setState(() => node.nextNodeId = v),
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: () { context.read<AppState>().updateStory(_story); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存'))); }, icon: const Icon(Icons.save), label: const Text('保存')),
    ]));
  }

  void _addNode() {
    if (_story.characters.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先添加人物'))); return; }
    setState(() {
      final node = StoryNode(id: context.read<AppState>().newId(), characterId: _story.characters.first.id, text: '');
      _story.nodes.add(node);
      if (_story.startNodeId.isEmpty) _story.startNodeId = node.id;
    });
  }
}
