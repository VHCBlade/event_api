import 'package:event_api/event_api.dart';
import 'package:event_db/event_db.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('FutureResponse', () {
    test('body', () async {
      final response = StreamedResponse(Stream.value('Amazing'.codeUnits), 200);
      expect(await response.body, 'Amazing');
    });
    test('bodyAsMap', () async {
      final response = StreamedResponse(
        Stream.value('{"cool": 1, "amazing": "a"}'.codeUnits),
        200,
      );
      expect(await response.bodyAsMap, {'cool': 1, 'amazing': 'a'});
    });
    test('bodyAsModel', () async {
      final jwt = EncodedJWT.fromToken('token')..idSuffix = 'cool';
      final response = StreamedResponse(
        Stream.value(jwt.toJsonString().codeUnits),
        200,
      );
      expect((await response.bodyAsModel(EncodedJWT.new)).toMap(), jwt.toMap());
    });
  });
}
