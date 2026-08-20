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
    if (!receipt.hasRequiredEnvelopeFields) {
      return const ReceiptAuthorizationResult(
        allowed: false,
        normalizedResultCode: 'ERR_RECEIPT_MALFORMED',
        message: 'Receipt envelope is malformed.',
      );
    }

    if (receipt.wipeState == ReceiptWipeState.wiped) {
      return const ReceiptAuthorizationResult(
        allowed: false,
        normalizedResultCode: 'ERR_RECEIPT_WIPED',
        message: 'Receipt unavailable.',
      );
    }

    if ((receipt.bindingMode == ReceiptBindingMode.sessionBound ||
            receipt.bindingMode == ReceiptBindingMode.mixed) &&
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

    return ReceiptAuthorizationResult(
      allowed: true,
      normalizedResultCode: request.accessMode == ReceiptAccessMode.view
          ? 'OK_RECEIPT_VIEW_ALLOWED'
          : 'OK_RECEIPT_RESTORE_ALLOWED',
      message: request.accessMode == ReceiptAccessMode.view
          ? 'View permitted for the bound session and user.'
          : 'Restore permitted.',
    );
  }
}
