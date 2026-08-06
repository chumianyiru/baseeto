import 'package:flutter/material.dart';
import '../models/story.dart';

class StoryPlayerScreen extends StatefulWidget {
  final Story story;

  const StoryPlayerScreen({super.key, required this.story});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  String? _currentNodeId;
  StoryDialogue? _currentDialogue;
  String _displayedText = '';
  bool _isTyping = false;
  bool _textComplete = false;
  int _typingIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentNodeId = widget.story.startNodeId;
    _loadCurrentDialogue();
  }

  void _loadCurrentDialogue() {
    if (_currentNodeId == null) {
      setState(() => _currentDialogue = null);
      return;
    }
    final dialogue = widget.story.dialogues.firstWhere(
      (d) => d.id == _currentNodeId,
      orElse: () => widget.story.dialogues.isNotEmpty
          ? widget.story.dialogues.first
          : StoryDialogue(id: '', characterId: '', characterName: '', text: ''),
    );
    setState(() {
      _currentDialogue = dialogue;
      _displayedText = '';
      _typingIndex = 0;
      _textComplete = false;
      _isTyping = true;
    });
    _startTypingAnimation(dialogue.text);
  }

  void _startTypingAnimation(String fullText) {
    Future.doWhile(() async {
      if (!mounted || _typingIndex >= fullText.length) {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _textComplete = true;
          });
        }
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return false;
      setState(() {
        _typingIndex++;
        _displayedText = fullText.substring(0, _typingIndex);
      });
      return true;
    });
  }

  void _onTap() {
    if (_currentDialogue == null) {
      Navigator.pop(context);
      return;
    }

    if (_isTyping) {
      setState(() {
        _displayedText = _currentDialogue!.text;
        _typingIndex = _currentDialogue!.text.length;
        _isTyping = false;
        _textComplete = true;
      });
      return;
    }

    if (_currentDialogue!.isChoice) {
      return;
    }

    if (_currentDialogue!.nextNodeId != null) {
      _currentNodeId = _currentDialogue!.nextNodeId;
      _loadCurrentDialogue();
    } else {
      _showEnding();
    }
  }

  void _onChoiceSelected(StoryChoice choice) {
    _currentNodeId = choice.nextNodeId;
    _loadCurrentDialogue();
  }

  void _showEnding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('剧情结束'),
        content: const Text('感谢游玩！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('返回'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _currentNodeId = widget.story.startNodeId;
              _loadCurrentDialogue();
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  StoryCharacter? _getCurrentCharacter() {
    if (_currentDialogue == null) return null;
    try {
      return widget.story.characters.firstWhere(
        (c) => c.id == _currentDialogue!.characterId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final character = _getCurrentCharacter();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    character != null
                        ? Color(character.colorValue).withOpacity(0.3)
                        : Colors.blueGrey.shade900,
                    Colors.black,
                  ],
                ),
              ),
            ),
            // Character placeholder
            if (character != null)
              Positioned(
                bottom: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(character.colorValue).withOpacity(0.6),
                          Color(character.colorValue).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(100),
                        topRight: Radius.circular(100),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        character.name,
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  widget.story.title,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Choices
            if (_currentDialogue?.isChoice == true && _textComplete)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _currentDialogue!.choices.map((choice) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _onChoiceSelected(choice),
                          child: Text(
                            choice.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Dialog box
            if (_currentDialogue != null && !(_currentDialogue!.isChoice && _textComplete))
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (character != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(character.colorValue),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          character.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: character != null
                              ? Color(character.colorValue).withOpacity(0.5)
                              : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayedText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.6,
                            ),
                          ),
                          if (_textComplete && !_currentDialogue!.isChoice)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
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
