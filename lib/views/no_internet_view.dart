import 'package:flutter/material.dart';

// Return a collection of widgets that tells the user that they currently 
// do not have an internet connection and thus cannot use this app.
class NoInternetView extends StatelessWidget {
  const NoInternetView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64),
            SizedBox(height: 16),
            Text('No Internet Connection', style: TextStyle(fontSize: 22)),
            SizedBox(height: 8),
            Text('Please connect to the internet.'),
          ],
        ),
      ),
    );
  }
}