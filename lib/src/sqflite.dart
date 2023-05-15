import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

class BoxCollection {
  final Database _db;
  final Set<String> boxNames;

  BoxCollection(this._db, this.boxNames);

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    int version = 1,
    Object? sqfliteDatabase,
  }) async {
    if (sqfliteDatabase is! Database) {
      throw ('You must provide a Database `sqfliteDatabase` for FluffyBox on native.');
    }
    final batch = sqfliteDatabase.batch();
    for (final name in boxNames) {
      batch.execute(
        'CREATE TABLE IF NOT EXISTS $name (k TEXT PRIMARY KEY NOT NULL, v TEXT)',
      );
      batch.execute('CREATE INDEX IF NOT EXISTS k_index ON $name (k)');
    }
    await batch.commit(noResult: true);
    return BoxCollection(sqfliteDatabase, boxNames);
  }

  Box<V> openBox<V>(String name) {
    if (!boxNames.contains(name)) {
      throw ('Box with name $name is not in the known box names of this collection.');
    }
    return Box<V>(name, this);
  }

  Batch? _activeBatch;

  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  }) async {
    boxNames ??= this.boxNames.toList();
    _activeBatch = _db.batch();
    await action();
    final batch = _activeBatch;
    _activeBatch = null;
    if (batch == null) return;
    await batch.commit(noResult: true);
    return;
  }

  void close() {
    //_db.close();
  }
}

class Box<V> {
  final String name;
  final BoxCollection boxCollection;
  final Map<String, V?> _cache = {};
  Set<String>? _cachedKeys;
  bool get _keysCached => _cachedKeys != null;

  static const Set<String> allowedValueTypes = {
    'List<dynamic>',
    'Map<dynamic, dynamic>',
    'String',
    'int',
    'double',
    'bool',
  };

  Box(this.name, this.boxCollection) {
    if (!allowedValueTypes.contains(V.toString())) {
      throw Exception(
        'Illegal value type for Box: "${V.toString()}". Must be one of $allowedValueTypes',
      );
    }
  }

  String? _toString(V? value) {
    if (value == null) return null;
    switch (V.toString()) {
      case 'List<dynamic>':
      case 'Map<dynamic, dynamic>':
        return jsonEncode(value);
      case 'String':
      case 'int':
      case 'double':
      case 'bool':
      default:
        return value.toString();
    }
  }

  V? _fromString(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw Exception(
          'Wrong database type! Expected String but got one of type ${value.runtimeType}');
    }
    switch (V.toString()) {
      case 'int':
        return int.parse(value) as V;
      case 'double':
        return double.parse(value) as V;
      case 'bool':
        return (value == 'true') as V;
      case 'List<dynamic>':
      case 'Map<dynamic, dynamic>':
        return jsonDecode(value) as V;
      case 'String':
      default:
        return value as V;
    }
  }

  Future<List<String>> getAllKeys([Transaction? txn]) async {
    if (_keysCached) return _cachedKeys!.toList();

    final executor = txn ?? boxCollection._db;

    final result = await executor.query(name, columns: ['k']);
    final keys = result.map((row) => row['k'] as String).toList();

    _cachedKeys = keys.toSet();
    return keys;
  }

  Future<Map<String, V>> getAllValues([Transaction? txn]) async {
    final executor = txn ?? boxCollection._db;

    final result = await executor.query(name);
    return Map.fromEntries(
      result.where((row) => row['v'] != null).map(
            (row) => MapEntry(
              row['k'] as String,
              _fromString(row['v']) as V,
            ),
          ),
    );
  }

  Future<V?> get(String key, [Transaction? txn]) async {
    if (_cache.containsKey(key)) return _cache[key];

    final executor = txn ?? boxCollection._db;

    final result = await executor.query(
      name,
      columns: ['v'],
      where: 'k = ?',
      whereArgs: [key],
    );

    final value = result.isEmpty ? null : _fromString(result.single['v']);
    _cache[key] = value;
    return value;
  }

  Future<List<V?>> getAll(List<String> keys, [Transaction? txn]) async {
    if (!keys.any((key) => !_cache.containsKey(key))) {
      return keys.map((key) => _cache[key]).toList();
    }

    final executor = txn ?? boxCollection._db;

    final list = <V?>[];
    final result = await executor.query(
      name,
      where: 'k IN (${keys.map((_) => '?').join(',')})',
      whereArgs: keys,
    );
    final resultMap = Map<String, V?>.fromEntries(result
        .map((row) => MapEntry(row['k'] as String, _fromString(row['v']))));
    list.addAll(keys.map((key) => resultMap[key]));

    for (var i = 0; i < keys.length; i++) {
      _cache[keys[i]] = list[i];
    }
    return list;
  }

  Future<void> put(String key, V val) async {
    final txn = boxCollection._activeBatch;

    final params = {
      'k': key,
      'v': _toString(val),
    };
    if (txn == null) {
      await boxCollection._db.insert(
        name,
        params,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      txn.insert(
        name,
        params,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    _cache[key] = val;
    _cachedKeys?.add(key);
    return;
  }

  Future<void> delete(String key, [Batch? txn]) async {
    txn ??= boxCollection._activeBatch;

    if (txn == null) {
      await boxCollection._db.delete(name, where: 'k = ?', whereArgs: [key]);
    } else {
      txn.delete(name, where: 'k = ?', whereArgs: [key]);
    }

    _cache.remove(key);
    _cachedKeys?.remove(key);
    return;
  }

  Future<void> deleteAll(List<String> keys, [Batch? txn]) async {
    txn ??= boxCollection._activeBatch;

    final placeholder = keys.map((_) => '?').join(',');
    if (txn == null) {
      await boxCollection._db.delete(
        name,
        where: 'k IN ($placeholder)',
        whereArgs: keys,
      );
    } else {
      txn.delete(
        name,
        where: 'k IN ($placeholder)',
        whereArgs: keys,
      );
    }

    for (final key in keys) {
      _cache.remove(key);
      _cachedKeys?.removeAll(keys);
    }
    return;
  }

  Future<void> clear([Batch? txn]) async {
    txn ??= boxCollection._activeBatch;

    if (txn == null) {
      await boxCollection._db.delete(name);
    } else {
      txn.delete(name);
    }

    _cache.clear();
    _cachedKeys = null;
    return;
  }
}
