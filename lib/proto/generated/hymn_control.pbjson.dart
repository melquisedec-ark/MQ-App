// This is a generated file - do not edit.
//
// Generated from hymn_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use commandTypeDescriptor instead')
const CommandType$json = {
  '1': 'CommandType',
  '2': [
    {'1': 'NEXT_STANZA', '2': 0},
    {'1': 'PREV_STANZA', '2': 1},
    {'1': 'GO_TO_CHORUS', '2': 2},
    {'1': 'GO_TO_STANZA', '2': 3},
    {'1': 'BLACKOUT', '2': 4},
    {'1': 'CLEAR_BLACKOUT', '2': 5},
    {'1': 'SET_TRANSPOSITION', '2': 6},
    {'1': 'JUMP_TO_HYMN', '2': 7},
    {'1': 'SET_BACKGROUND', '2': 8},
    {'1': 'SET_FONT_SIZE', '2': 9},
    {'1': 'PING', '2': 10},
    {'1': 'SET_APPEARANCE', '2': 11},
  ],
};

/// Descriptor for `CommandType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List commandTypeDescriptor = $convert.base64Decode(
    'CgtDb21tYW5kVHlwZRIPCgtORVhUX1NUQU5aQRAAEg8KC1BSRVZfU1RBTlpBEAESEAoMR09fVE'
    '9fQ0hPUlVTEAISEAoMR09fVE9fU1RBTlpBEAMSDAoIQkxBQ0tPVVQQBBISCg5DTEVBUl9CTEFD'
    'S09VVBAFEhUKEVNFVF9UUkFOU1BPU0lUSU9OEAYSEAoMSlVNUF9UT19IWU1OEAcSEgoOU0VUX0'
    'JBQ0tHUk9VTkQQCBIRCg1TRVRfRk9OVF9TSVpFEAkSCAoEUElORxAKEhIKDlNFVF9BUFBFQVJB'
    'TkNFEAs=');

@$core.Deprecated('Use hymnPayloadDescriptor instead')
const HymnPayload$json = {
  '1': 'HymnPayload',
  '2': [
    {'1': 'hymn_id', '3': 1, '4': 1, '5': 5, '10': 'hymnId'},
    {'1': 'titulo', '3': 2, '4': 1, '5': 9, '10': 'titulo'},
    {'1': 'numero', '3': 3, '4': 1, '5': 5, '9': 0, '10': 'numero', '17': true},
    {'1': 'tipo', '3': 4, '4': 1, '5': 9, '10': 'tipo'},
    {'1': 'version_pais_id', '3': 5, '4': 1, '5': 5, '10': 'versionPaisId'},
    {
      '1': 'estrofas',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.himnario.StanzaPayload',
      '10': 'estrofas'
    },
  ],
  '8': [
    {'1': '_numero'},
  ],
};

/// Descriptor for `HymnPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hymnPayloadDescriptor = $convert.base64Decode(
    'CgtIeW1uUGF5bG9hZBIXCgdoeW1uX2lkGAEgASgFUgZoeW1uSWQSFgoGdGl0dWxvGAIgASgJUg'
    'Z0aXR1bG8SGwoGbnVtZXJvGAMgASgFSABSBm51bWVyb4gBARISCgR0aXBvGAQgASgJUgR0aXBv'
    'EiYKD3ZlcnNpb25fcGFpc19pZBgFIAEoBVINdmVyc2lvblBhaXNJZBIzCghlc3Ryb2ZhcxgGIA'
    'MoCzIXLmhpbW5hcmlvLlN0YW56YVBheWxvYWRSCGVzdHJvZmFzQgkKB19udW1lcm8=');

@$core.Deprecated('Use stanzaPayloadDescriptor instead')
const StanzaPayload$json = {
  '1': 'StanzaPayload',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'version_pais_id', '3': 2, '4': 1, '5': 5, '10': 'versionPaisId'},
    {'1': 'tipo', '3': 3, '4': 1, '5': 9, '10': 'tipo'},
    {'1': 'orden', '3': 4, '4': 1, '5': 5, '10': 'orden'},
    {'1': 'contenido', '3': 5, '4': 1, '5': 9, '10': 'contenido'},
  ],
};

