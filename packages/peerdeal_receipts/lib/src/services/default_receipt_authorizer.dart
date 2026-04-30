import '../contracts/receipt_authorizer.dart';
import '../models/peer_deal_receipt.dart';
import '../models/receipt_access_mode.dart';
import '../models/receipt_authorization_request.dart';
import '../models/receipt_authorization_result.dart';
import '../models/receipt_binding_mode.dart';
import '../models/receipt_wipe_state.dart';

class DefaultReceiptAuthorizer implements ReceiptAuthorizer {
  const DefaultReceiptAuthorizer();

  @override
  ReceiptAuthorizationResult authorize(
    PeerDealReceipt receipt,
    ReceiptAuthorizationRequest request,
  ) {
    if (receipt.wipeState == ReceiptWipeState.wiped) {
      return const ReceiptAuthorizationResult(
        allowed: false,
        normalizedResultCode: 'ERR_RECEIPT_WIPED',
        message: 'Receipt unavailable.',
      );
    }

    if (request.accessMode == ReceiptAccessMode.view) {
      return const ReceiptAuthorizationResult(
        allowed: true,
        normalizedResultCode: 'OK_RECEIPT_VIEW_ALLOWED',
        message: 'View permitted under shared-view rules.',
      );
    }

    if (receipt.bindingMode == ReceiptBindingMode.sessionBound &&
        request.requestedSessionId != receipt.sessionId) {
      return const ReceiptAuthorizationResult(
        allowed: false,
        normalizedResultCode: 'ERR_RECEIPT_SESSION_MISMATCH',
        message: 'Not authorized for this session.',
      );
    }

    if ((receipt.bindingMode == ReceiptBindingMode.userBound ||
            receipt.bindingMode == ReceiptBindingMode.mixed ||
            receipt.bindingMode == ReceiptBindingMode.sessionBound) &&
        request.requestedByUserId != receipt.pseudonymousUserId) {
      return const ReceiptAuthorizationResult(
        allowed: false,
        normalizedResultCode: 'ERR_RECEIPT_USER_MISMATCH',
        message: 'Not authorized for this user.',
      );
    }

    return const ReceiptAuthorizationResult(
      allowed: true,
      normalizedResultCode: 'OK_RECEIPT_RESTORE_ALLOWED',
      message: 'Restore permitted.',
    );
  }
}
