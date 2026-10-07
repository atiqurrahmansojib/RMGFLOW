import 'package:flutter_test/flutter_test.dart';
import 'package:rmgflow_mobile/common/lookups/current_user.dart';
import 'package:rmgflow_mobile/common/lookups/module_access.dart';

void main() {
  CurrentUser user(List<String> roles) => CurrentUser(id: 1, roles: roles);

  test('home modules follow the seeded *_VIEW permissions per role', () {
    final sampling = user(['SAMPLING_COORDINATOR']);
    expect(canOpenModule(sampling, 'sampling'), isTrue);
    expect(canOpenModule(sampling, 'costing'), isFalse);
    expect(canOpenModule(sampling, 'financial'), isFalse);

    final viewer = user(['MANAGEMENT_VIEWER']);
    expect(canOpenModule(viewer, 'financial'), isTrue);
    expect(canOpenModule(viewer, 'inquiries'), isFalse);

    expect(canOpenModule(user(['FACTORY_COORDINATOR']), 'buyers'), isFalse);
    // Any one granting role is enough; reports/tasks are open to everyone.
    expect(canOpenModule(user(['FACTORY_COORDINATOR', 'SENIOR_MERCHANDISER']), 'buyers'), isTrue);
    expect(canOpenModule(sampling, 'reports'), isTrue);
    expect(canOpenModule(null, 'financial'), isTrue);
  });
}
