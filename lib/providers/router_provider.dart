import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/tasklist_provider.dart';
import 'package:frontend/screens/addroutine.dart';
import 'package:frontend/screens/calendar.dart';
import 'package:frontend/screens/editinfo.dart';
import 'package:frontend/screens/feedback.dart';
import 'package:frontend/screens/login.dart';
import 'package:frontend/screens/bedtime.dart';
import 'package:frontend/screens/name_setup.dart';
import 'package:frontend/screens/preference.dart';
import 'package:frontend/screens/routine_report.dart';
import 'package:frontend/screens/setting.dart';
import 'package:frontend/screens/weekly_reports.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(initialLocation: '/login', routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        return Calendar(
          googleId: googleId,
        );
      },
    ),
    GoRoute(
        path: '/name/:googleId',
        builder: (context, state) {
          final googleId = state.params['googleId']!;
          if (googleId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid googleId')),
            );
          }
          return NameSetup(
            googleId: googleId,
          );
        }),
    GoRoute(
      path: '/bedtime/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        if (googleId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invalid googleId')),
          );
        }
        return Bedtime(
          googleId: googleId,
        );
      },
    ),
    GoRoute(
      path: '/preference/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        if (googleId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invalid googleId')),
          );
        }
        return Preference(
          googleId: googleId,
        );
      },
    ),
    GoRoute(
      path: '/addroutine/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        final returnPath = state.queryParams['returnPath'] ?? '/';
        final taskListNotifier = TaskListNotifier();

        if (googleId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invalid googleId')),
          );
        }

        return AddRoutine(
          googleId: googleId,
          returnPath: returnPath,
          taskListNotifier: taskListNotifier,
        );
      },
    ),
    GoRoute(
        path: '/setting/:googleId',
        builder: (context, state) {
          final googleId = state.params['googleId']!;
          if (googleId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid googleId'),
              ),
            );
          }
          return Setting(
            googleId: googleId,
          );
        }),
    GoRoute(
      path: '/editinfo',
      builder: (context, state) => const Editinfo(),
    ),
    GoRoute(
      path: '/weeklyreports/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        if (googleId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invalid googleId')),
          );
        }
        return WeeklyReports(
          googleId: googleId,
        );
      },
    ),
    GoRoute(
      path: '/feedback/:googleId',
      builder: (context, state) {
        final googleId = state.params['googleId']!;
        if (googleId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invalid googleId')),
          );
        }
        return UserFeedBack(
          googleId: googleId,
        );
      },
    ),
  ]);
});
