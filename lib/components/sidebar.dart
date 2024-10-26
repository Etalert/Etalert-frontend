import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  final String googleId;
  const Sidebar({super.key, required this.googleId});

  @override
  Widget build(BuildContext context) {
    void routeToPage(String route) {
      Navigator.of(context).pop();
      context.go(route);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Container(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ),
                child: Text(
                  'ETAlert',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                routeToPage('/$googleId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Weekly Reports'),
              onTap: () {
                routeToPage('/weeklyreports/$googleId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                routeToPage('/setting/$googleId');
              },
            ),
            // Add more list tiles as needed
          ],
        ),
      ),
    );
  }
}
