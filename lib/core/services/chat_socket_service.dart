import "dart:async";
import "dart:convert";

import "package:web_socket_channel/web_socket_channel.dart";

import "../config/env.dart";

typedef ChatSocketMessageCallback = void Function(Map<String, dynamic> message);

/// Manages a WebSocket connection to a single chat thread.
///
/// - Fires [onNewMessage] for every `new_message` event pushed by the server.
/// - Fires [onRemoteTyping] when the other participant's typing state changes.
///   The typing indicator is auto-cleared after 3 s with no update.
/// - Reconnects automatically with exponential back-off (up to 6 retries).
class ChatSocketService {
  final String threadId;
  final String accessToken;
  final ChatSocketMessageCallback onNewMessage;
  final void Function(bool isTyping)? onRemoteTyping;

  static const int _maxRetries = 6;
  static const Duration _typingClearDelay = Duration(seconds: 3);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _typingTimer;
  int _retries = 0;
  bool _closed = false;

  ChatSocketService({
    required this.threadId,
    required this.accessToken,
    required this.onNewMessage,
    this.onRemoteTyping,
  });

  // ── URL derivation ─────────────────────────────────────────────────────────

  static String _wsBaseUrl() {
    try {
      final base = Env.baseUrl; // e.g. https://api.inotra.rw/ or http://localhost:8000/
      final uri = Uri.parse(base);
      final scheme = uri.scheme == "https" ? "wss" : "ws";
      final portSuffix = uri.hasPort &&
              uri.port != 80 &&
              uri.port != 443
          ? ":${uri.port}"
          : "";
      return "$scheme://${uri.host}$portSuffix";
    } catch (_) {
      return "ws://localhost:8000";
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Opens the connection (or re-opens after a [disconnect]).
  void connect() {
    _closed = false;
    _retries = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_closed) return;
    _sub?.cancel();
    _sub = null;
    try {
      final token = Uri.encodeComponent(accessToken);
      final url = "${_wsBaseUrl()}/ws/chat/threads/$threadId/?token=$token";
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sub = _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Closes the connection permanently. Call [connect] to restart.
  void disconnect() {
    _closed = true;
    _reconnectTimer?.cancel();
    _typingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close(1000);
    _channel = null;
    _sub = null;
  }

  // ── Sending ────────────────────────────────────────────────────────────────

  /// Broadcasts the local user's typing state to the other participant.
  void sendTyping(bool isTyping) {
    try {
      _channel?.sink
          .add(jsonEncode({"type": "typing", "is_typing": isTyping}));
    } catch (_) {}
  }

  // ── Internal handlers ──────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    if (_closed) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data["type"] as String?;

      if (type == "new_message") {
        final msg = data["message"];
        if (msg is Map<String, dynamic>) onNewMessage(msg);
      } else if (type == "typing") {
        final isTyping = data["is_typing"] as bool? ?? false;
        _typingTimer?.cancel();
        onRemoteTyping?.call(isTyping);
        if (isTyping) {
          _typingTimer = Timer(_typingClearDelay, () {
            if (!_closed) onRemoteTyping?.call(false);
          });
        }
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _onDone() {
    if (_closed) return;
    _channel = null;
    _sub = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed || _retries >= _maxRetries) return;
    final delayMs = 1000 * (1 << _retries); // 1 s, 2 s, 4 s, 8 s, 16 s, 32 s
    _retries++;
    _reconnectTimer?.cancel();
    _reconnectTimer =
        Timer(Duration(milliseconds: delayMs), _doConnect);
  }
}
