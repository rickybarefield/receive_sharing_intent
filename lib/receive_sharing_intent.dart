import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/Message.dart';

class ReceiveSharingIntent {
  static const MethodChannel _mChannel =
  const MethodChannel('receive_sharing_intent/messages');
  static const EventChannel _eChannelMedia =
  const EventChannel("receive_sharing_intent/events-media");
  static const EventChannel _eChannelLink =
  const EventChannel("receive_sharing_intent/events-text");

  static Stream<List<SharedMediaFile>>? _streamMedia;
  static Stream<Message>? _streamLink;

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored media uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  ///
  /// NOTE. The returned media on iOS (iOS ONLY) is already copied to a temp folder.
  /// So, you need to delete the file after you finish using it
  static Future<List<SharedMediaFile>> getInitialMedia() async {
    final json = await _mChannel.invokeMethod('getInitialMedia');
    if (json == null) return [];
    final encoded = jsonDecode(json);
    return encoded
        .map<SharedMediaFile>((file) => SharedMediaFile.fromJson(file))
        .toList();
  }

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored link (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  static Future<Message?> getInitialText() async {
    final initialText = await _mChannel.invokeMethod('getInitialText');

    return initialText == null
        ? null
        : Message.fromMap(initialText);
  }

  /// Sets up a broadcast stream for receiving incoming media share change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([List]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialMedia` instead.
  static Stream<List<SharedMediaFile>> getMediaStream() {
    if (_streamMedia == null) {
      final stream =
      _eChannelMedia.receiveBroadcastStream("media").cast<String?>();
      _streamMedia = stream.transform<List<SharedMediaFile>>(
        new StreamTransformer<String?, List<SharedMediaFile>>.fromHandlers(
          handleData: (String? data, EventSink<List<SharedMediaFile>> sink) {
            if (data == null) {
              sink.add([]);
            } else {
              final encoded = jsonDecode(data);
              sink.add(encoded
                  .map<SharedMediaFile>(
                      (file) => SharedMediaFile.fromJson(file))
                  .toList());
            }
          },
        ),
      );
    }
    return _streamMedia!;
  }

  /// Sets up a broadcast stream for receiving incoming link change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([String]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialText` instead.
  static Stream<Message> getTextStream() {
    if (_streamLink == null) {
      _streamLink = _eChannelLink.receiveBroadcastStream("text")
          .cast<Map<Object?, Object?>>()
          .map(Message.fromMap);
    }
    return _streamLink!;
  }

  /// Call this method if you already consumed the callback
  /// and don't want the same callback again
  static void reset() {
    _mChannel.invokeMethod('reset').then((_) {});
  }
}

class SharedMediaFile {
  /// Image or Video path.
  /// NOTE. for iOS only the file is always copied
  final String path;

  /// Video thumbnail
  final String? thumbnail;

  /// Video duration in milliseconds
  final int? duration;

  /// Whether its a video or image or file
  final SharedMediaType type;

  SharedMediaFile(this.path, this.thumbnail, this.duration, this.type);

  SharedMediaFile.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        thumbnail = json['thumbnail'],
        duration = json['duration'],
        type = SharedMediaType.values[json['type']];
}

enum SharedMediaType { IMAGE, VIDEO, FILE }
