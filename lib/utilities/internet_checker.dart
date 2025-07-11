import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

Future<bool> hasInternetConnection() async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if( connectivityResult == ConnectivityResult.none )
  {
    return false;
  }

  return await InternetConnectionChecker().hasConnection;
}
