import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../../../booking/presentation/providers/booking_providers.dart';
import '../../../treatments/presentation/widgets/glass_icon_button.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_photo.dart';

// In-app chat between the client and the therapist of one booking
// (chat_messages, RLS-scoped). #313129 header and input bar on a #434930
// body; sent bubbles white on the right, received bubbles glass on the left.
// Push notifications come from a DB trigger.

/// Dark chat palette, kept in one place so it can move into the app theme
/// tokens when the light/dark switch is added.
abstract final class _ChatColors {
  // Surfaces
  static const Color page = Color(0xFF434930);
  static const Color header = Color(0xFF313129);
  static const Color bar = Color(0xFF313129); // input bar, read-only notice
  static const Color sheet = Color(0xFF313129); // bottom sheets, dialogs
  static const Color divider = Color(0x26FFFFFF); // white 15%

  // Text on the page
  static const Color ink = Colors.white;
  static const Color muted = Color(0xB3FFFFFF); // white 70%
  static const Color hint = Color(0x99FFFFFF); // white 60%
  static const Color disabled = Color(0x59FFFFFF); // white 35%
  static const Color accent = Colors.white; // spinners, cursor, links, icons

  // Date chip
  static const Color chip = Color(0x1FFFFFFF); // white 12%
  static const Color chipText = Color(0xB3FFFFFF); // white 70%

  // Input
  static const Color field = Color(0x1AFFFFFF); // white 10%
  static const Color fieldBorder = Color(0x33FFFFFF); // white 20%
  static const Color fieldFocus = Colors.white;
  static const Color sendButton = Color(0xFF4E523B);

  // Bubbles
  static const Color sentBubble = Colors.white;
  static const Color onSent = Color(0xFF2C2C2A);
  static const Color onSentMeta = Color(0xFF6B6B68); // muted dark
  static const Color receivedBubble = Color(0x1AFFFFFF); // white 10%
  static const Color receivedBorder = Color(0x26FFFFFF); // white 15%
  static const Color onReceived = Colors.white;
  static const Color onReceivedMeta = Color(0x99FFFFFF); // white 60%
  static const Color photoPlaceholderSent = Color(0xFFEDE6D8);
  static const Color photoPlaceholderReceived = Color(0x14FFFFFF);

  static const Color error = Color(0xFFFFB4A8);
}

const String _kIconBack = 'assets/icons/chevron_left_33.svg';
const int _kPageSize = 50;
const int _kMaxLength = 1000;
const String _kColumns =
    'id, booking_id, sender_id, body, image_path, created_at, read_at';

/// Photos: long side ≤ 1600 px, JPEG ~80, at most 5 MB after compression.
const double _kPhotoMaxSide = 1600;
const int _kPhotoQuality = 80;
const int _kPhotoMaxBytes = 5 * 1024 * 1024;
const double _kGutter = 16;

/// Bookings in these states keep their chat history read-only.
const Set<String> _kClosedStatuses = {'completed', 'cancelled'};

