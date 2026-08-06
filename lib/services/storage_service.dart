import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import '../models/story.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _contactsKey = 'contacts';
  static const String _messagesKey = 'messages';
  static const String _storiesKey = 'stories';
  static const String _settingsKey = 'settings';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Contacts
  Future<List<Contact>> getContacts() async {
    final String? data = _prefs.getString(_contactsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final String data = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await _prefs.setString(_contactsKey, data);
  }

  // Messages
  Future<List<ChatMessage>> getMessages() async {
    final String? data = _prefs.getString(_messagesKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final String data = jsonEncode(messages.map((e) => e.toJson()).toList());
    await _prefs.setString(_messagesKey, data);
  }

  // Stories
  Future<List<Story>> getStories() async {
    final String? data = _prefs.getString(_storiesKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveStories(List<Story> stories) async {
    final String data = jsonEncode(stories.map((e) => e.toJson()).toList());
    await _prefs.setString(_storiesKey, data);
  }

  // Settings
  Future<AppSettings> getSettings() async {
    final String? data = _prefs.getString(_settingsKey);
    if (data == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
