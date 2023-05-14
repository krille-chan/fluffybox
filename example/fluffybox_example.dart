import 'package:fluffybox/fluffybox.dart';

void main() async {
  // Create a box collection
  final collection = await BoxCollection.open(
    'MyFirstFluffyBox', // Name of your database
    {'cats', 'dogs'}, // Names of your boxes
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
}
