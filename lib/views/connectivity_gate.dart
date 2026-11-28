import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:opendoor/views/auth_gate.dart';
import 'package:opendoor/repositories/auth_repository.dart';
import 'package:opendoor/views/no_internet_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final _connectionStream = InternetConnection().onStatusChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternetStatus>(
      stream: _connectionStream,
      builder: (context, snapshot) {
        // empty snapshot for some reason so show loading
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // if have internet status, then go through AuthGate.
        // if no have internet status, then show no internet view.
        if (snapshot.data == InternetStatus.connected) {
          return AuthGate(
            authRepository: AuthRepository(Supabase.instance.client),
          );
        } else {
          return const NoInternetView();
        }
      },
    );
  }
}
