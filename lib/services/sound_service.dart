import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static double _volume = 0.7;

  static Future<void> playMessageSound({bool isMe = false}) async {
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('sounds/message.wav'));
    } catch (e) {
      // Silently fail if sound not available
    }
  }

  static Future<void> playSendSound() async {
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('sounds/send.wav'));
    } catch (e) {}
  }

  static void setVolume(double volume) {
    _volume = volume;
  }
}