class ChatPage extends ConsumerStatefulWidget {
  final String bookingId;
  const ChatPage({super.key, required this.bookingId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _client = Supabase.instance.client;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  RealtimeChannel? _channel;

  /// Newest first (index 0 is at the bottom of the reversed list).
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _loadError;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _foreground = true;

  String get _userId => _client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _input.addListener(() => setState(() {}));
    _subscribe();
    _loadLatest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final channel = _channel;
    if (channel != null) _client.removeChannel(channel);
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _markRead();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> _fetch({DateTime? before}) async {
    var query = _client
        .from('chat_messages')
        .select(_kColumns)
        .eq('booking_id', widget.bookingId);
    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await query
        .order('created_at', ascending: false)
        .limit(_kPageSize);
    return [
      for (final r in rows as List<dynamic>)
        ChatMessage.fromJson(r as Map<String, dynamic>),
    ];
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final latest = await _fetch();
      if (!mounted) return;
      setState(() {
        // Keep anything realtime delivered while loading.
        final ids = latest.map((m) => m.id).toSet();
        final extra = _messages.where((m) => !ids.contains(m.id));
        _messages
          ..clear()
          ..addAll([...extra, ...latest]);
        _sortNewestFirst();
        _hasMore = latest.length == _kPageSize;
        _loading = false;
      });
      _markRead();
    } catch (e) {
      debugPrint('[Chat] load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'We couldn’t load this chat.';
        });
      }
    }
  }

  Future<void> _loadOlder() async {
    final oldest = _messages.lastWhere(
      (m) => !m.isLocal,
      orElse: () => _messages.last,
    );
    setState(() => _loadingMore = true);
    try {
      final older = await _fetch(before: oldest.createdAt);
      if (!mounted) return;
      setState(() {
        final ids = _messages.map((m) => m.id).toSet();
        _messages.addAll(older.where((m) => !ids.contains(m.id)));
        _sortNewestFirst();
        _hasMore = older.length == _kPageSize;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('[Chat] load older error: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    // Reversed list: scrolling up moves towards maxScrollExtent.
    if (!_hasMore || _loadingMore || _loading || _messages.isEmpty) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadOlder();
    }
  }

  void _sortNewestFirst() =>
      _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _subscribe() {
    _channel = _client
        .channel('chat:${widget.bookingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: widget.bookingId,
          ),
          callback: (payload) => _onRemoteInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: widget.bookingId,
          ),
          callback: (payload) => _onRemoteUpdate(payload.newRecord),
        )
        .subscribe((status, error) {
          if (error != null) debugPrint('[Chat] realtime $status: $error');
        });
  }

  void _onRemoteInsert(Map<String, dynamic> row) {
    if (!mounted || row.isEmpty) return;
    final message = ChatMessage.fromJson(row);
    setState(() {
      if (_messages.any((m) => m.id == message.id)) return;
      // Our own message can arrive here before the insert call returns:
      // replace the matching optimistic copy instead of showing it twice.
      if (message.senderId == _userId) {
        final local = _messages.indexWhere(
          (m) =>
              m.isLocal &&
              m.sendState == ChatSendState.sending &&
              (message.imagePath != null
                  ? m.uploadedPath == message.imagePath
                  : m.localImage == null && m.body == message.body),
        );
        if (local != -1) _messages.removeAt(local);
      }
      _messages.add(message);
      _sortNewestFirst();
    });
    if (message.senderId != _userId) {
      _markRead();
      _scrollToNewestIfNear();
    }
  }

  void _onRemoteUpdate(Map<String, dynamic> row) {
    if (!mounted || row.isEmpty) return;
    final message = ChatMessage.fromJson(row);
    final i = _messages.indexWhere((m) => m.id == message.id);
    if (i != -1) setState(() => _messages[i] = message);
  }

  /// Sets read_at on the therapist's unread messages (read_at only).
  Future<void> _markRead() async {
    if (!_foreground || _userId.isEmpty) return;
    final hasUnread = _messages.any(
      (m) => !m.isLocal && m.senderId != _userId && m.readAt == null,
    );
    if (!hasUnread) return;
    try {
      await _client
          .from('chat_messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('booking_id', widget.bookingId)
          .neq('sender_id', _userId)
          .isFilter('read_at', null);
    } catch (e) {
      debugPrint('[Chat] mark read error: $e');
    }
  }

  // ── Sending ────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _userId.isEmpty) return;
    final text = body.length > _kMaxLength
        ? body.substring(0, _kMaxLength)
        : body;
    final local = ChatMessage(
      id: 'local-${const Uuid().v4()}',
      bookingId: widget.bookingId,
      senderId: _userId,
      body: text,
      createdAt: DateTime.now().toUtc(),
      sendState: ChatSendState.sending,
    );
    _input.clear();
    setState(() => _messages.insert(0, local));
    _scrollToNewest();
    await _deliver(local);
  }

  /// Text: insert. Photo: upload once (kept in [ChatMessage.uploadedPath]),
  /// then insert; a retry after a failed insert skips the upload.
  Future<void> _deliver(ChatMessage local) async {
    var message = local;
    try {
      if (message.localImage != null && message.uploadedPath == null) {
        final path = '${message.bookingId}/${const Uuid().v4()}.jpg';
        await _client.storage
            .from(kChatImagesBucket)
            .uploadBinary(
              path,
              message.localImage!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        message = message.copyWith(uploadedPath: path);
        _replaceLocal(message);
      }
      final row = await _client
          .from('chat_messages')
          .insert({
            'booking_id': message.bookingId,
            'sender_id': message.senderId,
            'body': message.body.isEmpty ? null : message.body,
            if (message.uploadedPath != null)
              'image_path': message.uploadedPath,
          })
          .select(_kColumns)
          .single();
      if (!mounted) return;
      final saved = ChatMessage.fromJson(row);
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
        // Realtime may already have added it.
        if (!_messages.any((m) => m.id == saved.id)) _messages.add(saved);
        _sortNewestFirst();
      });
    } catch (e) {
      debugPrint('[Chat] send error: $e');
      if (!mounted) return;
      _replaceLocal(message.copyWith(sendState: ChatSendState.failed));
    }
  }

  void _replaceLocal(ChatMessage message) {
    if (!mounted) return;
    final i = _messages.indexWhere((m) => m.id == message.id);
    if (i != -1) setState(() => _messages[i] = message);
  }

  void _retry(ChatMessage failed) {
    final i = _messages.indexWhere((m) => m.id == failed.id);
    if (i == -1) return;
    final retrying = failed.copyWith(sendState: ChatSendState.sending);
    setState(() => _messages[i] = retrying);
    _deliver(retrying);
  }

  /// Discards an unsent message; an already-uploaded photo is removed from
  /// storage so it isn't orphaned.
  void _discard(ChatMessage failed) {
    setState(() => _messages.removeWhere((m) => m.id == failed.id));
    final path = failed.uploadedPath;
    if (path != null) {
      _client.storage.from(kChatImagesBucket).remove([path]).catchError((e) {
        debugPrint('[Chat] remove orphaned photo error: $e');
        return <FileObject>[];
      });
    }
  }

  // ── Photos ─────────────────────────────────────────────────────────────────

  Future<void> _attachPhoto() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _ChatColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null || !mounted) return;

    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: _kPhotoMaxSide,
        maxHeight: _kPhotoMaxSide,
        imageQuality: _kPhotoQuality,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      debugPrint('[Chat] pick error: ${e.code} ${e.message}');
      if (!mounted) return;
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        _showPermissionDenied(camera: e.code == 'camera_access_denied');
      } else {
        _snack(
          'Couldn’t open ${source == ImageSource.camera ? 'the camera' : 'your photos'}.',
        );
      }
      return;
    }
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > _kPhotoMaxBytes) {
      _snack(
        'That photo is too large (over 5 MB). Please choose a smaller one.',
      );
      return;
    }

    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ChatColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PhotoPreviewSheet(bytes: bytes),
    );
    // null = Cancel (discard); '' = send without a caption.
    if (caption == null || !mounted || _userId.isEmpty) return;

    final local = ChatMessage(
      id: 'local-${const Uuid().v4()}',
      bookingId: widget.bookingId,
      senderId: _userId,
      body: caption,
      createdAt: DateTime.now().toUtc(),
      sendState: ChatSendState.sending,
      localImage: bytes,
    );
    setState(() => _messages.insert(0, local));
    _scrollToNewest();
    await _deliver(local);
  }

  void _showPermissionDenied({required bool camera}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ChatColors.sheet,
        title: Text(
          camera ? 'Camera access is off' : 'Photo access is off',
          style: flowHeading(20, color: _ChatColors.ink),
        ),
        content: Text(
          camera
              ? 'Allow camera access in Settings to take a photo for this chat.'
              : 'Allow photo access in Settings to send a photo in this chat.',
          style: flowBody(14, color: _ChatColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: _ChatColors.muted),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: TextButton.styleFrom(foregroundColor: _ChatColors.accent),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Follow new incoming messages unless the user has scrolled up to read.
  void _scrollToNewestIfNear() {
    if (_scroll.hasClients && _scroll.position.pixels < 120) _scrollToNewest();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(chatBookingInfoProvider(widget.bookingId));
    final info = infoAsync.value;
    // Live status (e.g. the booking completes while the chat is open).
    final liveStatus =
        ref
                .watch(bookingDetailStreamProvider(widget.bookingId))
                .value?['status']
            as String?;
    final status = liveStatus ?? info?.status;
    final readOnly = status != null && _kClosedStatuses.contains(status);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar and navigation-bar icons over the dark header and
      // input bar.
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: _ChatColors.bar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: _ChatColors.accent,
            selectionHandleColor: _ChatColors.accent,
          ),
        ),
        child: Scaffold(
          backgroundColor: _ChatColors.page,
          body: Column(
            children: [
              _ChatHeader(
                name: info?.therapistName ?? 'Therapist',
                avatarUrl: info?.therapistAvatarUrl,
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/bookings/${widget.bookingId}'),
              ),
              Expanded(child: _buildMessages(info?.therapistName)),
              if (readOnly)
                _ClosedNotice(status: status)
              else
                _InputBar(
                  controller: _input,
                  enabled: !_loading && _loadError == null,
                  onSend: _send,
                  onAttach: _attachPhoto,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(String? therapistName) {
    if (_loading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _ChatColors.accent),
      );
    }
    if (_loadError != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, style: flowBody(14, color: _ChatColors.muted)),
            TextButton(
              onPressed: _loadLatest,
              style: TextButton.styleFrom(foregroundColor: _ChatColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return _EmptyChat(name: therapistName ?? 'your therapist');
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(_kGutter, 12, _kGutter, 12),
        itemCount: _messages.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _ChatColors.accent,
                  ),
                ),
              ),
            );
          }
          final m = _messages[i];
          // The list is reversed: the next-older message is at i + 1.
          final older = i + 1 < _messages.length ? _messages[i + 1] : null;
          final newDay =
              older == null || !_sameWibDay(older.createdAt, m.createdAt);
          // 4 between messages from the same sender, 12 when it changes;
          // a date separator brings its own spacing.
          final gap = newDay
              ? 0.0
              : older.senderId == m.senderId
              ? 4.0
              : 12.0;
          final mine = m.senderId == _userId;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay) _DaySeparator(m.createdAt),
              Padding(
                padding: EdgeInsets.only(top: gap),
                // Full-width row: only the bubble moves left or right.
                child: Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: _Bubble(
                    message: m,
                    mine: mine,
                    onRetry: () => _retry(m),
                    onDiscard: () => _discard(m),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _sameWibDay(DateTime a, DateTime b) {
  final x = WIB.toWIB(a);
  final y = WIB.toWIB(b);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onBack;

  const _ChatHeader({
    required this.name,
    required this.avatarUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ChatColors.header, // #313129
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kFlowGutter, 12, kFlowGutter, 16),
          child: Row(
            children: [
              GlassIconButton(
                svgAsset: _kIconBack,
                iconSize: 33,
                iconOffset: const Offset(6.5, 8.5),
                onTap: onBack,
              ),
              const SizedBox(width: 14),
              _Avatar(name: name, url: avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: flowHeading(20, height: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your therapist',
                      style: flowBody(12, color: kFlowMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  const _Avatar({required this.name, required this.url});

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      width: _size,
      height: _size,
      color: AppColors.darkOliveLight,
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty
            ? '?'
            : name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .take(2)
                  .map((w) => w[0])
                  .join()
                  .toUpperCase(),
        style: flowHeading(16),
      ),
    );
    final link = url?.trim() ?? '';
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: ClipOval(
        child: link.isEmpty
            ? initials
            : CachedNetworkImage(
                imageUrl: link,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                placeholder: (_, _) => initials,
                errorWidget: (_, _, _) => initials,
              ),
      ),
    );
  }
}

// ── Messages ──────────────────────────────────────────────────────────────────

/// Sent: white with dark text, right. Received: glass with white text, left.
class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const _Bubble({
    required this.message,
    required this.mine,
    required this.onRetry,
    required this.onDiscard,
  });

  static const Radius _r = Radius.circular(18);
  static const Radius _tail = Radius.circular(4);

  @override
  Widget build(BuildContext context) {
    final failed = message.sendState == ChatSendState.failed;
    final sending = message.sendState == ChatSendState.sending;
    final ink = mine ? _ChatColors.onSent : _ChatColors.onReceived;
    final meta = mine ? _ChatColors.onSentMeta : _ChatColors.onReceivedMeta;
    final screen = MediaQuery.sizeOf(context).width;
    final photo = message.isPhoto;
    final caption = message.body.trim();

    final timeRow = Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            WIB.formatTime(message.createdAt),
            style: flowBody(10.5, color: meta),
          ),
          // Time only on received bubbles; time + tick on sent.
          if (mine) ...[
            const SizedBox(width: 4),
            Icon(
              sending
                  ? Icons.schedule_rounded
                  : failed
                  ? Icons.error_outline_rounded
                  : message.readAt != null
                  ? Icons.done_all_rounded
                  : Icons.done_rounded,
              size: 14,
              color: meta,
            ),
          ],
        ],
      ),
    );

    // Content-sized up to 75% of the screen; long text wraps inside.
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: screen * 0.75),
      child: Container(
        padding: photo
            ? const EdgeInsets.fromLTRB(4, 4, 4, 8)
            : const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? _ChatColors.sentBubble : _ChatColors.receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: _r,
            topRight: _r,
            bottomLeft: mine ? _r : _tail,
            bottomRight: mine ? _tail : _r,
          ),
          border: mine ? null : Border.all(color: _ChatColors.receivedBorder),
        ),
        // As wide as the widest of photo, text and time row, so the time
        // sits bottom right and short text stays left-aligned.
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photo)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ChatPhoto(
                    imagePath: message.imagePath,
                    localImage: message.localImage,
                    maxWidth: screen * 0.65,
                    uploading: sending,
                    placeholderColor: mine
                        ? _ChatColors.photoPlaceholderSent
                        : _ChatColors.photoPlaceholderReceived,
                    iconColor: mine
                        ? _ChatColors.onSentMeta
                        : _ChatColors.onReceivedMeta,
                    onOpen: (image) => openChatPhotoViewer(context, image),
                  ),
                ),
              if (caption.isNotEmpty)
                Padding(
                  padding: photo
                      ? const EdgeInsets.fromLTRB(10, 8, 10, 0)
                      : EdgeInsets.zero,
                  child: Text(
                    message.body,
                    style: flowBody(14.5, color: ink, height: 1.35),
                  ),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: photo
                    ? const EdgeInsets.symmetric(horizontal: 10)
                    : EdgeInsets.zero,
                child: timeRow,
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Opacity(opacity: sending && !photo ? 0.7 : 1, child: bubble),
        if (failed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FailedAction(
                icon: Icons.refresh_rounded,
                label: 'Not sent · Retry',
                semantics: 'Message not sent. Tap to retry.',
                onTap: onRetry,
              ),
              _FailedAction(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                semantics: 'Delete unsent message',
                onTap: onDiscard,
              ),
            ],
          ),
      ],
    );
  }
}

