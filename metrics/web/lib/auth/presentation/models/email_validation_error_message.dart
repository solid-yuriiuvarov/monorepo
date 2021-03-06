import 'package:metrics/auth/presentation/strings/auth_strings.dart';
import 'package:metrics_core/metrics_core.dart';

/// A class that provides the email validation error description
/// based on [EmailValidationErrorCode].
class EmailValidationErrorMessage {
  /// A [EmailValidationErrorCode] provides an information
  /// of concrete email validation error.
  final EmailValidationErrorCode _code;

  /// Creates the [EmailValidationErrorMessage] with the given [EmailValidationErrorCode].
  const EmailValidationErrorMessage(this._code);

  /// Provides the email validation error message based on the [EmailValidationErrorCode].
  String get message {
    switch (_code) {
      case EmailValidationErrorCode.isNull:
        return AuthStrings.emailRequiredErrorMessage;
      case EmailValidationErrorCode.invalidEmailFormat:
        return AuthStrings.invalidEmailErrorMessage;
      default:
        return null;
    }
  }
}
