import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  final String targetId;
  final String targetName;
  final String currentUserId;
  final bool isCaller;
  final dynamic offer;
  final String callType;
  final String? callId;

  const CallScreen({
    super.key,
    required this.targetId,
    required this.targetName,
    required this.currentUserId,
    required this.isCaller,
    this.offer,
    this.callType = 'video',
    this.callId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _socketService = SocketService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _callId;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _callConnected = false;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _setupPeerConnection();
    if (widget.isCaller) {
      await _startCall();
    } else {
      await _answerCall();
    }
  }

  Future<void> _setupPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // Get local media
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.callType == 'video',
    });

    _localRenderer.srcObject = _localStream;

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Remote stream
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
          _callConnected = true;
        });
      }
    };

    // ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      _socketService.socket?.emit('ice_candidate', {
        'targetId': widget.targetId,
        'candidate': candidate.toMap(),
      });
    };

    // Listen for remote ICE candidates
    _socketService.socket?.on('ice_candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    });

    // Listen for call end
    _socketService.socket?.on('call_end', (data) {
      _endCall();
    });

    // Listen for call rejected
    _socketService.socket?.on('call_rejected', (data) {
      _endCall();
    });
  }

  Future<void> _startCall() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.socket?.emit('call_offer', {
      'calleeId': widget.targetId,
      'offer': offer.toMap(),
      'callType': widget.callType,
    });

    // Listen for answer
    _socketService.socket?.on('call_answer', (data) async {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
      setState(() => _callId = data['callId']?.toString());
    });
  }

  Future<void> _answerCall() async {
    _callId = widget.callId;
    final offer = RTCSessionDescription(
      widget.offer['sdp'],
      widget.offer['type'],
    );
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.socket?.emit('call_answer', {
      'callerId': widget.targetId,
      'answer': answer.toMap(),
      'callId': _callId,
    });

    setState(() => _callConnected = true);
  }

  void _endCall() {
    _socketService.socket?.emit('call_end', {
      'targetId': widget.targetId,
      'callId': _callId,
    });
    _cleanup();
    if (mounted) Navigator.pop(context);
  }

  void _cleanup() {
    _socketService.socket?.off('call_answer');
    _socketService.socket?.off('ice_candidate');
    _socketService.socket?.off('call_end');
    _socketService.socket?.off('call_rejected');
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_isMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_isCameraOff);
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          Positioned.fill(
            child: _callConnected
                ? RTCVideoView(_remoteRenderer)
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6C63FF),
                    child: Text(
                      widget.targetName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.targetName,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isCaller ? 'Calling...' : 'Incoming call...',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Local video (picture-in-picture)
          if (widget.callType == 'video')
            Positioned(
              top: 40,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _isMuted ? Colors.white : Colors.white24,
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.black : Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),
                ),
                // End call
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white, size: 30),
                    onPressed: _endCall,
                  ),
                ),
                // Camera toggle
                if (widget.callType == 'video')
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _isCameraOff ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        color: _isCameraOff ? Colors.black : Colors.white,
                      ),
                      onPressed: _toggleCamera,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}