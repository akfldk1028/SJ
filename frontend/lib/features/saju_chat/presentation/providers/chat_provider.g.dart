// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'e56551aac747a58f8c60f6a7b336767405478a25';

/// ChatRepository Provider
///
/// Copied from [chatRepository].
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
String _$chatNotifierHash() => r'3883a00971829a35e9e9d2b4ecb51d72b6af85df';

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

abstract class _$ChatNotifier extends BuildlessAutoDisposeNotifier<ChatState> {
  late final ChatType chatType;

  ChatState build(ChatType chatType);
}

/// 채팅 상태 관리 Provider
///
/// Copied from [ChatNotifier].
@ProviderFor(ChatNotifier)
const chatNotifierProvider = ChatNotifierFamily();

/// 채팅 상태 관리 Provider
///
/// Copied from [ChatNotifier].
class ChatNotifierFamily extends Family<ChatState> {
  /// 채팅 상태 관리 Provider
  ///
  /// Copied from [ChatNotifier].
  const ChatNotifierFamily();

  /// 채팅 상태 관리 Provider
  ///
  /// Copied from [ChatNotifier].
  ChatNotifierProvider call(ChatType chatType) {
    return ChatNotifierProvider(chatType);
  }

  @override
  ChatNotifierProvider getProviderOverride(
    covariant ChatNotifierProvider provider,
  ) {
    return call(provider.chatType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatNotifierProvider';
}

/// 채팅 상태 관리 Provider
///
/// Copied from [ChatNotifier].
class ChatNotifierProvider
    extends AutoDisposeNotifierProviderImpl<ChatNotifier, ChatState> {
  /// 채팅 상태 관리 Provider
  ///
  /// Copied from [ChatNotifier].
  ChatNotifierProvider(ChatType chatType)
    : this._internal(
        () => ChatNotifier()..chatType = chatType,
        from: chatNotifierProvider,
        name: r'chatNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatNotifierHash,
        dependencies: ChatNotifierFamily._dependencies,
        allTransitiveDependencies:
            ChatNotifierFamily._allTransitiveDependencies,
        chatType: chatType,
      );

  ChatNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatType,
  }) : super.internal();

  final ChatType chatType;

  @override
  ChatState runNotifierBuild(covariant ChatNotifier notifier) {
    return notifier.build(chatType);
  }

  @override
  Override overrideWith(ChatNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatNotifierProvider._internal(
        () => create()..chatType = chatType,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatType: chatType,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ChatNotifier, ChatState> createElement() {
    return _ChatNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatNotifierProvider && other.chatType == chatType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatNotifierRef on AutoDisposeNotifierProviderRef<ChatState> {
  /// The parameter `chatType` of this provider.
  ChatType get chatType;
}

class _ChatNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ChatNotifier, ChatState>
    with ChatNotifierRef {
  _ChatNotifierProviderElement(super.provider);

  @override
  ChatType get chatType => (origin as ChatNotifierProvider).chatType;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
