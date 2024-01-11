import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_merge/scr/basic_merge.dart';
import 'package:firestore_merge/scr/document_reference_merge.dart';
import 'package:firestore_merge/scr/query_snapshot_merge.dart';

class FirestoreMerge {
  static Stream<MergedQuerySnapshot<T>> snapshots<T>({
    required Iterable<DocumentReference<T>> docs,
    required Iterable<Query<T>> queries,
  }) => MergedStream.combineLatest(
    MergedIterable({
      docs.map((e) => e.snapshotsAsQuery()), 
      queries.map((e) => e.snapshots())
    })).map((event) => MergedQuerySnapshot(event.where((element) => element != null).cast()));  

  static Future<MergedQuerySnapshot<T>> get<T>({
    required Iterable<DocumentReference<T>> docs,
    required Iterable<Query<T>> queries,
  }) => Future.wait(MergedIterable({
    docs.map((e) => e.getAsQuery()), 
    queries.map((e) => e.get())
  })).then((value) => MergedQuerySnapshot(value));    
}

extension DocumentsToQuerySnapshotExtension<T> on Iterable<DocumentReference<T>>{
  Stream<MergedQuerySnapshot<T>> snapshots() => FirestoreMerge.snapshots<T>(
    docs: this,
    queries: const {},
  );

    Future<QuerySnapshot<T>> get() => FirestoreMerge.get<T>(
    docs: this,
    queries: const {},
  );
}

extension QueriesToQuerySnapshotExtension<T> on Iterable<Query<T>>{
  Stream<MergedQuerySnapshot<T>> snapshots() => FirestoreMerge.snapshots<T>(
    docs: const {},
    queries: this,
  );

    Future<QuerySnapshot<T>> get() => FirestoreMerge.get<T>(
    docs: const {},
    queries: this,
  );
}

extension DocumentReferenceQuerySnapshotExtension<T> on DocumentReference<T>{
  Stream<QuerySnapshot<T>> snapshotsAsQuery() {
    DocumentSnapshot<T>? old;
    return snapshots().map((event) {
      final res = DocumentsToQuerySnapshot({
        DocumentSnapshotPair(
          current: event,
          old: old,
        )
      });
      old = event;   
      return res;  
    });    
  } 

  Future<QuerySnapshot<T>> getAsQuery() {
    DocumentSnapshot<T>? old;
    return get().then((value) {
      final res = DocumentsToQuerySnapshot({
        DocumentSnapshotPair(
          current: value,
          old: old,
        )
      });
      old = value;   
      return res;
    });    
  } 
}