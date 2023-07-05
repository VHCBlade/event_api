import 'package:event_api/event_api.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAPIRequester', () {
    test('Fail', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = FakeAPIRequester(
        fakeRequestMap: {},
      );

      final repository = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final response =
          await repository.request('POST', 'login', (request) => null);

      expect(response.statusCode, 500);
    });
    test('Login', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = FakeAPIRequester(
        fakeRequestMap: {
          'login': (request) async => StreamedResponse(
                Stream.value([]),
                200,
                headers: {}..authorization = await JWTSigner(
                    () => 'cool',
                    issuer: 'example.com',
                  ).createToken(BaseJWT()..expiry = const Duration(hours: 5)),
              ),
          'loggedIn': (request) async => StreamedResponse(
                Stream.value(request.headers.authorization!.codeUnits),
                200,
              )
        },
      );

      final repository = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final response =
          await repository.request('POST', 'login', (request) => null);

      expect(response.statusCode, 200);
      final jwt = await repository.jwt;
      expect(jwt!.jwt.expiry, const Duration(hours: 5));

      final loggedInResponse =
          await repository.request('POST', 'loggedIn', (request) => null);

      final loggedInData = await loggedInResponse.body;
      final returnedData = BaseJWT.fromToken(loggedInData);

      expect(returnedData.expiry, const Duration(hours: 5));

      await repository.logout();
      expect(await repository.jwt, null);
    });
  });
}
