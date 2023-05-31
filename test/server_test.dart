import 'package:event_api/event_api.dart';
import 'package:event_api/src/response.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:test/test.dart';

void main() {
  group('ServerAPIRequester', () {
    test('Fail', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = ServerAPIRequester(
        apiServer: 'https://test.vhcblade.com/',
        website: 'https://test.vhcblade.com/',
      );

      final repository = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final response =
          await repository.request('POST', 'amazing', (request) => null);

      expect(response.statusCode, 404);
      expect(await response.body, 'Route not found');
    });
    test('Login', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = ServerAPIRequester(
        apiServer: 'https://test.vhcblade.com/',
        website: 'https://test.vhcblade.com/',
      );

      final repository = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final response = await repository.request(
        'POST',
        'login/email',
        (request) => request.body = (EmailLoginRequest()
              ..email = 'example@example.com'
              ..password = 'example')
            .toJsonString(),
      );

      expect(response.statusCode, 200);
      final jwt = await repository.jwt;
      expect(jwt!.jwt.expiry, const Duration(hours: 2));

      await repository.request(
        'POST',
        'authenticated',
        (request) => null,
      );

      final newJwt = await repository.jwt;
      expect(newJwt!.jwt.expiry, const Duration(hours: 2));
      expect(
        newJwt.jwt.dateIssued.microsecondsSinceEpoch,
        isNot(jwt.jwt.dateIssued.microsecondsSinceEpoch),
      );
    });
    test('No Server', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = ServerAPIRequester(
        apiServer: 'https://imaginary.vhcblade.com/',
        website: 'https://imaginary.vhcblade.com/',
      );

      final repository = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final response = await repository.request(
        'POST',
        'login/email',
        (request) => request.body = (EmailLoginRequest()
              ..email = 'example@example.com'
              ..password = 'example')
            .toJsonString(),
      );

      expect(response.statusCode, 504);
    });
  });
}