/// Descriptor for `StanzaPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stanzaPayloadDescriptor = $convert.base64Decode(
    'Cg1TdGFuemFQYXlsb2FkEg4KAmlkGAEgASgFUgJpZBImCg92ZXJzaW9uX3BhaXNfaWQYAiABKA'
    'VSDXZlcnNpb25QYWlzSWQSEgoEdGlwbxgDIAEoCVIEdGlwbxIUCgVvcmRlbhgEIAEoBVIFb3Jk'
    'ZW4SHAoJY29udGVuaWRvGAUgASgJUgljb250ZW5pZG8=');

@$core.Deprecated('Use backgroundInfoDescriptor instead')
const BackgroundInfo$json = {
  '1': 'BackgroundInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'nombre', '3': 2, '4': 1, '5': 9, '10': 'nombre'},
    {'1': 'tipo', '3': 3, '4': 1, '5': 9, '10': 'tipo'},
  ],
};

/// Descriptor for `BackgroundInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundInfoDescriptor = $convert.base64Decode(
    'Cg5CYWNrZ3JvdW5kSW5mbxIOCgJpZBgBIAEoBVICaWQSFgoGbm9tYnJlGAIgASgJUgZub21icm'
    'USEgoEdGlwbxgDIAEoCVIEdGlwbw==');

@$core.Deprecated('Use backgroundListDescriptor instead')
const BackgroundList$json = {
  '1': 'BackgroundList',
  '2': [
    {
      '1': 'backgrounds',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.himnario.BackgroundInfo',
      '10': 'backgrounds'
    },
  ],
};

/// Descriptor for `BackgroundList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundListDescriptor = $convert.base64Decode(
    'Cg5CYWNrZ3JvdW5kTGlzdBI6CgtiYWNrZ3JvdW5kcxgBIAMoCzIYLmhpbW5hcmlvLkJhY2tncm'
    '91bmRJbmZvUgtiYWNrZ3JvdW5kcw==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use commandRequestDescriptor instead')
const CommandRequest$json = {
  '1': 'CommandRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.himnario.CommandType',
      '10': 'type'
    },
    {'1': 'stanza_index', '3': 2, '4': 1, '5': 5, '10': 'stanzaIndex'},
    {'1': 'semitones', '3': 3, '4': 1, '5': 5, '10': 'semitones'},
    {'1': 'hymn_id', '3': 4, '4': 1, '5': 5, '10': 'hymnId'},
    {'1': 'background_id', '3': 5, '4': 1, '5': 9, '10': 'backgroundId'},
    {'1': 'font_size', '3': 6, '4': 1, '5': 2, '10': 'fontSize'},
    {
      '1': 'text_color',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'textColor',
      '17': true
    },
    {
      '1': 'chord_color',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'chordColor',
      '17': true
    },
    {
      '1': 'font_family',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'fontFamily',
      '17': true
    },
    {
      '1': 'is_bold',
      '3': 10,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'isBold',
      '17': true
    },
    {
      '1': 'show_chords',
      '3': 11,
      '4': 1,
      '5': 8,
      '9': 4,
      '10': 'showChords',
      '17': true
    },
    {
      '1': 'card_opacity',
      '3': 12,
      '4': 1,
      '5': 2,
      '9': 5,
      '10': 'cardOpacity',
      '17': true
    },
    {
      '1': 'projection_font_scale',
      '3': 13,
      '4': 1,
      '5': 2,
      '9': 6,
      '10': 'projectionFontScale',
      '17': true
    },
    {
      '1': 'bg_color',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'bgColor',
      '17': true
    },
  ],
  '8': [
    {'1': '_text_color'},
    {'1': '_chord_color'},
    {'1': '_font_family'},
    {'1': '_is_bold'},
    {'1': '_show_chords'},
    {'1': '_card_opacity'},
    {'1': '_projection_font_scale'},
    {'1': '_bg_color'},
  ],
};

