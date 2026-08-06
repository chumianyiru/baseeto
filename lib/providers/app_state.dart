import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import '../models/story.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<Contact> _contacts = [];
  List<ChatMessage> _messages = [];
  List<Story> _stories = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  List<Contact> get contacts => _contacts;
  List<ChatMessage> get messages => _messages;
  List<Story> get stories => _stories;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _storage.init();
    _contacts = await _storage.getContacts();
    _messages = await _storage.getMessages();
    _stories = await _storage.getStories();
    _settings = await _storage.getSettings();
    _isLoading = false;
    notifyListeners();
  }

  // Contact operations
  Future<Contact> addContact({
    required String name,
    String avatarPath = '',
    String systemPrompt = '',
    bool enableAI = false,
    bool isGroup = false,
    List<String> memberIds = const [],
    int colorValue = 0xFF2196F3,
  }) async {
    final contact = Contact(
      id: _uuid.v4(),
      name: name,
      avatarPath: avatarPath,
      systemPrompt: systemPrompt,
      enableAI: enableAI,
      isGroup: isGroup,
      memberIds: memberIds,
      colorValue: colorValue,
    );
    _contacts.add(contact);
    await _storage.saveContacts(_contacts);
    notifyListeners();
    return contact;
  }

  Future<void> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await _storage.saveContacts(_contacts);
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    _messages.removeWhere((m) => m.chatId == id);
    await _storage.saveContacts(_contacts);
    await _storage.saveMessages(_messages);
    notifyListeners();
  }

  // Message operations
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    bool isMe = false,
    String? filePath,
    double? amount,
    String? avatarPath,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      type: type,
      isMe: isMe,
      filePath: filePath,
      amount: amount,
      avatarPath: avatarPath,
    );
    _messages.add(message);
    await _storage.saveMessages(_messages);
    notifyListeners();

    // Show notification
    if (!isMe && _settings.notificationsEnabled) {
      await NotificationService.showNotification(
        title: senderName,
        body: type == MessageType.text ? content : '[${_getTypeText(type)}]',
      );
    }

    // AI auto-reply
    if (isMe) {
      final contact = _contacts.firstWhere(
        (c) => c.id == chatId,
        orElse: () => Contact(id: '', name: ''),
      );
      if (contact.enableAI && contact.id.isNotEmpty) {
        _triggerAIReply(chatId, contact);
      }
    }

    return message;
  }

  String _getTypeText(MessageType type) {
    switch (type) {
      case MessageType.image: return '图片';
      case MessageType.file: return '文件';
      case MessageType.transfer: return '转账';
      case MessageType.redPacket: return '红包';
      case MessageType.emoji: return '表情';
      default: return '消息';
    }
  }

  Future<void> _triggerAIReply(String chatId, Contact contact) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final chatMessages = getMessagesForChat(chatId);
    final history = chatMessages.map((m) => {
      'role': m.isMe ? 'user' : 'assistant',
      'content': m.content,
    }).toList();

    final reply = await AIService.getReply(
      systemPrompt: contact.systemPrompt,
      history: history,
      apiKey: _settings.apiKey,
      model: _settings.modelName,
    );

    if (reply != null && reply.isNotEmpty) {
      await sendMessage(
        chatId: chatId,
        senderId: contact.id,
        senderName: contact.name,
        content: reply,
        isMe: false,
        avatarPath: contact.avatarPath,
      );
    }
  }

  Future<void> openRedPacket(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && !_messages[index].isOpened) {
      _messages[index].isOpened = true;
      final amount = _messages[index].amount ?? 0;
      _settings.balance += amount;
      await _storage.saveMessages(_messages);
      await _storage.saveSettings(_settings);
      notifyListeners();
    }
  }

  // Wallet
  Future<void> setBalance(double amount) async {
    _settings.balance = amount;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // Settings
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // Story operations
  Future<Story> createStory({
    required String title,
    String description = '',
    String? coverPath,
  }) async {
    final story = Story(
      id: _uuid.v4(),
      title: title,
      description: description,
      coverPath: coverPath,
      createdAt: DateTime.now(),
      startNodeId: _uuid.v4(),
      characters: [],
      dialogues: [],
    );
    _stories.add(story);
    await _storage.saveStories(_stories);
    notifyListeners();
    return story;
  }

  Future<void> updateStory(Story story) async {
    final index = _stories.indexWhere((s) => s.id == story.id);
    if (index != -1) {
      _stories[index] = story;
      await _storage.saveStories(_stories);
      notifyListeners();
    }
  }

  Future<void> deleteStory(String id) async {
    _stories.removeWhere((s) => s.id == id);
    await _storage.saveStories(_stories);
    notifyListeners();
  }

  Contact? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
