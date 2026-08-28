/// End-user identity attached to a single posted feedback entry.
class User {
  const User({this.id, this.name, this.email});

  /// Your company-defined user id.
  final String? id;

  /// Name or alias for the user.
  final String? name;

  /// Reachable email for the user.
  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.name == name &&
          other.email == email;

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