/// Descriptor for `CommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commandRequestDescriptor = $convert.base64Decode(
    'Cg5Db21tYW5kUmVxdWVzdBIpCgR0eXBlGAEgASgOMhUuaGltbmFyaW8uQ29tbWFuZFR5cGVSBH'
    'R5cGUSIQoMc3RhbnphX2luZGV4GAIgASgFUgtzdGFuemFJbmRleBIcCglzZW1pdG9uZXMYAyAB'
    'KAVSCXNlbWl0b25lcxIXCgdoeW1uX2lkGAQgASgFUgZoeW1uSWQSIwoNYmFja2dyb3VuZF9pZB'
    'gFIAEoCVIMYmFja2dyb3VuZElkEhsKCWZvbnRfc2l6ZRgGIAEoAlIIZm9udFNpemUSIgoKdGV4'
    'dF9jb2xvchgHIAEoCUgAUgl0ZXh0Q29sb3KIAQESJAoLY2hvcmRfY29sb3IYCCABKAlIAVIKY2'
    'hvcmRDb2xvcogBARIkCgtmb250X2ZhbWlseRgJIAEoCUgCUgpmb250RmFtaWx5iAEBEhwKB2lz'
    'X2JvbGQYCiABKAhIA1IGaXNCb2xkiAEBEiQKC3Nob3dfY2hvcmRzGAsgASgISARSCnNob3dDaG'
    '9yZHOIAQESJgoMY2FyZF9vcGFjaXR5GAwgASgCSAVSC2NhcmRPcGFjaXR5iAEBEjcKFXByb2pl'
    'Y3Rpb25fZm9udF9zY2FsZRgNIAEoAkgGUhNwcm9qZWN0aW9uRm9udFNjYWxliAEBEh4KCGJnX2'
    'NvbG9yGA4gASgJSAdSB2JnQ29sb3KIAQFCDQoLX3RleHRfY29sb3JCDgoMX2Nob3JkX2NvbG9y'
    'Qg4KDF9mb250X2ZhbWlseUIKCghfaXNfYm9sZEIOCgxfc2hvd19jaG9yZHNCDwoNX2NhcmRfb3'
    'BhY2l0eUIYChZfcHJvamVjdGlvbl9mb250X3NjYWxlQgsKCV9iZ19jb2xvcg==');

