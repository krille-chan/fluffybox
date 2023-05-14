Easy to use but powerful storage for Flutter and web if you need a simple package like Hive with the scalability of SQFlite on native and IndexedDB on web. Works on all platforms!

## Features

- Simple API with Boxes highly inspired by Hive
- Just uses native **indexedDB** on web and **SQFlite** on native
- **Nothing** is loaded to memory until it is needed
- You have **BoxCollections** (Databases in SQFlite and IndexedDB) and **Boxes** (tables in SQFlite and ObjectStores in IndexedDB)
- **Transactions** to speed up dozens of write actions

## Getting started

Add FluffyBox and SQFlite to your pubspec.yaml:

```yaml
  fluffybox: <latest-version>
  sqflite: <latest-version> # Needed to use in Flutter on Android and iOS
  sqflite_common_ffi: <latest-version> # Needed to use in Flutter Desktop and Dart IO applications
  sqflite_sqlcipher: <latest-version> # If you like your databases encrypted
```

## Usage

```dart
  // Create a box collection
  final collection = await BoxCollection.open(
    'MyFirstFluffyBox', // Name of your database
    {'cats', 'dogs'}, // Names of your boxes
    sqfliteDatabase: database, // Needed outside of web
  );

  // Open your boxes. Optional: Give it a type.
  final catsBox = collection.openBox<Map>('cats');

  // Put something in
  await catsBox.put('fluffy', {'name': 'Fluffy', 'age': 4});
  await catsBox.put('loki', {'name': 'Loki', 'age': 2});

  // Get values of type (immutable) Map?
  final loki = await catsBox.get('loki');
  print('Loki is ${loki?['age']} years old.');

  // Returns a List of values
  final cats = await catsBox.getAll(['loki', 'fluffy']);
  print(cats);

  // Returns a List<String> of all keys
  final allCatKeys = await catsBox.getAllKeys();
  print(allCatKeys);

  // Returns a Map<String, Map> with all keys and entries
  final catMap = await catsBox.getAllValues();
  print(catMap);

  // delete one or more entries
  await catsBox.delete('loki');
  await catsBox.deleteAll(['loki', 'fluffy']);

  // ...or clear the whole box at once
  await catsBox.clear();

  // Speed up write actions with transactions
  await collection.transaction(
    () async {
      await catsBox.put('fluffy', {'name': 'Fluffy', 'age': 4});
      await catsBox.put('loki', {'name': 'Loki', 'age': 2});
      // ...
    },
    boxNames: ['cats'], // By default all boxes become blocked.
    readOnly: false,
  );
```
