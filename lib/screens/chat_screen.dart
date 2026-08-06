import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  int _visibleCount = 0;
  bool _animating = false;
  String? _nextSender; // null = me, or contact id for next
  bool _aiTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateMessages());
  }

  Future<void> _animateMessages() async {
    final app = context.read<AppState>();
    final msgs = app.messages[widget.contact.id] ?? [];
    if (_visibleCount >= msgs.length) return;
    setState(() => _animating = true);
    while (_visibleCount < msgs.length && mounted) {
      await Future.delayed(Duration(milliseconds: (300 / app.settings.messageSpeed).round()));
      if (!mounted) break;
      setState(() => _visibleCount++);
      _scrollToBottom();
    }
    if (mounted) setState(() => _animating = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final app = context.read<AppState>();
    final isMe = _nextSender == null;
    await app.sendMessage(chatId: widget.contact.id, content: text, isMe: isMe);
    _nextSender = null;
    setState(() => _visibleCount = (app.messages[widget.contact.id]?.length ?? 0));
    _scrollToBottom();
    if (isMe && widget.contact.aiEnabled) {
      setState(() => _aiTyping = true);
      await Future.delayed(const Duration(milliseconds: 500));
      await app.triggerAiReply(widget.contact.id);
      if (mounted) {
        setState(() { _aiTyping = false; _visibleCount = (app.messages[widget.contact.id]?.length ?? 0); });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final app = context.read<AppState>();
    await app.sendMessage(chatId: widget.contact.id, content: '[图片]', type: MessageType.image, extraData: x.path, isMe: true);
    setState(() => _visibleCount = (app.messages[widget.contact.id]?.length ?? 0));
    _scrollToBottom();
  }

  Future<void> _sendTransfer() async {
    final amount = await _showAmountDialog('转账');
    if (amount == null) return;
    final app = context.read<AppState>();
    await app.sendMessage(chatId: widget.contact.id, content: '转账 ¥$amount', type: MessageType.transfer, extraData: amount.toString(), isMe: true);
    setState(() => _visibleCount = (app.messages[widget.contact.id]?.length ?? 0));
    _scrollToBottom();
  }

  Future<void> _sendRedPacket() async {
    final amount = await _showAmountDialog('发红包');
    if (amount == null) return;
    final app = context.read<AppState>();
    await app.sendMessage(chatId: widget.contact.id, content: '🧧 红包 ¥$amount', type: MessageType.redPacket, extraData: amount.toString(), isMe: true);
    setState(() => _visibleCount = (app.messages[widget.contact.id]?.length ?? 0));
    _scrollToBottom();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final fileSize = await file.length();
    final app = context.read<AppState>();
    await app.sendMessage(
      chatId: widget.contact.id,
      content: '📎 $fileName',
      type: MessageType.file,
      extraData: '${result.files.single.path}|$fileSize',
      isMe: true,
    );
    setState(() => _visibleCount = (app.messages[widget.contact.id]?.length ?? 0));
    _scrollToBottom();
  }

  Future<double?> _showAmountDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<double>(context: context, builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '金额(元)', prefixText: '¥ ')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)), child: const Text('确定'))],
    ));
  }

  void _openImage(String path) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(children: [
        Center(child: path.startsWith('http') ? PhotoView(imageProvider: NetworkImage(path)) : PhotoView(imageProvider: FileImage(File(path)))),
        Positioned(bottom: 40, left: 0, right: 0, child: Center(child: IconButton.filled(
          icon: const Icon(Icons.download), onPressed: () async {
            await ImageGallerySaver.saveFile(path);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到相册')));
          },
        ))),
      ]),
    )));
  }

  Future<void> _openRedPacket(ChatMessage msg) async {
    if (msg.isOpened) return;
    final amount = double.tryParse(msg.extraData ?? '0') ?? 0;
    final app = context.read<AppState>();
    msg.isOpened = true;
    await app.addBalance(amount);
    await app.updateMessage(msg);
    if (mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🧧', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('已存入钱包'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('收下'))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final allMsgs = app.messages[widget.contact.id] ?? [];
    final msgs = allMsgs.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: Color(widget.contact.colorValue),
            child: widget.contact.avatarPath.isEmpty ? Text(widget.contact.name[0], style: const TextStyle(color: Colors.white, fontSize: 14)) : null,
            backgroundImage: widget.contact.avatarPath.isNotEmpty ? NetworkImage(widget.contact.avatarPath) : null),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.contact.name, style: const TextStyle(fontSize: 16)),
            if (_aiTyping) const Text('对方正在输入...', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
        actions: [
          PopupMenuButton(itemBuilder: (_) => [
            const PopupMenuItem(value: 'next_other', child: Text('下一条由对方发')),
            const PopupMenuItem(value: 'next_me', child: Text('下一条由我发')),
            if (widget.contact.aiEnabled) const PopupMenuItem(value: 'trigger_ai', child: Text('让AI回复')),
          ], onSelected: (v) {
            if (v == 'next_other') setState(() => _nextSender = widget.contact.id);
            if (v == 'next_me') setState(() => _nextSender = null);
            if (v == 'trigger_ai') app.triggerAiReply(widget.contact.id);
          }),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: msgs.length + (_aiTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == msgs.length) return _typingIndicator();
            return _messageBubble(msgs[i]);
          },
        )),
        _buildInputBar(),
      ]),
    );
  }

  Widget _typingIndicator() => Align(
    alignment: Alignment.centerLeft,
    child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2), width: 6, height: 6,
        decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(3)),
      )))),
  );

  Widget _messageBubble(ChatMessage msg) {
    if (msg.type == MessageType.system) {
      return Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Text(msg.content, style: TextStyle(fontSize: 12, color: Colors.grey[700]))));
    }

    final isMe = msg.isMe;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(radius: 16, backgroundColor: Color(widget.contact.colorValue),
            child: widget.contact.avatarPath.isEmpty ? Text(widget.contact.name[0], style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
            backgroundImage: widget.contact.avatarPath.isNotEmpty ? NetworkImage(widget.contact.avatarPath) : null),
          const SizedBox(width: 8),
        ],
        Flexible(child: GestureDetector(
          onTap: msg.type == MessageType.image ? () => _openImage(msg.extraData ?? '') : (msg.type == MessageType.redPacket ? () => _openRedPacket(msg) : null),
          child: Container(
            padding: _paddingForType(msg.type),
            decoration: BoxDecoration(
              color: _bubbleColor(msg.type, isMe),
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: _bubbleContent(msg, isMe),
          ),
        )),
        if (isMe) ...[const SizedBox(width: 8), CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.person, color: Colors.white, size: 18))],
      ],
    ));
  }

  EdgeInsets _paddingForType(MessageType t) {
    if (t == MessageType.image) return EdgeInsets.zero;
    if (t == MessageType.redPacket || t == MessageType.transfer) return const EdgeInsets.all(12);
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  }

  Color _bubbleColor(MessageType t, bool isMe) {
    if (t == MessageType.redPacket) return const Color(0xFFF5A623);
    if (t == MessageType.transfer) return const Color(0xFF4CAF50);
    return isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200]!;
  }

  Widget _bubbleContent(ChatMessage msg, bool isMe) {
    final style = TextStyle(color: _textColor(msg.type, isMe), fontSize: 15);
    switch (msg.type) {
      case MessageType.image:
        return ClipRRect(borderRadius: BorderRadius.circular(16),
          child: msg.extraData!.startsWith('http') ? Image.network(msg.extraData!, width: 200, fit: BoxFit.cover) : Image.file(File(msg.extraData!), width: 200, fit: BoxFit.cover));
      case MessageType.redPacket:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🧧', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(msg.isOpened ? '红包已领取' : '微信红包', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('¥${msg.extraData}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]);
      case MessageType.transfer:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.payments, color: Colors.white),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('转账 ¥${msg.extraData}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('点击查看详情', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]);
      case MessageType.file:
        final parts = msg.extraData?.split('|') ?? ['', '0'];
        final path = parts[0];
        final size = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final sizeStr = size < 1024 ? '$size B' : size < 1024 * 1024 ? '${(size / 1024).toStringAsFixed(1)} KB' : '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
        final fileName = path.split('/').last;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.insert_drive_file, size: 36),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(fileName, style: style.copyWith(fontWeight: FontWeight.w500)),
            Text(sizeStr, style: style.copyWith(fontSize: 12, color: isMe ? Colors.white70 : Colors.grey[600])),
          ]),
        ]);
      default:
        return Text(msg.content, style: style);
    }
  }

  Color _textColor(MessageType t, bool isMe) {
    if (t == MessageType.redPacket || t == MessageType.transfer) return Colors.white;
    return isMe ? Colors.white : Colors.black87;
  }

  Widget _buildInputBar() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: SafeArea(child: Row(children: [
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
          showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.image), title: const Text('图片'), onTap: () { Navigator.pop(context); _sendImage(); }),
            ListTile(leading: const Icon(Icons.attach_file), title: const Text('文件'), onTap: () { Navigator.pop(context); _sendFile(); }),
            ListTile(leading: const Icon(Icons.payments), title: const Text('转账'), onTap: () { Navigator.pop(context); _sendTransfer(); }),
            ListTile(leading: const Icon(Icons.card_giftcard), title: const Text('红包'), onTap: () { Navigator.pop(context); _sendRedPacket(); }),
          ])));
        }),
        Expanded(child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: _nextSender != null ? '以${widget.contact.name}身份发送...' : '输入消息...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          minLines: 1, maxLines: 4,
          onSubmitted: (_) => _sendText(),
        )),
        const SizedBox(width: 4),
        IconButton.filled(onPressed: _sendText, icon: const Icon(Icons.send)),
      ])),
    );
  }
}

