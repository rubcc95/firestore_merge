# Firestore Snapshot Combiner for Dart/Flutter

A package that simplifies the merging of snapshots from different Firestore documents and collections into a single `QuerySnapshot`. It streamlines real-time data management and provides an easy-to-use interface for working with multiple data sources in Firestore.

## Usage

Here's a basic example of how to use the package:

```dart
import 'package:package:firestore_merge/firestore_merge.dart';

void example(){    
  final database = FirebaseFirestore.instance;

  final queries = {
    database.collection('Lorem'),
    database.collection('ipsum').where('elementum', isNull: true),
    database.collection('dolor'),
  };

  final documents = {
    database.doc('sit/amet'),
    database.doc('consectetur/adipiscing'),
  };

  FirestoreMerge.snapshots(
    docs: documents,
    queries: queries,
  ).listen((event) {
    print('''$event says: "Hi, I'm a combination of all this stuff"''');
  });
}
```

Make sure to provide clear and concise examples so that users can understand how to integrate and use your package in their projects.

## Contributions and Issues

If you encounter problems or wish to contribute, please open an issue or send a pull request on the [package's GitHub repository](link_to_repository).

## License

This package is under the Apache License 2.0.