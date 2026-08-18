import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/provider_proof_normalizer.dart';
import '../models/deal_proof_bundle.dart';
import '../models/deal_proof_limits.dart';

class DefaultProviderProofNormalizer implements ProviderProofNormalizer {
  const DefaultProviderProofNormalizer({this.limits = const DealProofLimits()});

  final DealProofLimits limits;

  @override
  DealProofBundle normalize({
    required String providerId,
    required String providerVersion,
    required Map<String, Object?> rawProof,
  }) {
    limits.validate();
    _requireSafeTextWithinLimit(
      providerId,
      limits.maxProviderIdBytes,
      'Provider id',
    );
    _requireSafeTextWithinLimit(
      providerVersion,
      limits.maxProviderVersionBytes,
      'Provider version',
    );

    final boundedProof = _BoundedProofCopier(limits).copyMap(rawProof);
    final proofReference = _proofReferenceFrom(boundedProof);
    _requireSafeTextWithinLimit(
      proofReference,
      limits.maxProofReferenceBytes,
      'Proof reference',
    );

    try {
      final encodedProof = canonicalJsonEncode(boundedProof);
      if (!CanonicalJsonLimits(
        maxTextBytes: limits.maxProofBytes,
      ).isWithinUtf8TextLimit(encodedProof)) {
        throw const FormatException('Provider proof payload is too large.');
      }
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Provider proof payload is not encodable.');
    }

    return DealProofBundle(
      providerId: providerId,
      providerVersion: providerVersion,
      proofReference: proofReference,
      normalizedFields: boundedProof,
      rawPayload: boundedProof,
    );
  }

  static String _proofReferenceFrom(Map<String, Object?> proof) {
    final hasSnakeCase = proof.containsKey('proof_ref');
    final hasCamelCase = proof.containsKey('proofReference');
    if (hasSnakeCase && hasCamelCase) {
      throw const FormatException(
        'Provider proof contains ambiguous proof reference fields.',
      );
    }

    if (!hasSnakeCase && !hasCamelCase) return 'unknown';
    final value = proof[hasSnakeCase ? 'proof_ref' : 'proofReference'];
    if (value is! String) {
      throw const FormatException('Provider proof reference must be a string.');
    }
    return value;
  }

  static void _requireTextWithinLimit(
    String value,
    int maxBytes,
    String label,
  ) {
    if (!CanonicalJsonLimits(
      maxTextBytes: maxBytes,
    ).isWithinUtf8TextLimit(value)) {
      throw FormatException('$label exceeds its configured byte limit.');
    }
  }

  static void _requireSafeTextWithinLimit(
    String value,
    int maxBytes,
    String label,
  ) {
    _requireTextWithinLimit(value, maxBytes, label);
    if (value.trim().isEmpty || value.trim() != value) {
      throw FormatException('$label must be non-empty and unpadded.');
    }
    if (value.codeUnits.any(
      (codeUnit) => codeUnit < 0x20 || (codeUnit >= 0x7f && codeUnit <= 0x9f),
    )) {
      throw FormatException('$label contains a control character.');
    }
  }
}

class _BoundedProofCopier {
  _BoundedProofCopier(this.limits);

  final DealProofLimits limits;
  var _nodes = 0;

  Map<String, Object?> copyMap(Map<dynamic, dynamic> input) {
    return _copyMap(input, 0);
  }

  Object? copyValue(Object? value, int depth) {
    _checkDepth(depth);
    if (value is Map) {
      return _copyMap(value, depth);
    }
    if (value is List) {
      return _copyList(value, depth);
    }
    _consumeNode();
    if (value is String) {
      DefaultProviderProofNormalizer._requireTextWithinLimit(
        value,
        limits.maxTextBytes,
        'Provider proof text',
      );
      return value;
    }
    if (value is num) {
      if (value is double && !value.isFinite) {
        throw const FormatException(
          'Provider proof contains a non-finite number.',
        );
      }
      return value;
    }
    if (value is bool || value == null) {
      return value;
    }
    throw const FormatException(
      'Provider proof contains an unsupported value.',
    );
  }

  Map<String, Object?> _copyMap(Map<dynamic, dynamic> input, int depth) {
    _checkDepth(depth);
    _consumeNode();
    if (input.length > limits.maxMapEntries) {
      throw const FormatException(
        'Provider proof object has too many entries.',
      );
    }

    final output = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException(
          'Provider proof object contains a non-string key.',
        );
      }
      DefaultProviderProofNormalizer._requireTextWithinLimit(
        key,
        limits.maxTextBytes,
        'Provider proof key',
      );
      output[key] = copyValue(entry.value, depth + 1);
    }
    return Map<String, Object?>.unmodifiable(output);
  }

  List<Object?> _copyList(List<dynamic> input, int depth) {
    _checkDepth(depth);
    _consumeNode();
    if (input.length > limits.maxListItems) {
      throw const FormatException('Provider proof array has too many items.');
    }
    return List<Object?>.unmodifiable(
      input.map((value) => copyValue(value, depth + 1)),
    );
  }

  void _checkDepth(int depth) {
    if (depth > limits.maxDepth) {
      throw const FormatException('Provider proof nesting is too deep.');
    }
  }

  void _consumeNode() {
    _nodes += 1;
    if (_nodes > limits.maxNodes) {
      throw const FormatException('Provider proof contains too many nodes.');
    }
  }
}
