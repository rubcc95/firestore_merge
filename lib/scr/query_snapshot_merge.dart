import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_merge/scr/basic_merge.dart';

class MergedQuerySnapshot<T> extends Iterable<QuerySnapshot<T>> implements QuerySnapshot<T> {
  final Iterable<QuerySnapshot<T>> _querySnapshots;

  const MergedQuerySnapshot(this._querySnapshots);

  @override
  List<DocumentChange<T>> get docChanges => MergedList(_querySnapshots.map((e) => e.docChanges));

  @override
  List<QueryDocumentSnapshot<T>> get docs => MergedList(_querySnapshots.map((e) => e.docs));

  @override
  MergedSnapshotMetadata get metadata => MergedSnapshotMetadata(_querySnapshots.map((e) => e.metadata));

  @override
  int get size => _querySnapshots.fold(0, (total, list) => total + _querySnapshots.length);
  
  @override
  Iterator<QuerySnapshot<T>> get iterator => _querySnapshots.iterator;
}

class MergedSnapshotMetadata extends Iterable<SnapshotMetadata> implements SnapshotMetadata{
  final Iterable<SnapshotMetadata> _snapshotMetadatas;

  const MergedSnapshotMetadata(this._snapshotMetadatas);

  @override
  bool get hasPendingWrites => _snapshotMetadatas.any((element) => element.hasPendingWrites);

  @override  
  bool get isFromCache => !_snapshotMetadatas.any((element) => !element.isFromCache);
  
  @override  
  Iterator<SnapshotMetadata> get iterator => _snapshotMetadatas.iterator;
}
