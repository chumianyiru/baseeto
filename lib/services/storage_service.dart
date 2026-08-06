import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import '../models/story.dart';
import '../models/app_settings.dart';

class StorageService {
  static late Box _contactsBox;
  static late Box _messagesBox;
  static late Box _storiesBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _contactsBox = await Hive.openBox('contacts');
    _messagesBox = await Hive.openBox('messages');
    _storiesBox = await Hive.openBox('stories');
    _settingsBox = await Hive.openBox('settings');
  }

  // Contacts
  static List<Contact> getContacts() {
    return _contactsBox.values.map((v) => Contact.fromJson(jsonDecode(v))).toList();
  }

  static Future<void> saveContact(Contact c) async {
    await _contactsBox.put(c.id, jsonEncode(c.toJson()));
  }

  static Future<void> deleteContact(String id) async {
    await _contactsBox.delete(id);
  }

  // Messages - stored as list per chatId
  static List<ChatMessage> getMessages(String chatId) {
    final data = _messagesBox.get(chatId);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((m) => ChatMessage.fromJson(m)).toList();
  }

  static Future<void> saveMessages(String chatId, List<ChatMessage> msgs) async {
    await _messagesBox.put(chatId, jsonEncode(msgs.map((m) => m.toJson()).toList()));
  }

  static Future<void> addMessage(ChatMessage msg) async {
    final msgs = getMessages(msg.chatId);
    msgs.add(msg);
    await saveMessages(msg.chatId, msgs);
  }

  // Stories
  static List<Story> getStories() {
    return _storiesBox.values.map((v) => Story.fromJson(jsonDecode(v))).toList();
  }

  static Future<void> saveStory(Story s) async {
    await _storiesBox.put(s.id, jsonEncode(s.toJson()));
  }

  static Future<void> deleteStory(String id) async {
    await _storiesBox.delete(id);
  }

  // Settings
  static AppSettings getSettings() {
    final data = _settingsBox.get('app');
    if (data == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(data));
  }

  static Future<void> saveSettings(AppSettings s) async {
    await _settingsBox.put('app', jsonEncode(s.toJson()));
  }
}
