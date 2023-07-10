import 'dart:async';

import 'package:event_api/event_api.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_bloc/event_bloc.dart';
import 'package:event_db/event_db.dart';
import 'package:http/http.dart';

const _encodedJWT = 'EncodedJWT';

/// Automatically manages JWTs while sending requests.
class APIRepository extends Repository {
  /// [database] is where the JWT will be saved.
  ///
  /// [requester] is what
  APIRepository({
    required this.database,
    required this.requester,
  });

  /// Where the [EncodedJWT] will be stored.
  final SpecificDatabase database;

  /// Handles sending requests.
  final APIRequester requester;

  EncodedJWT? _jwt;

  /// This is the JWT that will be attached to all requests.
  Future<EncodedJWT?> get jwt async {
    if (_jwt != null) {
      return _jwt;
    }
    return _jwt = await database.findModel(_encodedJWT);
  }

  /// Deletes the current jwt to perform a logout.
  Future<void> logout() async {
    final currentJwt = await jwt;
    if (currentJwt != null) {
      await database.deleteModel(currentJwt);
    }
    _jwt = null;
  }

  /// Creates a request using [method] to the [urlSuffix] endpoint with
  /// [requester].
  ///
  /// [addToRequest] is used for addings things like headers to the request
  /// before sending it.
  ///
  /// Automatically adds [jwt] as an Authorization header if it's available.
  Future<StreamedResponse> request(
    String method,
    String urlSuffix,
    FutureOr<void> Function(Request request) addToRequest,
  ) async {
    final response =
        await requester.request(method, urlSuffix, (request) async {
      final loadedJwt = await jwt;
      request.headers.authorization = loadedJwt?.token;
      addToRequest(request);
    });

    if (response.headers.authorization == null) {
      return response;
    }
    _jwt = EncodedJWT.fromToken(response.headers.authorization!)
      ..id = _encodedJWT;
    database.saveModel(_jwt!);
    return response;
  }

  /// Creates a multipart request using [method] to the [urlSuffix] endpoint
  /// with [requester].
  ///
  /// [addToRequest] is used for addings things like headers to the request
  /// before sending it.
  ///
  /// Automatically adds [jwt] as an Authorization header if it's available.
  Future<StreamedResponse> multipartRequest(
    String method,
    String urlSuffix,
    FutureOr<void> Function(MultipartRequest request) addToRequest,
  ) async {
    final response =
        await requester.multipartRequest(method, urlSuffix, (request) async {
      final loadedJwt = await jwt;
      request.headers.authorization = loadedJwt?.token;
      addToRequest(request);
    });

    if (response.headers.authorization == null) {
      return response;
    }
    _jwt = EncodedJWT.fromToken(response.headers.authorization!)
      ..id = _encodedJWT;
    database.saveModel(_jwt!);
    return response;
  }

  @override
  List<BlocEventListener<dynamic>> generateListeners(
    BlocEventChannel channel,
  ) =>
      [];
}

/// Manages sending requests to the server or other API.
abstract class APIRequester {
  /// The server to send requests to.
  String get apiServer;

  /// The expected client-side website to be used as the origin
  String get website;

  /// Creates a request using [method] to the [urlSuffix] endpoint.
  ///
  /// [addToRequest] is used for addings things like headers to the request
  /// before sending it.
  FutureOr<StreamedResponse> request(
    String method,
    String urlSuffix,
    void Function(Request request) addToRequest,
  );

  /// Creates a multipart request using [method] to the [urlSuffix] endpoint.
  ///
  /// [addToRequest] is used for addings things like headers to the request
  /// before sending it.
  FutureOr<StreamedResponse> multipartRequest(
    String method,
    String urlSuffix,
    void Function(MultipartRequest request) addToRequest,
  );
}
