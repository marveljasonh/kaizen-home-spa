import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Private bucket for chat photos: `{booking_id}/{uuid}.jpg`.
const String kChatImagesBucket = 'chat-images';

/// Signed URLs for private chat photos, cached in memory per image_path.
/// URLs last an hour and are refreshed 5 minutes early, or on demand after a
/// load failure.
class ChatImageUrls {
  ChatImageUrls._();

  static const Duration _ttl = Duration(hours: 1);
  static const Duration _margin = Duration(minutes: 5);

  static final Map<String, ({String url, DateTime expiresAt})> _cache = {};
  static final Map<String, Future<String>> _inFlight = {};

  static Future<String> get(String path, {bool refresh = false}) {
    final cached = _cache[path];
    if (!refresh &&
        cached != null &&
        DateTime.now().isBefore(cached.expiresAt.subtract(_margin))) {
      return Future.value(cached.url);
    }
    return _inFlight[path] ??= _sign(
      path,
    ).whenComplete(() => _inFlight.remove(path));
  }

  static Future<String> _sign(String path) async {
    final url = await Supabase.instance.client.storage
        .from(kChatImagesBucket)
        .createSignedUrl(path, _ttl.inSeconds);
    _cache[path] = (url: url, expiresAt: DateTime.now().add(_ttl));
    return url;
  }
}

/// Rounded photo in a chat bubble: the picked bytes while sending, else the
/// signed URL. Keeps the aspect ratio inside [maxWidth] × [maxHeight].
class ChatPhoto extends StatefulWidget {
  final String? imagePath;
  final Uint8List? localImage;
  final double maxWidth;
  final double maxHeight;
  final Color placeholderColor;
  final Color iconColor;

  /// Dims the photo with a spinner while it uploads.
  final bool uploading;
  final ValueChanged<ImageProvider>? onOpen;

  const ChatPhoto({
    super.key,
    required this.imagePath,
    required this.localImage,
    required this.maxWidth,
    required this.placeholderColor,
    required this.iconColor,
    this.maxHeight = 360,
    this.uploading = false,
    this.onOpen,
  });

  @override
  State<ChatPhoto> createState() => _ChatPhotoState();
}

class _ChatPhotoState extends State<ChatPhoto> {
  Future<String>? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ChatPhoto old) {
    super.didUpdateWidget(old);
    if (old.imagePath != widget.imagePath) _resolve();
  }

  void _resolve({bool refresh = false}) {
    final path = widget.imagePath;
    _url = path == null ? null : ChatImageUrls.get(path, refresh: refresh);
  }

  void _retry() => setState(() => _resolve(refresh: true));

  @override
  Widget build(BuildContext context) {
    final Widget content;
    final local = widget.localImage;
    if (local != null) {
      final provider = MemoryImage(local);
      content = _tappable(
        provider,
        Image(image: provider, fit: BoxFit.contain),
      );
    } else {
      content = FutureBuilder<String>(
        future: _url,
        builder: (context, snap) {
          if (snap.hasError) return _error();
          if (!snap.hasData) return _placeholder();
          // Cache by path, so a refreshed URL reuses the downloaded image.
          final provider = CachedNetworkImageProvider(
            snap.data!,
            cacheKey: widget.imagePath,
          );
          return _tappable(
            provider,
            Image(
              image: provider,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, sync) =>
                  frame == null && !sync ? _placeholder() : child,
              errorBuilder: (_, _, _) => _error(),
            ),
          );
        },
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            content,
            if (widget.uploading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tappable(ImageProvider provider, Widget image) => Semantics(
    image: true,
    button: widget.onOpen != null,
    label: 'Photo',
    child: GestureDetector(
      onTap: widget.onOpen == null ? null : () => widget.onOpen!(provider),
      child: image,
    ),
  );

  Widget _placeholder() => Container(
    width: widget.maxWidth,
    height: widget.maxWidth * 0.75,
    color: widget.placeholderColor,
    alignment: Alignment.center,
    child: SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(strokeWidth: 2, color: widget.iconColor),
    ),
  );

  Widget _error() => Container(
    width: widget.maxWidth,
    height: widget.maxWidth * 0.75,
    color: widget.placeholderColor,
    alignment: Alignment.center,
    child: TextButton.icon(
      onPressed: _retry,
      style: TextButton.styleFrom(
        foregroundColor: widget.iconColor,
        minimumSize: const Size(44, 44),
      ),
      icon: const Icon(Icons.broken_image_outlined),
      label: const Text('Tap to retry'),
    ),
  );
}

/// Full-screen photo: pinch to zoom, close button, swipe down to dismiss
/// (while not zoomed in).
Future<void> openChatPhotoViewer(BuildContext context, ImageProvider image) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _ChatPhotoViewer(image: image),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ChatPhotoViewer extends StatefulWidget {
  final ImageProvider image;
  const _ChatPhotoViewer({required this.image});

  @override
  State<_ChatPhotoViewer> createState() => _ChatPhotoViewerState();
}

class _ChatPhotoViewerState extends State<_ChatPhotoViewer> {
  final _transform = TransformationController();
  double _dragY = 0;
  bool _zoomed = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final fade = (1 - (_dragY.abs() / 400)).clamp(0.3, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: fade),
        body: Stack(
          children: [
            // Swipe down only while not zoomed; zoomed drags pan the photo.
            GestureDetector(
              onVerticalDragUpdate: _zoomed
                  ? null
                  : (d) => setState(() => _dragY += d.delta.dy),
              onVerticalDragEnd: _zoomed
                  ? null
                  : (d) {
                      if (_dragY.abs() > 120 ||
                          (d.primaryVelocity ?? 0).abs() > 900) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _dragY = 0);
                      }
                    },
              child: Transform.translate(
                offset: Offset(0, _dragY),
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 5,
                  panEnabled: _zoomed,
                  onInteractionEnd: _onInteractionEnd,
                  child: SizedBox.expand(
                    child: Image(image: widget.image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    tooltip: 'Close',
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// True on web, where only the gallery (file picker) is offered.
bool get chatCameraAvailable => !kIsWeb;
