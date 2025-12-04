enum MessageRole {
  user,
  assistant,
  system;

  String toJson() => name;
  static MessageRole fromJson(String json) => values.byName(json);
}
