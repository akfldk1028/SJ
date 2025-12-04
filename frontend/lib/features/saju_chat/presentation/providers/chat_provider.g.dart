// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'f1cbf557c4d51eabfdc21ea2baa681354961f70b';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = AutoDisposeProvider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = AutoDisposeProviderRef<ChatRepository>;
String _$chatSessionControllerHash() =>
    r'7adadb32aa8e135d2e6dedf504050d270846e1d3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChatSessionController
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatSession>> {
  late final String profileId;

  FutureOr<List<ChatSession>> build(String profileId);
}

/// See also [ChatSessionController].
@ProviderFor(ChatSessionController)
const chatSessionControllerProvider = ChatSessionControllerFamily();

/// See also [ChatSessionController].
class ChatSessionControllerFamily
    extends Family<AsyncValue<List<ChatSession>>> {
  /// See also [ChatSessionController].
  const ChatSessionControllerFamily();

  /// See also [ChatSessionController].
  ChatSessionControllerProvider call(String profileId) {
    return ChatSessionControllerProvider(profileId);
  }

  @override
  ChatSessionControllerProvider getProviderOverride(
    covariant ChatSessionControllerProvider provider,
  ) {
    return call(provider.profileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatSessionControllerProvider';
}

/// See also [ChatSessionController].
class ChatSessionControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ChatSessionController,
          List<ChatSession>
        > {
  /// See also [ChatSessionController].
  ChatSessionControllerProvider(String profileId)
    : this._internal(
        () => ChatSessionController()..profileId = profileId,
        from: chatSessionControllerProvider,
        name: r'chatSessionControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatSessionControllerHash,
        dependencies: ChatSessionControllerFamily._dependencies,
        allTransitiveDependencies:
            ChatSessionControllerFamily._allTransitiveDependencies,
        profileId: profileId,
      );

  ChatSessionControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  FutureOr<List<ChatSession>> runNotifierBuild(
    covariant ChatSessionController notifier,
  ) {
    return notifier.build(profileId);
  }

  @override
  Override overrideWith(ChatSessionController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatSessionControllerProvider._internal(
        () => create()..profileId = profileId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ChatSessionController,
    List<ChatSession>
  >
  createElement() {
    return _ChatSessionControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSessionControllerProvider &&
        other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatSessionControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatSession>> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _ChatSessionControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ChatSessionController,
          List<ChatSession>
        >
    with ChatSessionControllerRef {
  _ChatSessionControllerProviderElement(super.provider);

  @override
  String get profileId => (origin as ChatSessionControllerProvider).profileId;
}

String _$chatMessageControllerHash() =>
    r'c9b46191b3d415fadfb0ebcec284969b71c5064f';

abstract class _$ChatMessageController
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessage>> {
  late final String sessionId;

  FutureOr<List<ChatMessage>> build(String sessionId);
}

/// See also [ChatMessageController].
@ProviderFor(ChatMessageController)
const chatMessageControllerProvider = ChatMessageControllerFamily();

/// See also [ChatMessageController].
class ChatMessageControllerFamily
    extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [ChatMessageController].
  const ChatMessageControllerFamily();

  /// See also [ChatMessageController].
  ChatMessageControllerProvider call(String sessionId) {
    return ChatMessageControllerProvider(sessionId);
  }

  @override
  ChatMessageControllerProvider getProviderOverride(
    covariant ChatMessageControllerProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatMessageControllerProvider';
}

/// See also [ChatMessageController].
class ChatMessageControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ChatMessageController,
          List<ChatMessage>
        > {
  /// See also [ChatMessageController].
  ChatMessageControllerProvider(String sessionId)
    : this._internal(
        () => ChatMessageController()..sessionId = sessionId,
        from: chatMessageControllerProvider,
        name: r'chatMessageControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatMessageControllerHash,
        dependencies: ChatMessageControllerFamily._dependencies,
        allTransitiveDependencies:
            ChatMessageControllerFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  ChatMessageControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  FutureOr<List<ChatMessage>> runNotifierBuild(
    covariant ChatMessageController notifier,
  ) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(ChatMessageController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatMessageControllerProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ChatMessageController,
    List<ChatMessage>
  >
  createElement() {
    return _ChatMessageControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessageControllerProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatMessageControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ChatMessageControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ChatMessageController,
          List<ChatMessage>
        >
    with ChatMessageControllerRef {
  _ChatMessageControllerProviderElement(super.provider);

  @override
  String get sessionId => (origin as ChatMessageControllerProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
