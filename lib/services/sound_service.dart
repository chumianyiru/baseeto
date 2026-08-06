import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static double _volume = 0.7;

  static Future<void> playMessageSound({bool isMe = false}) async {
    try {
      await _player.setVolume(_volume);
      // Use system sound effect - we'll use a simple beep via audio cache
      // In a real app, you'd have actual sound files in assets
      await _player.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      // Silently fail if sound not available
    }
  }

  static Future<void> playSendSound() async {
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('sounds/send.mp3'));
    } catch (e) {}
  }

  static void setVolume(double volume) {
    _volume = volume;
  }
}
