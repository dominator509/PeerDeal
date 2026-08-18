import 'package:peerdeal_protocol/peerdeal_protocol.dart';

abstract final class HoldemInputLimits {
  static const defaultMaxSeats = 9;
  static const defaultMaxCommitments = defaultMaxSeats;
  static const defaultMaxShowdownResults = defaultMaxSeats;
  static const defaultMaxPotSlices = defaultMaxSeats;
  static const defaultMaxSeatIdsPerSlice = defaultMaxSeats;
  static final defaultMaxTextBytes = CanonicalJsonLimits().maxTextBytes;
}
