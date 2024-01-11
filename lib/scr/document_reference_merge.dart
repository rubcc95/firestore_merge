import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_merge/scr/query_snapshot_merge.dart';

class DocumentsToQuerySnapshot<T> implements QuerySnapshot<T> {
  @override
  final List<DocumentChange<T>> docChanges;  
  @override
  final List<QueryDocumentSnapshot<T>> docs;
  final Iterable<DocumentSnapshotPair<T>> _snapshots;

  DocumentsToQuerySnapshot(this._snapshots)
    : docChanges = _snapshots.where((element) => element.old != null).map((e) {
        return _DocumentChangesView<T>(
        doc: e.current, 
        newIndex: e.current.exists ? 1 : 0, 
        oldIndex: e.old!.exists ? 1 : 0, 
      );
      }).toList(),
      docs = _snapshots.where((e) => e.current.exists).map((e) => _DocumentSnapshotAsQueryDocumentSnapshot(e.current)).toList(growable: false);
  
  @override  
  int get size => docs.length;
  
  @override
  MergedSnapshotMetadata get metadata => MergedSnapshotMetadata(_snapshots.map((e) => e.current.metadata));
}

class DocumentSnapshotPair<T> {
  final DocumentSnapshot<T> current;
  final DocumentSnapshot<T>? old;

  DocumentSnapshotPair({required this.current, required this.old});
}

// ignore: subtype_of_sealed_class
class _DocumentSnapshotAsQueryDocumentSnapshot<T> implements QueryDocumentSnapshot<T>{
  final DocumentSnapshot<T> _doc;
  
  _DocumentSnapshotAsQueryDocumentSnapshot(this._doc);
  
  @override
  T data() => _doc.data()!;

  @override  
  bool get exists => true;

  @override
  operator [](Object field) => _doc[field];

  @override
  get(Object field) => _doc.get(field);

  @override  
  String get id => _doc.id;

  @override  
  SnapshotMetadata get metadata => _doc.metadata;

  @override  
  DocumentReference<T> get reference => _doc.reference;  
}

class _DocumentChangesView<T> implements DocumentChange<T>{

  @override
  final DocumentSnapshot<T> doc;
  @override
  final int newIndex;
  @override
  final int oldIndex;

  const _DocumentChangesView({required this.doc, required this.newIndex, required this.oldIndex});

  @override
  DocumentChangeType get type {
    if(newIndex < 0){
      return DocumentChangeType.removed;
    }
    if(oldIndex < 0){
      return DocumentChangeType.added;
    }
    return DocumentChangeType.modified;
  }
}

