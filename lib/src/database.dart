import 'dart:async';
import 'dart:convert';

import 'package:event_api/event_api.dart';
import 'package:event_bloc/event_bloc.dart';
import 'package:event_db/event_db.dart';

/// An implementation of [DatabaseRepository] that relies on an API Server or
/// [APIRepository] to manage the data.
class ApiDatabaseRepository extends DatabaseRepository {
  /// [apiRepository] is the api server where the [BaseModel]s will be stored
  ///
  /// [baseURL] is infixed to all requests. Should not end with /
  ApiDatabaseRepository({
    required this.apiRepository,
    required this.baseURL,
    required this.constructors,
  });

  /// [constructors] holds all of the [ModelConstructor]s that can be found in
  /// this repository.
  final Map<Type, ModelConstructor> constructors;

  /// The api server where the [BaseModel]s will be stored
  final APIRepository apiRepository;

  /// Infixed to all requests. Should not end with /
  final String baseURL;

  @override
  FutureOr<bool> deleteModel<T extends BaseModel>(
    String database,
    T model,
  ) async {
    assert(model.id != null, 'Cannot delete model with no specified id!');
    final response = await apiRepository.request(
      'DELETE',
      '$baseURL/$database/${model.id}',
      (request) => request.body = model.toJsonString(),
    );

    switch (response.statusCode) {
      case 200:
        return true;
      case 504:
        errorStream.add(
          DatabaseException(
            database: database,
            action: DatabaseAction.delete,
            error: DatabaseError.noDatabaseAccess,
          ),
        );
        return false;
      case 404:
      default:
        return false;
    }
  }

  @override
  FutureOr<Iterable<T>> findAllModelsOfType<T extends BaseModel>(
    String database,
    T Function() supplier,
  ) async {
    final response = await apiRepository.request(
      'GET',
      '$baseURL/$database',
      (request) => null,
    );

    switch (response.statusCode) {
      case 200:
        final body = await response.body;
        final list = json.decode(body) as List;
        return list
            .map((e) => supplier()..loadFromMap(e as Map<String, dynamic>));
      case 504:
        errorStream.add(
          DatabaseException(
            database: database,
            action: DatabaseAction.findAll,
            error: DatabaseError.noDatabaseAccess,
          ),
        );
        return [];
      case 404:
      default:
        return [];
    }
  }

  /// Creates an instance using one of the [constructors]
  ///
  /// Will throw an [ArgumentError] if one isn't present in [constructors]
  /// for [S]
  S getInstance<S>() {
    if (!constructors.containsKey(S)) {
      throw ArgumentError(
          '$S was not added to the constructors of this ApiDatabaseRepository.'
          ' Please ensure you add all constructors you want to use for each '
          'type you will use.');
    }
    return constructors[S]!() as S;
  }

  @override
  FutureOr<T?> findModel<T extends BaseModel>(
    String database,
    String key,
  ) async {
    final response = await apiRepository.request(
      'GET',
      '$baseURL/$database/$key',
      (request) => null,
    );

    switch (response.statusCode) {
      case 200:
        return response.bodyAsModel(getInstance<T>);
      case 504:
        errorStream.add(
          DatabaseException(
            database: database,
            action: DatabaseAction.findByKey,
            error: DatabaseError.noDatabaseAccess,
          ),
        );
        return null;
      case 404:
      default:
        return null;
    }
  }

  @override
  List<BlocEventListener<dynamic>> generateListeners(
    BlocEventChannel channel,
  ) =>
      [];

  @override
  FutureOr<T> saveModel<T extends BaseModel>(
    String database,
    T model,
  ) async {
    final shouldUpdate = model.id != null;
    final response = await (shouldUpdate
        ? apiRepository.request(
            'PUT',
            '$baseURL/$database/${model.id}',
            (request) => request.body = model.toJsonString(),
          )
        : apiRepository.request(
            'POST',
            '$baseURL/$database',
            (request) => request.body = model.toJsonString(),
          ));

    switch (response.statusCode) {
      case 200:
        return model..id = await response.body;
      case 504:
        errorStream.add(
          DatabaseException(
            database: database,
            action: DatabaseAction.save,
            error: DatabaseError.noDatabaseAccess,
          ),
        );
        return model;
      case 404:
      default:
        return model;
    }
  }
}
