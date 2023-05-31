import 'dart:async';

import 'package:event_api/event_api.dart';
import 'package:http/http.dart';

/// A fake version of [APIRequester]. Use this in tests or help develop your
/// APIs without having to
class FakeAPIRequester implements APIRequester {
  /// [fakeRequestMap] holds the fake responses for requests.
  FakeAPIRequester({
    required this.fakeRequestMap,
    this.website = 'https://example.com/',
    this.apiServer = 'https://api.example.com/',
  });

  /// Holds the fake responses for requests.
  ///
  /// The key is the urlSuffix used for the request.
  final Map<String, FutureOr<StreamedResponse> Function(Request)>
      fakeRequestMap;

  @override
  final String apiServer;

  @override
  final String website;

  @override
  FutureOr<StreamedResponse> request(
    String method,
    String urlSuffix,
    FutureOr<void> Function(Request) addToRequest,
  ) async {
    if (!fakeRequestMap.containsKey(urlSuffix)) {
      return StreamedResponse(Stream.value([]), 500);
    }

    final fullUrl = '$apiServer$urlSuffix';
    final request = Request(method, Uri.parse(fullUrl));

    await addToRequest(request);

    return fakeRequestMap[urlSuffix]!(request);
  }
}
