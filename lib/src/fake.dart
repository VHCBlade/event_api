import 'dart:async';

import 'package:event_api/event_api.dart';
import 'package:http/http.dart';

/// A fake version of [APIRequester]. Use this in tests or help develop your
/// APIs without having to depend on an external server.
class FakeAPIRequester implements APIRequester {
  /// [fakeRequestMap] holds the fake responses for requests.
  FakeAPIRequester({
    required this.fakeRequestMap,
    required this.fakeMultipartRequestMap,
    this.website = 'https://example.com/',
    this.apiServer = 'https://api.example.com/',
  });

  /// Holds the fake responses for requests.
  ///
  /// The key is the urlSuffix used for the request.
  final Map<String, FutureOr<StreamedResponse> Function(Request)>
      fakeRequestMap;

  /// Holds the fake responses for multipart requests.
  ///
  /// The key is the urlSuffix used for the request.
  final Map<String, FutureOr<StreamedResponse> Function(MultipartRequest)>
      fakeMultipartRequestMap;

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

  @override
  FutureOr<StreamedResponse> multipartRequest(
    String method,
    String urlSuffix,
    FutureOr<void> Function(MultipartRequest request) addToRequest,
  ) async {
    if (!fakeMultipartRequestMap.containsKey(urlSuffix)) {
      return StreamedResponse(Stream.value([]), 500);
    }

    final fullUrl = '$apiServer$urlSuffix';
    final request = MultipartRequest(method, Uri.parse(fullUrl));

    await addToRequest(request);

    return fakeMultipartRequestMap[urlSuffix]!(request);
  }
}

/// A stub version of [APIRequester]. Unlike [FakeAPIRequester], this will
/// always respond with the same response regardless of the urlSuffix.
class StubAPIRequester implements APIRequester {
  /// [stubResponse] is the stub response that will be returned for all requests
  /// to this reqeuster.
  StubAPIRequester({
    required this.stubResponse,
    required this.multipartStubResponse,
    this.website = 'https://example.com/',
    this.apiServer = 'https://api.example.com/',
  });

  @override
  final String apiServer;

  @override
  final String website;

  /// The stub response that will be returned for all requests
  /// to this reqeuster.
  final FutureOr<StreamedResponse> Function(Request) stubResponse;

  /// The stub response that will be returned for all multipart requests
  /// to this reqeuster.
  final FutureOr<StreamedResponse> Function(MultipartRequest)
      multipartStubResponse;

  @override
  FutureOr<StreamedResponse> request(
    String method,
    String urlSuffix,
    void Function(Request request) addToRequest,
  ) async {
    final fullUrl = '$apiServer$urlSuffix';
    final request = Request(method, Uri.parse(fullUrl));

    addToRequest(request);

    return stubResponse(request);
  }

  @override
  FutureOr<StreamedResponse> multipartRequest(
    String method,
    String urlSuffix,
    void Function(MultipartRequest request) addToRequest,
  ) {
    final fullUrl = '$apiServer$urlSuffix';
    final request = MultipartRequest(method, Uri.parse(fullUrl));

    addToRequest(request);

    return multipartStubResponse(request);
  }
}
