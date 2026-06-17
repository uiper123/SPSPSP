abstract class TokenStorage {
  Future<void> writeToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();
}
