enum RoleKind {
  host,
  cohost,
  player,
  spectator,
}

extension RoleKindX on RoleKind {
  String get wireValue => switch (this) {
        RoleKind.host => 'host',
        RoleKind.cohost => 'cohost',
        RoleKind.player => 'player',
        RoleKind.spectator => 'spectator',
      };
}
