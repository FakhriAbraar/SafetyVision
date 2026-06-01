import 'package:flutter/widgets.dart';

import 'report_repository.dart';

class AppScope extends InheritedWidget {
  final ReportRepository reports;

  const AppScope({
    super.key,
    required this.reports,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope ancestor');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.reports != reports;
}
