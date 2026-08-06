import 'dart:async';
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
  final _uuid = const Uuid();
  List<Contact> contacts = [];
  Map<String, List<ChatMessage>> messages = {};
  List<Story> stories = [];
  AppSettings settings = AppSettings();
  bool _initialized = false;

  Future<void> init() async {
    await StorageService.init();
    contacts = StorageService.getContacts();
    stories = StorageService.getStories();
    settings = StorageService.getSettings();
    for (final c in contacts) {
      messages[c.id] = StorageService.getMessages(c.id);
    }
    _initialized = true;
    notifyListeners();
  }

  void _checkInit() { if (!_initialized) return; }

  // Contacts
  Future<Contact> addContact({required String name, String avatarPath = '', String systemPrompt = '', bool isGroup = false, List<String> memberIds = const [], int colorValue = 0xFF3B82F6}) async {
    final c = Contact(
      id: _uuid.v4(), name: name, avatarPath: avatarPath,
      systemPrompt: systemPrompt.isEmpty ? '你是$name，用$name的语气和用户聊天。' : systemPrompt,
      isGroup: isGroup, memberIds: memberIds, colorValue: colorValue,
    );
    contacts.add(c);
    messages[c.id] = [];
    await StorageService.saveContact(c);
    notifyListeners();
    return c;
  }

  Future<void> updateContact(Contact c) async {
    final idx = contacts.indexWhere((x) => x.id == c.id);
    if (idx >= 0) { contacts[idx] = c; await StorageService.saveContact(c); notifyListeners(); }
  }

  Future<void> deleteContact(String id) async {
    contacts.removeWhere((c) => c.id == id);
    messages.remove(id);
    await StorageService.deleteContact(id);
    await StorageService.saveMessages(id, []);
    notifyListeners();
  }

  Contact? getContact(String id) {
    try { return contacts.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  // Messages
  List<ChatMessage> getMessages(String chatId) => messages[chatId] ?? [];

  Future<ChatMessage> sendMessage({required String chatId, required String content, MessageType type = MessageType.text, String? extraData, String? senderId, String? senderName, bool isMe = true}) async {
    final contact = getContact(chatId);
    final msg = ChatMessage(
      id: _uuid.v4(), chatId: chatId,
      senderId: senderId ?? (isMe ? 'me' : chatId),
      senderName: senderName ?? (isMe ? settings.myName : (contact?.name ?? '')),
      content: content, timestamp: DateTime.now(), isMe: isMe,
      type: type, extraData: extraData,
    );
    messages.putIfAbsent(chatId, () => []).add(msg);
    await StorageService.addMessage(msg);
    notifyListeners();
    return msg;
  }

  Future<void> triggerAiReply(String chatId) async {
    final contact = getContact(chatId);
    if (contact == null || !contact.aiEnabled) return;
    final history = messages[chatId] ?? [];
    final recent = history.length > 20 ? history.sublist(history.length - 20) : history;
    final hist = recent.map((m) => {
      'role': m.isMe ? 'user' : 'assistant',
      'content': m.content,
    }).toList();

    // Add group members context
    var sysPrompt = contact.systemPrompt;
    if (contact.isGroup && contact.memberIds.isNotEmpty) {
      final memberNames = contact.memberIds.map((id) => getContact(id)?.name ?? '').where((n) => n.isNotEmpty).join('、');
      sysPrompt = '$sysPrompt\n群成员有：$memberNames。你在群聊中发言。';
    }

    final reply = await AiService.chat(
      apiKey: settings.apiKey, model: settings.apiModel,
      systemPrompt: sysPrompt, history: hist,
    );
    final msg = await sendMessage(chatId: chatId, content: reply, isMe: false);
    if (settings.notificationEnabled) {
      NotificationService.showMessageNotification(contact.name, reply);
    }
  }

  // Wallet
  Future<void> setBalance(double v) async {
    settings.balance = v; await StorageService.saveSettings(settings); notifyListeners();
  }

  Future<void> addBalance(double v) async {
    settings.balance += v; await StorageService.saveSettings(settings); notifyListeners();
  }

  // Settings
  Future<void> updateSettings(AppSettings s) async {
    settings = s; await StorageService.saveSettings(s); notifyListeners();
  }

  // Stories
  Future<Story> createStory(String title) async {
    final s = Story(
      id: _uuid.v4(), title: title, startNodeId: '',
      characters: [], nodes: [], createdAt: DateTime.now(),
    );
    stories.add(s);
    await StorageService.saveStory(s);
    notifyListeners();
    return s;
  }

  Future<void> updateStory(Story s) async {
    final idx = stories.indexWhere((x) => x.id == s.id);
    if (idx >= 0) { stories[idx] = s; await StorageService.saveStory(s); notifyListeners(); }
  }

  Future<void> deleteStory(String id) async {
    stories.removeWhere((s) => s.id == id);
    await StorageService.deleteStory(id);
    notifyListeners();
  }

  Future<void> updateMessage(ChatMessage msg) async {
    final list = messages[msg.chatId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) { list[idx] = msg; await StorageService.saveMessages(msg.chatId, list); notifyListeners(); }
    }
  }

  String newId() => _uuid.v4();
}
