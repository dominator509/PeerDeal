class ProtocolVersion implements Comparable<ProtocolVersion> {
  const ProtocolVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  factory ProtocolVersion.parse(String input) {
    final parts = input.split('.');
    if (parts.length != 3) {
      throw FormatException('Expected major.minor.patch, got $input');
    }
    return ProtocolVersion(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String toWire() => '$major.$minor.$patch';

  @override
  int compareTo(ProtocolVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => toWire();

  @override
  bool operator ==(Object other) =>
      other is ProtocolVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
