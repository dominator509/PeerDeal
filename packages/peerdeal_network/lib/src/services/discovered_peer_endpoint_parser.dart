import '../models/bootstrap_candidate.dart';
import '../models/discovered_peer_endpoint.dart';
import '../models/network_input_limits.dart';

/// Parses the existing native discovery value format:
/// `peer-id` or `peer-id@host[:port]`.
class DiscoveredPeerEndpointParser {
  const DiscoveredPeerEndpointParser._();

  static List<DiscoveredPeerEndpoint> parseAll(
    Iterable<String> values, {
    int maxValues = NetworkInputLimits.defaultMaxPeerIds,
  }) {
    if (maxValues < 1) return const <DiscoveredPeerEndpoint>[];
    final seen = <String>{};
    final result = <DiscoveredPeerEndpoint>[];
    for (final value in values) {
      if (result.length == maxValues) break;
      final endpoint = parse(value);
      if (endpoint == null || !seen.add(endpoint.peerId)) continue;
      result.add(endpoint);
    }
    return List<DiscoveredPeerEndpoint>.unmodifiable(result);
  }

  static DiscoveredPeerEndpoint? parse(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty || _looksSensitive(normalized)) return null;

    final separator = normalized.indexOf('@');
    if (separator < 0) {
      final peerId = _safePeerId(normalized);
      if (peerId.isEmpty) return null;
      return DiscoveredPeerEndpoint(peerId: peerId, host: '');
    }
    if (separator == 0 || separator == normalized.length - 1) return null;

    final peerId = _safePeerId(normalized.substring(0, separator));
    final hostPort = _parseHostPort(normalized.substring(separator + 1));
    if (peerId.isEmpty || hostPort == null) return null;
    return DiscoveredPeerEndpoint(
      peerId: peerId,
      host: hostPort.host,
      port: hostPort.port,
    );
  }

  static List<BootstrapCandidate> projectCandidates(
    Iterable<BootstrapCandidate> candidates,
    Iterable<DiscoveredPeerEndpoint> endpoints,
  ) {
    final byPeerId = <String, DiscoveredPeerEndpoint>{
      for (final endpoint in endpoints)
        if (endpoint.host.isNotEmpty) endpoint.peerId: endpoint,
    };
    return candidates
        .map((candidate) {
          final endpoint = byPeerId[candidate.peerId];
          if (endpoint == null) return candidate;
          return BootstrapCandidate(
            peerId: candidate.peerId,
            routeClass: candidate.routeClass,
            reachable: candidate.reachable,
            priority: candidate.priority,
            host: candidate.host ?? endpoint.host,
            port: candidate.port ?? endpoint.port,
            reason: candidate.reason,
          );
        })
        .toList(growable: false);
  }

  static String _normalize(String value) => value
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _safePeerId(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty || _looksSensitive(normalized)) return '';
    const maxLength = 96;
    return normalized.length <= maxLength
        ? normalized
        : normalized.substring(0, maxLength);
  }

  static _HostPort? _parseHostPort(String value) {
    final location = value.trim();
    if (location.isEmpty || location.length > 253) return null;

    String host;
    int? port;
    if (location.startsWith('[')) {
      final closingBracket = location.indexOf(']');
      if (closingBracket <= 1) return null;
      host = location.substring(1, closingBracket);
      final suffix = location.substring(closingBracket + 1);
      if (suffix.isNotEmpty) {
        if (!suffix.startsWith(':')) return null;
        port = _parsePort(suffix.substring(1));
        if (port == null) return null;
      }
    } else {
      final colonCount = ':'.allMatches(location).length;
      if (colonCount == 1) {
        final separator = location.lastIndexOf(':');
        host = location.substring(0, separator);
        port = _parsePort(location.substring(separator + 1));
        if (port == null) return null;
      } else {
        host = location;
      }
    }

    if (!_isSafeHost(host)) return null;
    return _HostPort(host: host, port: port);
  }

  static int? _parsePort(String value) {
    final port = int.tryParse(value);
    return port != null && port > 0 && port <= 65535 ? port : null;
  }

  static bool _isSafeHost(String host) {
    if (host.isEmpty || host.length > 253 || _looksSensitive(host)) {
      return false;
    }
    if (host.contains(':')) {
      return RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(host);
    }
    return RegExp(r'^[A-Za-z0-9.-]+$').hasMatch(host) &&
        !host.startsWith('.') &&
        !host.endsWith('.') &&
        !host.startsWith('-') &&
        !host.endsWith('-');
  }

  static bool _looksSensitive(String value) {
    final lower = value.toLowerCase();
    return lower.contains('secret') ||
        lower.contains('token') ||
        lower.contains('password') ||
        value.contains('\\');
  }
}

class _HostPort {
  const _HostPort({required this.host, this.port});

  final String host;
  final int? port;
}
