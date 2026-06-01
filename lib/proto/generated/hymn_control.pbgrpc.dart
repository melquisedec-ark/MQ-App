// This is a generated file - do not edit.
//
// Generated from hymn_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'hymn_control.pb.dart' as $0;

export 'hymn_control.pb.dart';

@$pb.GrpcServiceName('himnario.HymnControl')
class HymnControlClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HymnControlClient(super.channel, {super.options, super.interceptors});

  /// Comandos del controlador al display
  $grpc.ResponseFuture<$0.CommandResponse> sendCommand(
    $0.CommandRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendCommand, request, options: options);
  }

  /// Obtener estado actual del display
  $grpc.ResponseFuture<$0.DisplayStatus> getStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  /// Streaming de estado (el display notifica cambios en tiempo real)
  $grpc.ResponseStream<$0.DisplayStatus> watchStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchStatus, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Handshake de conexión inicial
  $grpc.ResponseFuture<$0.HandshakeResponse> handshake(
    $0.HandshakeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$handshake, request, options: options);
  }

  /// ─── NUEVOS RPCs ──────────────────────────────────────────
  /// Enviar contenido completo de un himno al display remoto.
  /// El controlador envía el payload completo (título + estrofas).
  $grpc.ResponseFuture<$0.CommandResponse> sendHymnContent(
    $0.HymnPayload request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendHymnContent, request, options: options);
  }

  /// Obtener lista de fondos disponibles en el PC (dueño de los archivos multimedia).
  $grpc.ResponseFuture<$0.BackgroundList> getAvailableBackgrounds(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAvailableBackgrounds, request,
        options: options);
  }

  // method descriptors

  static final _$sendCommand =
      $grpc.ClientMethod<$0.CommandRequest, $0.CommandResponse>(
          '/himnario.HymnControl/SendCommand',
          ($0.CommandRequest value) => value.writeToBuffer(),
          $0.CommandResponse.fromBuffer);
  static final _$getStatus = $grpc.ClientMethod<$0.Empty, $0.DisplayStatus>(
      '/himnario.HymnControl/GetStatus',
      ($0.Empty value) => value.writeToBuffer(),
      $0.DisplayStatus.fromBuffer);
  static final _$watchStatus = $grpc.ClientMethod<$0.Empty, $0.DisplayStatus>(
      '/himnario.HymnControl/WatchStatus',
      ($0.Empty value) => value.writeToBuffer(),
      $0.DisplayStatus.fromBuffer);
  static final _$handshake =
      $grpc.ClientMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
          '/himnario.HymnControl/Handshake',
          ($0.HandshakeRequest value) => value.writeToBuffer(),
          $0.HandshakeResponse.fromBuffer);
  static final _$sendHymnContent =
      $grpc.ClientMethod<$0.HymnPayload, $0.CommandResponse>(
          '/himnario.HymnControl/SendHymnContent',
          ($0.HymnPayload value) => value.writeToBuffer(),
          $0.CommandResponse.fromBuffer);
  static final _$getAvailableBackgrounds =
      $grpc.ClientMethod<$0.Empty, $0.BackgroundList>(
          '/himnario.HymnControl/GetAvailableBackgrounds',
          ($0.Empty value) => value.writeToBuffer(),
          $0.BackgroundList.fromBuffer);
}

@$pb.GrpcServiceName('himnario.HymnControl')
abstract class HymnControlServiceBase extends $grpc.Service {
  $core.String get $name => 'himnario.HymnControl';

  HymnControlServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CommandRequest, $0.CommandResponse>(
        'SendCommand',
        sendCommand_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CommandRequest.fromBuffer(value),
        ($0.CommandResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.DisplayStatus>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.DisplayStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.DisplayStatus>(
        'WatchStatus',
        watchStatus_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.DisplayStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
        'Handshake',
        handshake_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HandshakeRequest.fromBuffer(value),
        ($0.HandshakeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HymnPayload, $0.CommandResponse>(
        'SendHymnContent',
        sendHymnContent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HymnPayload.fromBuffer(value),
        ($0.CommandResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.BackgroundList>(
        'GetAvailableBackgrounds',
        getAvailableBackgrounds_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.BackgroundList value) => value.writeToBuffer()));
  }

  $async.Future<$0.CommandResponse> sendCommand_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CommandRequest> $request) async {
    return sendCommand($call, await $request);
  }

  $async.Future<$0.CommandResponse> sendCommand(
      $grpc.ServiceCall call, $0.CommandRequest request);

  $async.Future<$0.DisplayStatus> getStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.DisplayStatus> getStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$0.DisplayStatus> watchStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* watchStatus($call, await $request);
  }

  $async.Stream<$0.DisplayStatus> watchStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.HandshakeResponse> handshake_Pre($grpc.ServiceCall $call,
      $async.Future<$0.HandshakeRequest> $request) async {
    return handshake($call, await $request);
  }

  $async.Future<$0.HandshakeResponse> handshake(
      $grpc.ServiceCall call, $0.HandshakeRequest request);

  $async.Future<$0.CommandResponse> sendHymnContent_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.HymnPayload> $request) async {
    return sendHymnContent($call, await $request);
  }

  $async.Future<$0.CommandResponse> sendHymnContent(
      $grpc.ServiceCall call, $0.HymnPayload request);

  $async.Future<$0.BackgroundList> getAvailableBackgrounds_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAvailableBackgrounds($call, await $request);
  }

  $async.Future<$0.BackgroundList> getAvailableBackgrounds(
      $grpc.ServiceCall call, $0.Empty request);
}
