import 'dart:collection';

class Singleton {
  static Singleton _instance;

  static dynamic _map;

  Singleton._internal() {
    _instance = this;
    _map = new HashMap();
  }

  factory Singleton() => _instance ?? Singleton._internal();

  void add(String key, dynamic value) {
    _map.putIfAbsent(key, () => value);
  }

  dynamic read(String key) {
    return _map[key];
  }
}