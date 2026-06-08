import '../models/transport_frame.dart';

abstract interface class TransportFrameHandler {
  Future<void> handleFrame(TransportFrame frame);
}
