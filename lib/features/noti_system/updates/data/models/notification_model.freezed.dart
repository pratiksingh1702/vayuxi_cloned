// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationModel {
  String get id;
  NotificationType get type;
  String get title;
  String get description;
  DateTime get timestamp;
  bool get isRead;
  NotificationPriority get priority;
  NotificationMedia? get media;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<NotificationAction> get actions;
  Map<String, dynamic> get metadata;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotificationModelCopyWith<NotificationModel> get copyWith =>
      _$NotificationModelCopyWithImpl<NotificationModel>(
          this as NotificationModel, _$identity);

  /// Serializes this NotificationModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NotificationModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.media, media) || other.media == media) &&
            const DeepCollectionEquality().equals(other.actions, actions) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      title,
      description,
      timestamp,
      isRead,
      priority,
      media,
      const DeepCollectionEquality().hash(actions),
      const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, description: $description, timestamp: $timestamp, isRead: $isRead, priority: $priority, media: $media, actions: $actions, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $NotificationModelCopyWith<$Res> {
  factory $NotificationModelCopyWith(
          NotificationModel value, $Res Function(NotificationModel) _then) =
      _$NotificationModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      NotificationType type,
      String title,
      String description,
      DateTime timestamp,
      bool isRead,
      NotificationPriority priority,
      NotificationMedia? media,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<NotificationAction> actions,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$NotificationModelCopyWithImpl<$Res>
    implements $NotificationModelCopyWith<$Res> {
  _$NotificationModelCopyWithImpl(this._self, this._then);

  final NotificationModel _self;
  final $Res Function(NotificationModel) _then;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? timestamp = null,
    Object? isRead = null,
    Object? priority = null,
    Object? media = freezed,
    Object? actions = null,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _self.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      media: freezed == media
          ? _self.media
          : media // ignore: cast_nullable_to_non_nullable
              as NotificationMedia?,
      actions: null == actions
          ? _self.actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<NotificationAction>,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [NotificationModel].
extension NotificationModelPatterns on NotificationModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_NotificationModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_NotificationModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_NotificationModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            NotificationType type,
            String title,
            String description,
            DateTime timestamp,
            bool isRead,
            NotificationPriority priority,
            NotificationMedia? media,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<NotificationAction> actions,
            Map<String, dynamic> metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationModel() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.title,
            _that.description,
            _that.timestamp,
            _that.isRead,
            _that.priority,
            _that.media,
            _that.actions,
            _that.metadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            NotificationType type,
            String title,
            String description,
            DateTime timestamp,
            bool isRead,
            NotificationPriority priority,
            NotificationMedia? media,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<NotificationAction> actions,
            Map<String, dynamic> metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationModel():
        return $default(
            _that.id,
            _that.type,
            _that.title,
            _that.description,
            _that.timestamp,
            _that.isRead,
            _that.priority,
            _that.media,
            _that.actions,
            _that.metadata);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            NotificationType type,
            String title,
            String description,
            DateTime timestamp,
            bool isRead,
            NotificationPriority priority,
            NotificationMedia? media,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<NotificationAction> actions,
            Map<String, dynamic> metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationModel() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.title,
            _that.description,
            _that.timestamp,
            _that.isRead,
            _that.priority,
            _that.media,
            _that.actions,
            _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NotificationModel implements NotificationModel {
  const _NotificationModel(
      {required this.id,
      required this.type,
      required this.title,
      required this.description,
      required this.timestamp,
      this.isRead = false,
      this.priority = NotificationPriority.medium,
      this.media,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<NotificationAction> actions = const [],
      final Map<String, dynamic> metadata = const {}})
      : _actions = actions,
        _metadata = metadata;
  factory _NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  @override
  final String id;
  @override
  final NotificationType type;
  @override
  final String title;
  @override
  final String description;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isRead;
  @override
  @JsonKey()
  final NotificationPriority priority;
  @override
  final NotificationMedia? media;
  final List<NotificationAction> _actions;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<NotificationAction> get actions {
    if (_actions is EqualUnmodifiableListView) return _actions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_actions);
  }

  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotificationModelCopyWith<_NotificationModel> get copyWith =>
      __$NotificationModelCopyWithImpl<_NotificationModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NotificationModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NotificationModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.media, media) || other.media == media) &&
            const DeepCollectionEquality().equals(other._actions, _actions) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      title,
      description,
      timestamp,
      isRead,
      priority,
      media,
      const DeepCollectionEquality().hash(_actions),
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, description: $description, timestamp: $timestamp, isRead: $isRead, priority: $priority, media: $media, actions: $actions, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$NotificationModelCopyWith<$Res>
    implements $NotificationModelCopyWith<$Res> {
  factory _$NotificationModelCopyWith(
          _NotificationModel value, $Res Function(_NotificationModel) _then) =
      __$NotificationModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      NotificationType type,
      String title,
      String description,
      DateTime timestamp,
      bool isRead,
      NotificationPriority priority,
      NotificationMedia? media,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<NotificationAction> actions,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$NotificationModelCopyWithImpl<$Res>
    implements _$NotificationModelCopyWith<$Res> {
  __$NotificationModelCopyWithImpl(this._self, this._then);

  final _NotificationModel _self;
  final $Res Function(_NotificationModel) _then;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? timestamp = null,
    Object? isRead = null,
    Object? priority = null,
    Object? media = freezed,
    Object? actions = null,
    Object? metadata = null,
  }) {
    return _then(_NotificationModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _self.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      media: freezed == media
          ? _self.media
          : media // ignore: cast_nullable_to_non_nullable
              as NotificationMedia?,
      actions: null == actions
          ? _self._actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<NotificationAction>,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

// dart format on
