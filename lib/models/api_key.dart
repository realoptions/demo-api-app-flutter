class ApiKey {
  final int id;
  final String key;
  ApiKey({this.id, this.key});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key
    };
  }
}