import '../models/transport_frame.dart';

abstract interface class TransportFrameSink {
  Future<void> sendFrame(TransportFrame frame);
}
