// login
class IncorrectCredentialsAuthException implements Exception{}

// is no longer supported due to security
// class UserNotFoundAuthException implements Exception{}

// register
class EmailAlreadyInUseAuthException implements Exception{}

class WeakPasswordAuthException implements Exception{}

class InvalidEmailAuthException implements Exception{}

// generic
class GenericAuthException implements Exception{}

class UserNotLoggedInAuthException implements Exception{}