class Message {

  String? text;
  String? subject;

  Message({required this.text, required this.subject});

  static Message fromMap(Map<Object?, Object?> map) {

    return Message(
        text: map["text"] as String?,
        subject: map["subject"] as String?);
  }
}