import 'package:flutter/services.dart';

class VolumeChannel {
  static const MethodChannel _channel = MethodChannel('volume_channel');

  static Future<double> getMediaVolume() async {
    final double volume = await _channel.invokeMethod('getMediaVolume');
    return volume;
  }
} 