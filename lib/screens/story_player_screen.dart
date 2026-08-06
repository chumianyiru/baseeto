import 'dart:async';
import 'package:flutter/material.dart';
import '../models/story.dart';

class StoryPlayerScreen extends StatefulWidget {
  final Story story;
  const StoryPlayerScreen({super.key, required this.story});
  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> with SingleTickerProviderStateMixin {
  StoryNode? _currentNode;
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typeTimer;
  bool _isTyping = false;
  bool _showChoices = false;
  String? _endingTitle;
  String? _bgPath;

  @override
  void initState() {
    super.initState();
    _goToNode(widget.story.startNodeId);
  }

  @override
  void dispose() { _typeTimer?.cancel(); super.dispose(); }

  void _goToNode(String? nodeId) {
    if (nodeId == null || nodeId.isEmpty) { _showEnding('剧情结束'); return; }
    final node = widget.story.nodes.firstWhere((n) => n.id == nodeId, orElse: () => StoryNode(id: '', characterId: '', text: ''));
    if (node.id.isEmpty) { _showEnding('剧情结束'); return; }
    setState(() {
      _currentNode = node;
      _displayedText = '';
      _charIndex = 0;
      _showChoices = false;
      _endingTitle = null;
      if (node.backgroundPath != null) _bgPath = node.backgroundPath;
    });
    _startTyping(node.text);
  }

  void _startTyping(String text) {
    _typeTimer?.cancel();
    _isTyping = true;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (_charIndex >= text.length) {
        t.cancel(); _isTyping = false;
        if (mounted) {
          setState(() {
            if (_currentNode!.isEnding) _showEnding(_currentNode!.endingTitle ?? '剧情结束');
            else if (_currentNode!.choices.isNotEmpty) _showChoices = true;
          });
        }
        return;
      }
      setState(() => _displayedText = text.substring(0, _charIndex + 1));
      _charIndex++;
    });
  }

  void _onTap() {
    if (_isTyping) { _typeTimer?.cancel(); setState(() { _displayedText = _currentNode!.text; _isTyping = false; if (_currentNode!.choices.isNotEmpty) _showChoices = true; }); return; }
    if (_showChoices) return;
    if (_endingTitle != null) { Navigator.pop(context); return; }
    if (_currentNode != null && _currentNode!.choices.isEmpty) {
      _goToNode(_currentNode!.nextNodeId);
    }
  }

  void _showEnding(String title) {
    setState(() => _endingTitle = title);
  }

  StoryCharacter? _getChar(String id) {
    try { return widget.story.characters.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final char = _currentNode != null ? _getChar(_currentNode!.characterId) : null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(onTap: _onTap, child: Stack(fit: StackFit.expand, children: [
        // Background
        if (_bgPath != null) Positioned.fill(child: Image.network(_bgPath!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: const Color(0xFF1a1a2e))))
        else Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1a1a3e), Color(0xFF2d1b4e)]))),
        // Character portrait area
        if (char != null && char.avatarPath.isNotEmpty) Positioned(bottom: 180, left: 0, right: 0, child: Center(child: Opacity(opacity: 0.9, child: Image.network(char.avatarPath, height: 300, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox())))),
        // Ending overlay
        if (_endingTitle != null) Container(color: Colors.black.withOpacity(0.8), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('— END —', style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 4)),
          const SizedBox(height: 16),
          Text(_endingTitle!, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('点击屏幕返回', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ]))),
        // Choices
        if (_showChoices) Positioned.fill(child: Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ..._currentNode!.choices.map((c) => Container(margin: const EdgeInsets.symmetric(vertical: 6), width: 280, child: Material(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), child: InkWell(
            borderRadius: BorderRadius.circular(8), onTap: () => _goToNode(c.targetNodeId),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), child: Center(child: Text(c.text, style: const TextStyle(fontSize: 16, color: Colors.black87)))),
          )))),
        ])))),
        // Dialog box (Blue Archive style)
        if (_currentNode != null && _endingTitle == null) Positioned(left: 16, right: 16, bottom: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (char != null) Container(margin: const EdgeInsets.only(left: 12, bottom: -1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Color(char.colorValue), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
            child: Text(char.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16), topRight: Radius.circular(16))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_displayedText, style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.5)),
              if (_isTyping) const SizedBox.shrink()
              else if (!_showChoices) Align(alignment: Alignment.bottomRight, child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20)),
            ])),
        ])),
        // Back button
        Positioned(top: 40, left: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context))),
      ])),
    );
  }
}
