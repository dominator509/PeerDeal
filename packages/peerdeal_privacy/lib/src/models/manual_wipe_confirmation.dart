class ManualWipeConfirmation {
  const ManualWipeConfirmation({
    required this.requiresSecondConfirmation,
    required this.confirmationPhrase,
  });

  final bool requiresSecondConfirmation;
  final String confirmationPhrase;
}
