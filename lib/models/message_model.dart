class MessageModel {
  final String id;
  final String sender;
  final String? receiver;
  final String? group;
  final String? text;
  final String? fileUrl;
  final String? fileType;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.sender,
    this.receiver,
    this.group,
    this.text,
    this.fileUrl,
    this.fileType,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      sender: json['sender'] ?? '',
      receiver: json['receiver'],
      group: json['group'],
      text: json['text'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}