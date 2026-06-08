import '../models/transport_frame.dart';
import '../models/transport_frame_send_result.dart';

abstract interface class TransportFrameSender {
  Future<TransportFrameSendResult> send(TransportFrame frame);
}
