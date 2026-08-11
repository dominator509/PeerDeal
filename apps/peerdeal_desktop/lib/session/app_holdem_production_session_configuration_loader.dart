import '../join_flow/join_flow_models.dart';
import 'app_holdem_production_session_configuration_factory.dart';

/// Loads one app-owned production session configuration for an accepted join.
///
/// The product supplies the factory composition. This seam only carries the
/// typed governance result into the app shell and does not invent session
/// state, route policy, identity, or persistence.
typedef AppHoldemProductionSessionConfigurationLoader =
    Future<AppHoldemProductionSessionConfigurationLoadResult> Function(
      JoinFlowSessionContext sessionContext,
    );
