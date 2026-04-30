enum HoldemTableActionType {
  fold,
  check,
  call,
  bet,
  raise,
  allIn,
}

class HoldemTableAction {
  const HoldemTableAction({
    required this.actorSeat,
    required this.type,
    this.amount = 0,
  });

  final int actorSeat;
  final HoldemTableActionType type;
  final int amount;
}
