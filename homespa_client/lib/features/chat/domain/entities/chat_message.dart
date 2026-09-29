import 'dart:typed_data';

/// Delivery state of a message this client sent from this device.
enum ChatSendState { sent, sending, failed }

/// A `chat_messages` row, or an optimistic local copy while it is sending.
class ChatMessage {
  /// Server id, or a local `local-…` id until the insert returns.
  final String id;
  final String bookingId;
  final String senderId;

  /// Text, or a photo's caption; empty for a photo without one.
  final String body;

  /// Path in the private "chat-images" bucket, for photo messages.
  final String? imagePath;

  /// UTC.
  final DateTime createdAt;
  final DateTime? readAt;
  final ChatSendState sendState;

  /// Local only: the picked photo, shown while it uploads.
  final Uint8List? localImage;

  /// Local only: set once the photo is in storage, so a failed insert is
  /// retried without uploading again.
  final String? uploadedPath;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.imagePath,
    this.readAt,
    this.sendState = ChatSendState.sent,
    this.localImage,
    this.uploadedPath,
  });

  bool get isLocal => id.startsWith('local-');
  bool get isPhoto => imagePath != null || localImage != null;

  /// For previews and notifications: the text, or "Photo" without one.
  String get previewText => body.trim().isNotEmpty ? body : 'Photo';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'].toString(),
    bookingId: json['booking_id'] as String,
    senderId: json['sender_id'] as String,
    body: json['body'] as String? ?? '',
    imagePath: json['image_path'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    readAt: json['read_at'] == null
        ? null
        : DateTime.parse(json['read_at'] as String).toUtc(),
  );

  ChatMessage copyWith({ChatSendState? sendState, String? uploadedPath}) =>
      ChatMessage(
        id: id,
        bookingId: bookingId,
        senderId: senderId,
        body: body,
        imagePath: imagePath,
        createdAt: createdAt,
        readAt: readAt,
        sendState: sendState ?? this.sendState,
        localImage: localImage,
        uploadedPath: uploadedPath ?? this.uploadedPath,
      );
}
