import 'package:flutter_test/flutter_test.dart';
import 'package:operations_app/models/notification_item.dart';

void main() {
  test('NotificationItem round-trips through JSON', () {
    final n = NotificationItem(
      id: 'abc',
      title: 'title',
      body: 'body',
      timestamp: DateTime(2026, 8, 7, 12, 0),
    );
    final decoded = NotificationItem.decode(n.encode());
    expect(decoded.id, 'abc');
    expect(decoded.title, 'title');
    expect(decoded.body, 'body');
    expect(decoded.isExpired, isFalse);
    decoded.isRead = true;
    expect(decoded.isRead, isTrue);
  });
}