// login
class IncorrectCredentialsAuthException implements Exception{}

// register
class EmailAlreadyInUseAuthException implements Exception{}

class WeakPasswordAuthException implements Exception{}

class InvalidEmailAuthException implements Exception{}

// generic
class GenericAuthException implements Exception{}

class UserNotLoggedInAuthException implements Exception{}