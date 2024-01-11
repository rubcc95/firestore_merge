import 'dart:async';
import 'dart:collection';

typedef MergedStreamBuilder<T, R> = void Function(MergedStreamController<T, R> c) Function();

class MergedStreamController<T, R> {
  final StreamController<R> _controller;
  final T value;
  final int index;
  final List<StreamSubscription<T>> subscriptions;

  MergedStreamController._(
      this._controller, this.value, this.index, this.subscriptions);

  StreamSubscription get currentSubscription => subscriptions[index];

  void add(R combined) => _controller.add(combined);

  void pause() {
    for (int i = 0; i < subscriptions.length; i++) {
      subscriptions[i].pause();
    }
  }

  void resume() {
    for (int i = 0; i < subscriptions.length; i++) {
      subscriptions[i].resume();
    }
  }

  void cancel() async =>
      await Future.wait(subscriptions.map((e) => e.cancel()));
}

class MergedStream<T, R> extends StreamView<R> {
  MergedStream(
    final Iterable<Stream<T>> streams,
    final MergedStreamBuilder<T, R> mergerBuilder,
  ) : super(_createController(streams, mergerBuilder).stream);

  static MergedStream<T, T> merge<T>(final Iterable<Stream<T>> streams) =>
      MergedStream(streams, () => (c) => c.add(c.value));

  static MergedStream<T, List<T?>> combineLatest<T>(
    final Iterable<Stream<T>> streams) =>
  MergedStream(streams, () {
    final latest = List<T?>.filled(streams.length, null, growable: false);
    return (c) {
      latest[c.index] = c.value;
      c.add(latest.toList(growable: false));
    };
  });

  static MergedStream<T, List<T>> combineAll<T>(
          final Iterable<Stream<T>> streams) =>
      MergedStream(streams, () {
        final latest = List<T?>.filled(streams.length, null, growable: false);
        var count = 0;
        return (c) {
          if (latest[c.index] == null) {
            latest[c.index] = c.value;
            if (++count == latest.length) {
              count = 0;
              c.add(latest.cast<T>().toList(growable: false));
              for (int i = 0; i < latest.length; i++) {
                latest[i] = null;
              }

              c.resume();
            } else {
              c.currentSubscription.pause();
            }
          }
        };
      });

  static StreamController<R> _createController<T, R>(
      final Iterable<Stream<T>> streams,
      final MergedStreamBuilder<T, R> mergerBuilder) {
    late final StreamController<R> controller;
    late final List<StreamSubscription<T>> subscriptions;
    final merger = mergerBuilder();

    return controller = StreamController<R>(
      sync: true,
      onListen: () {
        var completed = 0;
        subscriptions = streams.indexed.map((entry) {
          final index = entry.$1, stream = entry.$2;
          return stream.listen(
            (value) {
              merger(
                  MergedStreamController._(controller, value, index, subscriptions));
            },
            onError: controller.addError,
            onDone: () {
              if (++completed == subscriptions.length) {
                controller.close();
              }
            },
          );
        }).toList(growable: false);

        if (subscriptions.isEmpty) {
          controller.close();
        }
      },

      onPause: () {
        for (int i = 0; i < subscriptions.length; i++) {
          subscriptions[i].pause();
        }
      },

      onResume: () {
        for (int i = 0; i < subscriptions.length; i++) {
          subscriptions[i].resume();
        }
      },

      onCancel: () async =>
          await Future.wait(subscriptions.map((e) => e.cancel())),
    );
  }
}

class MergedList<T> extends UnmodifiableListView<T>{
  MergedList(Iterable<List<T>> lists) : super(_MergedList(lists));
}

class _MergedList<T> extends ListBase<T> {
  final Iterable<List<T>> lists;

  _MergedList(this.lists);
  
  @override
  int get length => lists.fold(0, (total, list) => total + list.length);
  
  @override
  T operator [](int index) {
    for(final list in lists) {
      if (index < list.length) {
        return list[index];
      } else {
        index -= list.length;
      }
    }

    throw RangeError('Index out of bounds');
  }
  
  @override
  void operator []=(int index, T value) => throw UnsupportedError("Cannot change the length of an unmodifiable list");
  
  @override
  set length(int newLength) => throw UnsupportedError("Cannot change the length of an unmodifiable list");
}

class MergedIterable<T> extends Iterable<T>{
  final Iterable<Iterable<T>> _iterables;

  MergedIterable(this._iterables);

  @override
  Iterator<T> get iterator => _MergedIterator(_iterables.iterator);
}

class _MergedIterator<T> implements Iterator<T>{
  final Iterator<Iterable<T>> _iterator;
  Iterator<T> _innerIterator = const _EmptyIterator();

  _MergedIterator(this._iterator);
  
  @override
  T get current => _innerIterator.current;
  
  @override
  bool moveNext() {
    while(_innerIterator.moveNext()){
      if(_iterator.moveNext()) {
        _innerIterator = _iterator.current.iterator;
      }
      else{
        return false;
      }
    }
    return true;
  }  
}

class _EmptyIterator<T> implements Iterator<T>{
  const _EmptyIterator();
  
  @override
  T get current => throw UnimplementedError();

  @override
  bool moveNext() => false;
}