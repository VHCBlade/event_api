import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:tuple/tuple.dart';

/// This represents a JWT that has been retrieved from a server. This helps
/// preserve the tokenized version of the JWT.
class EncodedJWT extends GenericModel {
  /// Default Constructor
  EncodedJWT();

  /// Creates a new EncodedJWT with its [token] value set to [token].
  factory EncodedJWT.fromToken(String token) => EncodedJWT()..token = token;

  /// Converts [token] into a [BaseJWT] for easier use.
  BaseJWT get jwt => BaseJWT.fromToken(token);

  /// The token that represents the jwt.
  late String token;

  @override
  Map<String, Tuple2<Getter<dynamic>, Setter<dynamic>>> getGetterSetterMap() =>
      {
        'token': Tuple2(() => token, (val) => token = '$val'),
      };

  @override
  String get type => 'EncodedJWT';
}
