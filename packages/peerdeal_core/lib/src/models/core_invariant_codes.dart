abstract final class CoreInvariantCodes {
  static const tableIdEmpty = 'ERR_TABLE_ID_EMPTY';
  static const tableIdUnsafe = 'ERR_TABLE_ID_UNSAFE';
  static const sessionIdEmpty = 'ERR_SESSION_ID_EMPTY';
  static const sessionIdUnsafe = 'ERR_SESSION_ID_UNSAFE';
  static const protocolVersionEmpty = 'ERR_PROTOCOL_VERSION_EMPTY';
  static const protocolVersionUnsafe = 'ERR_PROTOCOL_VERSION_UNSAFE';
  static const eventSequenceNegative = 'ERR_EVENT_SEQUENCE_NEGATIVE';
  static const connectedCountNegative = 'ERR_CONNECTED_COUNT_NEGATIVE';
  static const seatedCountNegative = 'ERR_SEATED_COUNT_NEGATIVE';
  static const activeHandIdEmpty = 'ERR_ACTIVE_HAND_ID_EMPTY';
  static const activeHandIdUnsafe = 'ERR_ACTIVE_HAND_ID_UNSAFE';
  static const activeHandOutsideLivePhase =
      'ERR_ACTIVE_HAND_OUTSIDE_LIVE_PHASE';
  static const seatedExceedsConnected = 'ERR_SEATED_EXCEEDS_CONNECTED';
  static const closingWithoutCloseRequest = 'ERR_CLOSING_WITHOUT_CLOSE_REQUEST';
  static const closedStateNotTerminal = 'ERR_CLOSED_STATE_NOT_TERMINAL';
  static const closedStateNotCloseRequested =
      'ERR_CLOSED_STATE_NOT_CLOSE_REQUESTED';
  static const wipedStateNotTerminal = 'ERR_WIPED_STATE_NOT_TERMINAL';
  static const wipedStateNotCloseRequested =
      'ERR_WIPED_STATE_NOT_CLOSE_REQUESTED';

  static const openEventAfterStreamStarted =
      'ERR_OPEN_EVENT_AFTER_STREAM_STARTED';
  static const terminalStateCannotAdvance = 'ERR_TERMINAL_STATE_CANNOT_ADVANCE';
  static const participantSeatedWithoutConnected =
      'ERR_PARTICIPANT_SEATED_WITHOUT_CONNECTED';
  static const handStartedWithoutHandId = 'ERR_HAND_STARTED_WITHOUT_HAND_ID';
  static const handStartedWhileActive = 'ERR_HAND_STARTED_WHILE_ACTIVE';
  static const handEventWithoutHandId = 'ERR_HAND_EVENT_WITHOUT_HAND_ID';
  static const handEventWithoutActiveHand =
      'ERR_HAND_EVENT_WITHOUT_ACTIVE_HAND';
  static const handEventIdMismatch = 'ERR_HAND_EVENT_ID_MISMATCH';
  static const sessionClosedWithoutCloseRequest =
      'ERR_SESSION_CLOSED_WITHOUT_CLOSE_REQUEST';
  static const sessionClosedWithActiveHand =
      'ERR_SESSION_CLOSED_WITH_ACTIVE_HAND';
  static const sessionWipedBeforeClose = 'ERR_SESSION_WIPED_BEFORE_CLOSE';
  static const eventEnvelopeIdentityEmpty = 'ERR_EVENT_ENVELOPE_IDENTITY_EMPTY';
  static const eventEnvelopeIdentityUnsafe =
      'ERR_EVENT_ENVELOPE_IDENTITY_UNSAFE';

  static const all = <String>[
    tableIdEmpty,
    tableIdUnsafe,
    sessionIdEmpty,
    sessionIdUnsafe,
    protocolVersionEmpty,
    protocolVersionUnsafe,
    eventSequenceNegative,
    connectedCountNegative,
    seatedCountNegative,
    activeHandIdEmpty,
    activeHandIdUnsafe,
    activeHandOutsideLivePhase,
    seatedExceedsConnected,
    closingWithoutCloseRequest,
    closedStateNotTerminal,
    closedStateNotCloseRequested,
    wipedStateNotTerminal,
    wipedStateNotCloseRequested,
    openEventAfterStreamStarted,
    terminalStateCannotAdvance,
    participantSeatedWithoutConnected,
    handStartedWithoutHandId,
    handStartedWhileActive,
    handEventWithoutHandId,
    handEventWithoutActiveHand,
    handEventIdMismatch,
    sessionClosedWithoutCloseRequest,
    sessionClosedWithActiveHand,
    sessionWipedBeforeClose,
    eventEnvelopeIdentityEmpty,
    eventEnvelopeIdentityUnsafe,
  ];
}
