import '../join_flow/join_flow_models.dart';
import 'app_holdem_production_session_configuration_factory.dart';
import 'app_holdem_production_session_configuration_loader.dart';

/// Adapts one configured production-session factory to the app-shell handoff.
///
/// The accepted session context is forwarded by the shell to the bootstrap
/// route after this factory creates the persisted configuration. The factory
/// itself remains responsible for product-owned route policy and persistence
/// inputs; this adapter only closes the app registration gap.
class AppHoldemProductionSessionConfigurationLoaderFactory {
  AppHoldemProductionSessionConfigurationLoaderFactory({
    required AppHoldemProductionSessionConfigurationFactory
    configurationFactory,
  }) : _configurationFactory = configurationFactory;

  final AppHoldemProductionSessionConfigurationFactory _configurationFactory;

  late final AppHoldemProductionSessionConfigurationLoader loader = _load;

  Future<AppHoldemProductionSessionConfigurationLoadResult> _load(
    JoinFlowSessionContext sessionContext, {
    Future<void>? cancellation,
  }) {
    return _configurationFactory.create(
      sessionContext: sessionContext,
      cancellation: cancellation,
    );
  }
}
