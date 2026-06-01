// This is a generated file - do not edit.
//
// Generated from hymn_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CommandType extends $pb.ProtobufEnum {
  static const CommandType NEXT_STANZA =
      CommandType._(0, _omitEnumNames ? '' : 'NEXT_STANZA');
  static const CommandType PREV_STANZA =
      CommandType._(1, _omitEnumNames ? '' : 'PREV_STANZA');
  static const CommandType GO_TO_CHORUS =
      CommandType._(2, _omitEnumNames ? '' : 'GO_TO_CHORUS');
  static const CommandType GO_TO_STANZA =
      CommandType._(3, _omitEnumNames ? '' : 'GO_TO_STANZA');
  static const CommandType BLACKOUT =
      CommandType._(4, _omitEnumNames ? '' : 'BLACKOUT');
  static const CommandType CLEAR_BLACKOUT =
      CommandType._(5, _omitEnumNames ? '' : 'CLEAR_BLACKOUT');
  static const CommandType SET_TRANSPOSITION =
      CommandType._(6, _omitEnumNames ? '' : 'SET_TRANSPOSITION');
  static const CommandType JUMP_TO_HYMN =
      CommandType._(7, _omitEnumNames ? '' : 'JUMP_TO_HYMN');
  static const CommandType SET_BACKGROUND =
      CommandType._(8, _omitEnumNames ? '' : 'SET_BACKGROUND');
  static const CommandType SET_FONT_SIZE =
      CommandType._(9, _omitEnumNames ? '' : 'SET_FONT_SIZE');
  static const CommandType PING =
      CommandType._(10, _omitEnumNames ? '' : 'PING');
  static const CommandType SET_APPEARANCE =
      CommandType._(11, _omitEnumNames ? '' : 'SET_APPEARANCE');

  static const $core.List<CommandType> values = <CommandType>[
    NEXT_STANZA,
    PREV_STANZA,
    GO_TO_CHORUS,
    GO_TO_STANZA,
    BLACKOUT,
    CLEAR_BLACKOUT,
    SET_TRANSPOSITION,
    JUMP_TO_HYMN,
    SET_BACKGROUND,
    SET_FONT_SIZE,
    PING,
    SET_APPEARANCE,
  ];

  static final $core.List<CommandType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static CommandType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CommandType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