/// 44-tall text action under a failed bubble.
class _FailedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  const _FailedAction({
    required this.icon,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _ChatColors.error),
              const SizedBox(width: 4),
              Text(label, style: flowBody(12, color: _ChatColors.error)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// "Today" / "Yesterday" / "12 Sep 2026", by WIB calendar day.
class _DaySeparator extends StatelessWidget {
  final DateTime utc;
  const _DaySeparator(this.utc);

  @override
  Widget build(BuildContext context) {
    final day = WIB.toWIB(utc);
    final today = WIB.now();
    final yesterday = today.subtract(const Duration(days: 1));
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final label = same(day, today)
        ? 'Today'
        : same(day, yesterday)
        ? 'Yesterday'
        : DateFormat('d MMM y').format(day);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _ChatColors.chip,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: flowBody(11.5, color: _ChatColors.chipText),
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 48,
              color: _ChatColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              'No messages yet',
              textAlign: TextAlign.center,
              style: flowHeading(22, color: _ChatColors.ink, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello to $name, or share anything they should know '
              'before your treatment.',
              textAlign: TextAlign.center,
              style: flowBody(13, color: _ChatColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input ─────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    final canSend = enabled && controller.text.trim().isNotEmpty;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(kFlowRadius),
      borderSide: const BorderSide(color: _ChatColors.fieldBorder),
    );

    return Container(
      decoration: const BoxDecoration(
        color: _ChatColors.bar,
        border: Border(top: BorderSide(color: _ChatColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kGutter, 10, _kGutter, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (length > _kMaxLength - 100)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 58),
                  child: Text(
                    '$length / $_kMaxLength',
                    style: flowBody(
                      11,
                      color: length >= _kMaxLength
                          ? _ChatColors.error
                          : _ChatColors.muted,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach a photo (camera / gallery).
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      tooltip: 'Send a photo',
                      onPressed: enabled ? onAttach : null,
                      icon: const Icon(Icons.photo_camera_outlined),
                      color: _ChatColors.accent,
                      disabledColor: _ChatColors.disabled,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_kMaxLength),
                      ],
                      style: flowBody(14.5, color: _ChatColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Write a message…',
                        hintStyle: flowBody(14.5, color: _ChatColors.hint),
                        filled: true,
                        fillColor: _ChatColors.field,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: fieldBorder,
                        enabledBorder: fieldBorder,
                        disabledBorder: fieldBorder,
                        focusedBorder: fieldBorder.copyWith(
                          borderSide: const BorderSide(
                            color: _ChatColors.fieldFocus,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    enabled: canSend,
                    child: Material(
                      color: canSend
                          ? _ChatColors.sendButton
                          : _ChatColors.sendButton.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: canSend ? onSend : null,
                        child: const SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replaces the input once the booking is completed or cancelled.
class _ClosedNotice extends StatelessWidget {
  final String status;
  const _ClosedNotice({required this.status});

  @override
  Widget build(BuildContext context) {
    final what = status == 'cancelled' ? 'cancelled' : 'completed';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _ChatColors.bar,
        border: Border(top: BorderSide(color: _ChatColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kGutter, 14, _kGutter, 14),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: _ChatColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This booking is $what, so the chat is read-only.',
                  style: flowBody(13, color: _ChatColors.muted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo sheets ──────────────────────────────────────────────────────────────

/// "Take Photo" / "Choose from Gallery". Web only offers the gallery (file
/// picker), since image_picker can't open the camera reliably there.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    Widget option(IconData icon, String label, ImageSource source) => ListTile(
      minTileHeight: 56,
      leading: Icon(icon, color: _ChatColors.accent),
      title: Text(label, style: flowBody(15, color: _ChatColors.ink)),
      onTap: () => Navigator.of(context).pop(source),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chatCameraAvailable)
              option(
                Icons.photo_camera_outlined,
                'Take Photo',
                ImageSource.camera,
              ),
            option(
              Icons.photo_library_outlined,
              'Choose from Gallery',
              ImageSource.gallery,
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview with an optional caption. Pops the caption ('' for none) on Send,
/// or null on Cancel.
class _PhotoPreviewSheet extends StatefulWidget {
  final Uint8List bytes;
  const _PhotoPreviewSheet({required this.bytes});

  @override
  State<_PhotoPreviewSheet> createState() => _PhotoPreviewSheetState();
}

class _PhotoPreviewSheetState extends State<_PhotoPreviewSheet> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(kFlowRadius),
      borderSide: const BorderSide(color: _ChatColors.fieldBorder),
    );
    final radius = BorderRadius.circular(kFlowRadius);

    return Padding(
      // Stay above the keyboard while typing the caption.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kGutter, 16, _kGutter, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send photo',
                style: flowHeading(20, color: _ChatColors.ink),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: _ChatColors.chip,
                    child: Image.memory(widget.bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _caption,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_kMaxLength),
                ],
                style: flowBody(14.5, color: _ChatColors.ink),
                decoration: InputDecoration(
                  hintText: 'Add a caption (optional)',
                  hintStyle: flowBody(14.5, color: _ChatColors.hint),
                  filled: true,
                  fillColor: _ChatColors.field,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: const BorderSide(color: _ChatColors.fieldFocus),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: _ChatColors.ink,
                        side: const BorderSide(color: _ChatColors.fieldBorder),
                        shape: RoundedRectangleBorder(borderRadius: radius),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_caption.text.trim()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: _ChatColors.sendButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: radius),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
