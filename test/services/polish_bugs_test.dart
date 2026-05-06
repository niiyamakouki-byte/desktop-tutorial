import 'package:flutter_test/flutter_test.dart';
import 'package:construction_project_manager/data/models/cashflow_model.dart';

void main() {
  group('VendorAvailability.fromJson', () {
    test('parses valid dailyStatus keys', () {
      final json = {
        'vendorId': 'v1',
        'vendorName': 'Test Vendor',
        'weekStart': '2026-05-04T00:00:00.000Z',
        'dailyStatus': {
          '1': 'available',
          '2': 'busy',
        },
        'updatedAt': null,
      };

      final availability = VendorAvailability.fromJson(json);
      expect(availability.dailyStatus.containsKey(1), isTrue);
      expect(availability.dailyStatus.containsKey(2), isTrue);
      expect(
        availability.dailyStatus[1],
        VendorAvailabilityStatus.available,
      );
    });

    test('skips non-integer dailyStatus keys without crashing', () {
      final json = {
        'vendorId': 'v1',
        'vendorName': 'Test Vendor',
        'weekStart': '2026-05-04T00:00:00.000Z',
        'dailyStatus': {
          'bad_key': 'available',
          '3': 'busy',
        },
        'updatedAt': null,
      };

      // Must not throw; invalid key is silently skipped.
      final availability = VendorAvailability.fromJson(json);
      expect(availability.dailyStatus.containsKey(3), isTrue);
      expect(availability.dailyStatus.length, 1);
    });

    test('handles null dailyStatus', () {
      final json = {
        'vendorId': 'v1',
        'vendorName': 'Test Vendor',
        'weekStart': '2026-05-04T00:00:00.000Z',
        'dailyStatus': null,
        'updatedAt': null,
      };

      final availability = VendorAvailability.fromJson(json);
      expect(availability.dailyStatus, isEmpty);
    });
  });
}
