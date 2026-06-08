import '../models/transport_frame.dart';
import '../models/transport_frame_receive_result.dart';

abstract interface class TransportFrameReceiver {
  Future<TransportFrameReceiveResult> receive(TransportFrame frame);
}
