// lib/src/core/errors/failures.dart

/// Clase abstracta base para todos los errores de la aplicación
abstract class Failure {
  final String message;
  
  const Failure(this.message);
  
  @override
  String toString() => message;
}

/// Error de validación (datos inválidos)
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Error de caché/almacenamiento local
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Error del servidor/operaciones de I/O
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Error de permisos
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Error de archivo no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Error genérico
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message) : super(message);
}