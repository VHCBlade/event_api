import 'dart:convert';

import 'package:event_api/event_api.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('ApiDatabaseRepository', () {
    test('Missing Constructor', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = createUnreachableRequester();

      final api = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final apiDatabase = ApiDatabaseRepository(
        apiRepository: api,
        baseURL: 'unreachable',
        constructors: {EncodedJWT: EncodedJWT.new},
      );
      expect(
        () => apiDatabase.getInstance<EmailLoginRequest>(),
        throwsArgumentError,
      );
    });
    test('Unreachable', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = createUnreachableRequester();

      final api = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final apiDatabase = ApiDatabaseRepository(
        apiRepository: api,
        baseURL: 'unreachable',
        constructors: {EmailLoginRequest: EmailLoginRequest.new},
      );
      var i = 0;
      apiDatabase.errorStream.stream.listen((_) => i++);

      expect(
        (await apiDatabase.saveModel('email', createRequest())).toMap(),
        createRequest().toMap(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 1);

      expect(
        (await apiDatabase.saveModel('email', createRequest()..id = 'Cool'))
            .toMap(),
        (createRequest()..id = 'Cool').toMap(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 2);

      expect((await apiDatabase.findModel('email', 'Cool'))?.toMap(), null);
      await Future<void>.delayed(Duration.zero);
      expect(i, 3);

      expect(
        await apiDatabase.findAllModelsOfType('email', EmailLoginRequest.new),
        <EmailLoginRequest>[],
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 4);

      expect(
        await apiDatabase.deleteModel('email', createRequest()..id = 'Cool'),
        false,
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 5);
    });
    test('Not Found', () async {
      final database =
          FakeDatabaseRepository(constructors: {EncodedJWT: EncodedJWT.new});
      final requester = createNotFoundRequester();

      final api = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final apiDatabase = ApiDatabaseRepository(
        apiRepository: api,
        baseURL: 'notFound',
        constructors: {EmailLoginRequest: EmailLoginRequest.new},
      );
      var i = 0;
      apiDatabase.errorStream.stream.listen((_) => i++);

      expect(
        (await apiDatabase.saveModel('email', createRequest())).toMap(),
        createRequest().toMap(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 0);

      expect(
        (await apiDatabase.saveModel('email', createRequest()..id = 'Cool'))
            .toMap(),
        (createRequest()..id = 'Cool').toMap(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 0);

      expect((await apiDatabase.findModel('email', 'Cool'))?.toMap(), null);
      await Future<void>.delayed(Duration.zero);
      expect(i, 0);

      expect(
        await apiDatabase.findAllModelsOfType('email', EmailLoginRequest.new),
        <EmailLoginRequest>[],
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 0);

      expect(
        await apiDatabase.deleteModel('email', createRequest()..id = 'Cool'),
        false,
      );
      await Future<void>.delayed(Duration.zero);
      expect(i, 0);
    });
    test('Expected', () async {
      final database = FakeDatabaseRepository(
        constructors: {EmailLoginRequest: EmailLoginRequest.new},
      );
      final requester = createRequester(database);

      final api = APIRepository(
        database: SpecificDatabase(database, 'jwt'),
        requester: requester,
      );

      final apiDatabase = ApiDatabaseRepository(
        apiRepository: api,
        baseURL: 'cool',
        constructors: {EmailLoginRequest: EmailLoginRequest.new},
      );
      var i = 0;
      apiDatabase.errorStream.stream.listen((_) => i++);

      expect(
        (await apiDatabase.saveModel('value', createRequest())).toMap(),
        (createRequest()..idSuffix = 'id').toMap(),
      );

      expect(
        (await apiDatabase.findModel<EmailLoginRequest>(
          'value',
          (EmailLoginRequest()..idSuffix = 'id').id!,
        ))
            ?.toMap(),
        (createRequest()..idSuffix = 'id').toMap(),
      );

      expect(
        (await apiDatabase.findAllModelsOfType('value', EmailLoginRequest.new))
            .map((e) => e.toMap())
            .toList(),
        [(createRequest()..idSuffix = 'id').toMap()],
      );

      expect(
        await apiDatabase.deleteModel(
          'value',
          createRequest()..idSuffix = 'id',
        ),
        true,
      );

      expect(
        (await apiDatabase.findModel<EmailLoginRequest>(
          'value',
          (EmailLoginRequest()..idSuffix = 'id').id!,
        ))
            ?.toMap(),
        null,
      );

      expect(
        await apiDatabase.deleteModel(
          'value',
          createRequest()..idSuffix = 'id',
        ),
        false,
      );

      await Future<void>.delayed(Duration.zero);
      expect(i, 0);
    });
  });
}

EmailLoginRequest createRequest() => EmailLoginRequest()
  ..email = 'myEmail@example.com'
  ..password = 'example';

APIRequester createRequester(DatabaseRepository repository) {
  return FakeAPIRequester(
    fakeMultipartRequestMap: {},
    fakeRequestMap: {
      'cool/value': (request) async {
        switch (request.method) {
          case 'GET':
            final models = await repository.findAllModelsOfType(
              'database',
              EmailLoginRequest.new,
            );
            final response = json.encode(models.map((e) => e.toMap()).toList());
            return StreamedResponse(Stream.value(response.codeUnits), 200);
          case 'POST':
            final model = EmailLoginRequest()..loadFromJsonString(request.body);
            model.idSuffix = 'id';
            await repository.saveModel('database', model);
            return StreamedResponse(Stream.value(model.id!.codeUnits), 200);
          default:
            return StreamedResponse(Stream.value([]), 404);
        }
      },
      'cool/value/Email Login::id': (request) async {
        switch (request.method) {
          case 'GET':
            final model = await repository.findModel<EmailLoginRequest>(
              'database',
              'Email Login::id',
            );
            if (model == null) {
              return StreamedResponse(Stream.value([]), 404);
            }
            return StreamedResponse(
              Stream.value(model.toJsonString().codeUnits),
              200,
            );
          case 'DELETE':
            final model = EmailLoginRequest()..loadFromJsonString(request.body);
            final success = await repository.deleteModel<EmailLoginRequest>(
              'database',
              model,
            );
            if (!success) {
              return StreamedResponse(Stream.value([]), 404);
            }
            return StreamedResponse(
              Stream.value(model.toJsonString().codeUnits),
              200,
            );
          case 'PUT':
            final model = EmailLoginRequest()..loadFromJsonString(request.body);
            model.idSuffix = 'id';
            await repository.saveModel('database', model);
            return StreamedResponse(Stream.value(model.id!.codeUnits), 200);
          default:
            return StreamedResponse(Stream.value([]), 404);
        }
      },
    },
  );
}

APIRequester createNotFoundRequester() {
  return StubAPIRequester(
    multipartStubResponse: (_) {
      return StreamedResponse(Stream.value([]), 404);
    },
    stubResponse: (request) async {
      return StreamedResponse(Stream.value([]), 404);
    },
  );
}

APIRequester createUnreachableRequester() {
  return StubAPIRequester(
    multipartStubResponse: (_) {
      return StreamedResponse(Stream.value([]), 404);
    },
    stubResponse: (request) async {
      return StreamedResponse(Stream.value([]), 504);
    },
  );
}
