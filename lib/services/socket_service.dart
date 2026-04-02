import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void connect(String token) {
    socket = IO.io(Constants.socketUrl, {
      'transports': ['websocket'],
      'query': {'token': token},
      'autoConnect': true,
    });

    socket!.onConnect((_) => print('Socket connected'));
    socket!.onDisconnect((_) => print('Socket disconnected'));
    socket!.onConnectError((err) => print('Socket error: $err'));
  }

  void disconnect() {
    socket?.disconnect();
  }

  void sendMessage(Map<String, dynamic> data) {
    socket?.emit('send_message', data);
  }

  void onReceiveMessage(Function(dynamic) callback) {
    socket?.on('receive_message', callback);
  }

  void onTypingStart(Function(dynamic) callback) {
    socket?.on('typing_start', callback);
  }

  void onTypingStop(Function(dynamic) callback) {
    socket?.on('typing_stop', callback);
  }

  void emitTypingStart(String receiverId) {
    socket?.emit('typing_start', {'receiverId': receiverId});
  }

  void emitTypingStop(String receiverId) {
    socket?.emit('typing_stop', {'receiverId': receiverId});
  }

  void joinRoom(String groupId) {
    socket?.emit('join_room', groupId);
  }

  void removeListener(String event) {
    socket?.off(event);
  }
}