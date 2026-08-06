import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/contact.dart';

class ContactEditScreen extends StatefulWidget {
  final Contact? contact;
  final bool isGroup;
  const ContactEditScreen({super.key, this.contact, this.isGroup = false});
  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _promptCtrl;
  late TextEditingController _avatarCtrl;
  late bool _aiEnabled;
  late int _color;
  List<String> _selectedMembers = [];

  static const _colors = [0xFF3B82F6, 0xFFEC4899, 0xFF8B5CF6, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444, 0xFF06B6D4, 0xFF6366F1];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.contact?.name ?? '');
    _promptCtrl = TextEditingController(text: widget.contact?.systemPrompt ?? '');
    _avatarCtrl = TextEditingController(text: widget.contact?.avatarPath ?? '');
    _aiEnabled = widget.contact?.aiEnabled ?? true;
    _color = widget.contact?.colorValue ?? _colors[0];
    _selectedMembers = List.from(widget.contact?.memberIds ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact == null ? (widget.isGroup ? '创建群聊' : '添加联系人') : '编辑'),
        actions: [if (widget.contact != null) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {
          app.deleteContact(widget.contact!.id); Navigator.pop(context);
        }), TextButton(onPressed: _save, child: const Text('保存'))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: CircleAvatar(radius: 40, backgroundColor: Color(_color),
          child: _avatarCtrl.text.isNotEmpty ? null : Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 28)),
          backgroundImage: _avatarCtrl.text.isNotEmpty ? NetworkImage(_avatarCtrl.text) : null)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: widget.isGroup ? '群名称' : '昵称', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        TextField(controller: _avatarCtrl, decoration: const InputDecoration(labelText: '头像URL(可选)', border: OutlineInputBorder(), hintText: 'https://...'), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        if (!widget.isGroup) ...[
          TextField(controller: _promptCtrl, decoration: const InputDecoration(labelText: 'AI角色设定 (System Prompt)', border: OutlineInputBorder(), hintText: '例如：你是星野，一个温柔的学姐...'), maxLines: 3),
          const SizedBox(height: 12),
          SwitchListTile(title: const Text('AI自动回复'), value: _aiEnabled, onChanged: (v) => setState(() => _aiEnabled = v), contentPadding: EdgeInsets.zero),
        ],
        if (widget.isGroup) ...[
          const Text('选择群成员', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...app.contacts.where((c) => !c.isGroup).map((c) => CheckboxListTile(
            title: Text(c.name), value: _selectedMembers.contains(c.id),
            secondary: CircleAvatar(backgroundColor: Color(c.colorValue), child: Text(c.name[0], style: const TextStyle(color: Colors.white))),
            onChanged: (v) => setState(() { v == true ? _selectedMembers.add(c.id) : _selectedMembers.remove(c.id); }),
          )),
        ],
        const SizedBox(height: 16),
        const Text('主题色', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, children: _colors.map((c) => GestureDetector(
          onTap: () => setState(() => _color = c),
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: _color == c ? Border.all(color: Colors.black, width: 2) : null)),
        )).toList()),
      ]),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入名称'))); return; }
    final app = context.read<AppState>();
    if (widget.contact == null) {
      app.addContact(name: _nameCtrl.text.trim(), avatarPath: _avatarCtrl.text.trim(), systemPrompt: _promptCtrl.text.trim(), isGroup: widget.isGroup, memberIds: _selectedMembers, colorValue: _color);
    } else {
      widget.contact!
        ..name = _nameCtrl.text.trim()
        ..avatarPath = _avatarCtrl.text.trim()
        ..systemPrompt = _promptCtrl.text.trim()
        ..aiEnabled = _aiEnabled
        ..memberIds = _selectedMembers
        ..colorValue = _color;
      app.updateContact(widget.contact!);
    }
    Navigator.pop(context);
  }
}