@$core.Deprecated('Use commandResponseDescriptor instead')
const CommandResponse$json = {
  '1': 'CommandResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error_message', '3': 2, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `CommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commandResponseDescriptor = $convert.base64Decode(
    'Cg9Db21tYW5kUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIjCg1lcnJvcl9tZX'
    'NzYWdlGAIgASgJUgxlcnJvck1lc3NhZ2U=');

@$core.Deprecated('Use displayStatusDescriptor instead')
const DisplayStatus$json = {
  '1': 'DisplayStatus',
  '2': [
    {'1': 'current_hymn_id', '3': 1, '4': 1, '5': 5, '10': 'currentHymnId'},
    {
      '1': 'current_hymn_title',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'currentHymnTitle'
    },
    {
      '1': 'current_stanza_index',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'currentStanzaIndex'
    },
    {'1': 'total_stanzas', '3': 4, '4': 1, '5': 5, '10': 'totalStanzas'},
    {
      '1': 'transposition_semitones',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'transpositionSemitones'
    },
    {'1': 'is_blackout', '3': 6, '4': 1, '5': 8, '10': 'isBlackout'},
    {
      '1': 'current_background_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'currentBackgroundId'
    },
    {'1': 'font_size', '3': 8, '4': 1, '5': 2, '10': 'fontSize'},
    {'1': 'display_name', '3': 9, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'text_color',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'textColor',
      '17': true
    },
    {
      '1': 'chord_color',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'chordColor',
      '17': true
    },
    {
      '1': 'font_family',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'fontFamily',
      '17': true
    },
    {
      '1': 'is_bold',
      '3': 13,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'isBold',
      '17': true
    },
    {
      '1': 'show_chords',
      '3': 14,
      '4': 1,
      '5': 8,
      '9': 4,
      '10': 'showChords',
      '17': true
    },
    {
      '1': 'card_opacity',
      '3': 15,
      '4': 1,
      '5': 2,
      '9': 5,
      '10': 'cardOpacity',
      '17': true
    },
    {
      '1': 'projection_font_scale',
      '3': 16,
      '4': 1,
      '5': 2,
      '9': 6,
      '10': 'projectionFontScale',
      '17': true
    },
  ],
  '8': [
    {'1': '_text_color'},
    {'1': '_chord_color'},
    {'1': '_font_family'},
    {'1': '_is_bold'},
    {'1': '_show_chords'},
    {'1': '_card_opacity'},
    {'1': '_projection_font_scale'},
  ],
};

/// Descriptor for `DisplayStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List displayStatusDescriptor = $convert.base64Decode(
    'Cg1EaXNwbGF5U3RhdHVzEiYKD2N1cnJlbnRfaHltbl9pZBgBIAEoBVINY3VycmVudEh5bW5JZB'
    'IsChJjdXJyZW50X2h5bW5fdGl0bGUYAiABKAlSEGN1cnJlbnRIeW1uVGl0bGUSMAoUY3VycmVu'
    'dF9zdGFuemFfaW5kZXgYAyABKAVSEmN1cnJlbnRTdGFuemFJbmRleBIjCg10b3RhbF9zdGFuem'
    'FzGAQgASgFUgx0b3RhbFN0YW56YXMSNwoXdHJhbnNwb3NpdGlvbl9zZW1pdG9uZXMYBSABKAVS'
    'FnRyYW5zcG9zaXRpb25TZW1pdG9uZXMSHwoLaXNfYmxhY2tvdXQYBiABKAhSCmlzQmxhY2tvdX'
    'QSMgoVY3VycmVudF9iYWNrZ3JvdW5kX2lkGAcgASgJUhNjdXJyZW50QmFja2dyb3VuZElkEhsK'
    'CWZvbnRfc2l6ZRgIIAEoAlIIZm9udFNpemUSIQoMZGlzcGxheV9uYW1lGAkgASgJUgtkaXNwbG'
    'F5TmFtZRIiCgp0ZXh0X2NvbG9yGAogASgJSABSCXRleHRDb2xvcogBARIkCgtjaG9yZF9jb2xv'
    'chgLIAEoCUgBUgpjaG9yZENvbG9yiAEBEiQKC2ZvbnRfZmFtaWx5GAwgASgJSAJSCmZvbnRGYW'
    '1pbHmIAQESHAoHaXNfYm9sZBgNIAEoCEgDUgZpc0JvbGSIAQESJAoLc2hvd19jaG9yZHMYDiAB'
    'KAhIBFIKc2hvd0Nob3Jkc4gBARImCgxjYXJkX29wYWNpdHkYDyABKAJIBVILY2FyZE9wYWNpdH'
    'mIAQESNwoVcHJvamVjdGlvbl9mb250X3NjYWxlGBAgASgCSAZSE3Byb2plY3Rpb25Gb250U2Nh'
    'bGWIAQFCDQoLX3RleHRfY29sb3JCDgoMX2Nob3JkX2NvbG9yQg4KDF9mb250X2ZhbWlseUIKCg'
    'hfaXNfYm9sZEIOCgxfc2hvd19jaG9yZHNCDwoNX2NhcmRfb3BhY2l0eUIYChZfcHJvamVjdGlv'
    'bl9mb250X3NjYWxl');

@$core.Deprecated('Use handshakeRequestDescriptor instead')
const HandshakeRequest$json = {
  '1': 'HandshakeRequest',
  '2': [
    {'1': 'client_name', '3': 1, '4': 1, '5': 9, '10': 'clientName'},
    {'1': 'client_version', '3': 2, '4': 1, '5': 9, '10': 'clientVersion'},
    {'1': 'protocol_version', '3': 3, '4': 1, '5': 5, '10': 'protocolVersion'},
  ],
};

/// Descriptor for `HandshakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeRequestDescriptor = $convert.base64Decode(
    'ChBIYW5kc2hha2VSZXF1ZXN0Eh8KC2NsaWVudF9uYW1lGAEgASgJUgpjbGllbnROYW1lEiUKDm'
    'NsaWVudF92ZXJzaW9uGAIgASgJUg1jbGllbnRWZXJzaW9uEikKEHByb3RvY29sX3ZlcnNpb24Y'
    'AyABKAVSD3Byb3RvY29sVmVyc2lvbg==');

@$core.Deprecated('Use handshakeResponseDescriptor instead')
const HandshakeResponse$json = {
  '1': 'HandshakeResponse',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'server_name', '3': 2, '4': 1, '5': 9, '10': 'serverName'},
    {'1': 'server_version', '3': 3, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'protocol_version', '3': 5, '4': 1, '5': 5, '10': 'protocolVersion'},
    {'1': 'session_id', '3': 6, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `HandshakeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeResponseDescriptor = $convert.base64Decode(
    'ChFIYW5kc2hha2VSZXNwb25zZRIaCghhY2NlcHRlZBgBIAEoCFIIYWNjZXB0ZWQSHwoLc2Vydm'
    'VyX25hbWUYAiABKAlSCnNlcnZlck5hbWUSJQoOc2VydmVyX3ZlcnNpb24YAyABKAlSDXNlcnZl'
    'clZlcnNpb24SIQoMZGlzcGxheV9uYW1lGAQgASgJUgtkaXNwbGF5TmFtZRIpChBwcm90b2NvbF'
    '92ZXJzaW9uGAUgASgFUg9wcm90b2NvbFZlcnNpb24SHQoKc2Vzc2lvbl9pZBgGIAEoCVIJc2Vz'
    'c2lvbklk');
