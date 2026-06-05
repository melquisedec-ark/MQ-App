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

  /// ─── BIBLE MODULE COMMANDS ─────────────────────────────────
  /// Se reservan los valores 20+ para no colisionar con himnario.
  static const CommandType NEXT_VERSE =
      CommandType._(20, _omitEnumNames ? '' : 'NEXT_VERSE');
  static const CommandType PREV_VERSE =
      CommandType._(21, _omitEnumNames ? '' : 'PREV_VERSE');
  static const CommandType NEXT_CHAPTER =
      CommandType._(22, _omitEnumNames ? '' : 'NEXT_CHAPTER');
  static const CommandType PREV_CHAPTER =
      CommandType._(23, _omitEnumNames ? '' : 'PREV_CHAPTER');
  static const CommandType GO_TO_VERSE =
      CommandType._(24, _omitEnumNames ? '' : 'GO_TO_VERSE');
  static const CommandType TOGGLE_FAVORITE =
      CommandType._(25, _omitEnumNames ? '' : 'TOGGLE_FAVORITE');
  static const CommandType SWITCH_TO_BIBLE =
      CommandType._(26, _omitEnumNames ? '' : 'SWITCH_TO_BIBLE');
  static const CommandType SWITCH_TO_HIMNAL =
      CommandType._(27, _omitEnumNames ? '' : 'SWITCH_TO_HIMNAL');
  static const CommandType SET_EMITTER_VIEW_MODE =
      CommandType._(28, _omitEnumNames ? '' : 'SET_EMITTER_VIEW_MODE');
  static const CommandType SET_BIBLE_THEME =
      CommandType._(29, _omitEnumNames ? '' : 'SET_BIBLE_THEME');
  static const CommandType SET_BIBLE_FONT_SCALE =
      CommandType._(30, _omitEnumNames ? '' : 'SET_BIBLE_FONT_SCALE');

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
    NEXT_VERSE,
    PREV_VERSE,
    NEXT_CHAPTER,
    PREV_CHAPTER,
    GO_TO_VERSE,
    TOGGLE_FAVORITE,
    SWITCH_TO_BIBLE,
    SWITCH_TO_HIMNAL,
    SET_EMITTER_VIEW_MODE,
    SET_BIBLE_THEME,
    SET_BIBLE_FONT_SCALE,
  ];

  static final $core.List<CommandType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 30);
  static CommandType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CommandType._(super.value, super.name);
}

/// Módulo actualmente activo en el display.
/// 0 = UNKNOWN (default proto3 — no usar en código de negocio).
class ModuleType extends $pb.ProtobufEnum {
  static const ModuleType MODULE_UNKNOWN =
      ModuleType._(0, _omitEnumNames ? '' : 'MODULE_UNKNOWN');
  static const ModuleType MODULE_BIBLIA =
      ModuleType._(1, _omitEnumNames ? '' : 'MODULE_BIBLIA');
  static const ModuleType MODULE_HIMNARIO =
      ModuleType._(2, _omitEnumNames ? '' : 'MODULE_HIMNARIO');

  static const $core.List<ModuleType> values = <ModuleType>[
    MODULE_UNKNOWN,
    MODULE_BIBLIA,
    MODULE_HIMNARIO,
  ];

  static final $core.List<ModuleType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ModuleType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModuleType._(super.value, super.name);
}

/// Modo de vista del emisor (afecta cómo se muestra la preview en el celular).
/// 0 = UNKNOWN; 1 = COMPACT (número + preview mini); 2 = PREVIEW (texto completo).
class EmitterViewMode extends $pb.ProtobufEnum {
  static const EmitterViewMode VIEW_MODE_UNKNOWN =
      EmitterViewMode._(0, _omitEnumNames ? '' : 'VIEW_MODE_UNKNOWN');
  static const EmitterViewMode VIEW_MODE_COMPACT =
      EmitterViewMode._(1, _omitEnumNames ? '' : 'VIEW_MODE_COMPACT');
  static const EmitterViewMode VIEW_MODE_PREVIEW =
      EmitterViewMode._(2, _omitEnumNames ? '' : 'VIEW_MODE_PREVIEW');

  static const $core.List<EmitterViewMode> values = <EmitterViewMode>[
    VIEW_MODE_UNKNOWN,
    VIEW_MODE_COMPACT,
    VIEW_MODE_PREVIEW,
  ];

  static final $core.List<EmitterViewMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static EmitterViewMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EmitterViewMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
