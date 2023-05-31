import 'dart:async';
import 'dart:convert';

import 'package:event_api/event_api.dart';
import 'package:http/http.dart';

/// IMplementation of [APIRequester] that sends actual requests to an
/// external server.
class ServerAPIRequester implements APIRequester {
  /// [apiServer] is the server to send requests to.
  ///
  /// [website] is the expected client-side website to be used as the origin
  ServerAPIRequester({required this.apiServer, required this.website});
  @override
  final String apiServer;
  @override
  final String website;

  /// The client used to send requests to the server.
  late final client = Client();

  @override
  Future<StreamedResponse> request(
    String method,
    String urlSuffix,
    FutureOr<void> Function(Request) addToRequest,
  ) async {
    final fullUrl = '$apiServer$urlSuffix';
    final request = Request(method, Uri.parse(fullUrl));
    await addToRequest(request);
    try {
      return await client.send(request);
    } on Object {
      return StreamedResponse(
        Stream.fromIterable(
          [utf8.encode('Unable to connect to the server...')],
        ),
        504,
      );
    }
  }
}
