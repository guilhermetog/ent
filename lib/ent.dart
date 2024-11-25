library ent;

abstract class Ent {
  final Map<String, dynamic> _props = {};
  final Map<String, List<Function>> _events = {};

  Map<String, dynamic> get props;
  Map<String, Function> get events;

  Map<String, dynamic> get allProps => _props;
  Map<String, dynamic> get allEvents => _events;

  Ent({
    Map<String, dynamic>? props,
    Map<String, Function> Function(Ent)? events,
  }) {
    withProps(props);
    withEvents(events);
  }

  withProps(Map<String, dynamic>? props) {
    Map<String, dynamic> externalProps = Map.fromEntries(
        this.props.entries.where((entry) => entry.value is! Function));

    Map<String, dynamic> internalProps = Map.fromEntries(
        props?.entries.where((entry) => entry.value is! Function) ?? {});

    _props.addAll(externalProps);
    _props.addAll(internalProps);
  }

  withEvents(Map<String, Function> Function(Ent)? events) {
    Map<String, Function> internalEvents = this.events;
    Map<String, Function> externalEvents = events?.call(this) ?? {};

    for (final entry in internalEvents.entries) {
      _events[entry.key] ??= [];
      _events[entry.key] = [entry.value];
    }

    for (final entry in externalEvents.entries) {
      _events[entry.key] ??= [];
      _events[entry.key]!.add(entry.value);
    }
  }

  dynamic operator [](String key) {
    if (_props.containsKey(key)) {
      return _props[key];
    } else if (_events.containsKey(key)) {
      return ([arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10]) {
        final args = [
          arg1,
          arg2,
          arg3,
          arg4,
          arg5,
          arg6,
          arg7,
          arg8,
          arg9,
          arg10
        ].where((element) => element != null).toList();
        for (final event in _events[key]!) {
          try {
            Function.apply(event, args);
          } catch (e, stackTrace) {
            print(
                "Error: Event $key has signature [${event.runtimeType}] but was called with arguments[$args]\n$e\n$stackTrace");
          }
        }
      };
    }
    return null;
  }

  operator []=(String key, dynamic value) {
    if (value is Function) {
      _events[key] ??= [];
      _events[key]!.add(value);
    } else {
      if (_events.containsKey(key)) {
        for (final event in _events[key]!) {
          try {
            Function.apply(event, [value]);
          } catch (e, stackTrace) {
            print(
                "Error: Event $key has signature [${event.runtimeType}] but was called with arguments\n[$value]\n$stackTrace");
          }
        }
      } else {
        _props[key] = value;
        if (_events.containsKey('$key-changed')) {
          for (final event in _events['$key-changed']!) {
            Function.apply(event, [value]);
          }
        }
      }
    }
  }

  void listen(String key, Function listener) {
    if (_props.containsKey(key)) {
      key = "$key-changed";
    }

    if (_events.containsKey(key)) {
      if (_events[key]!.first.runtimeType.toString() !=
          listener.runtimeType.toString()) {
        throw Exception(
            "$key must has this [${_events[key]!.first.runtimeType}], but was given this [${listener.runtimeType}]");
      }
    }
    _events[key] ??= [];
    _events[key]!.add(listener);
  }

  T call<T extends Ent>({
    Map<String, dynamic>? props,
    Map<String, Function> Function(Ent)? events,
  }) {
    withProps(props);
    withEvents(events);
    return this as T;
  }

  @override
  String toString() => {
        "props": {
          ..._props.entries.map((prop) => {
                "label": prop.key,
                "value": prop.value,
                "type": prop.value.runtimeType,
              }),
        },
        "events": {
          ..._events.entries.map((event) => {
                "label": event.key,
                "type": event.value.first.runtimeType,
              })
        },
      }.toString();
}
