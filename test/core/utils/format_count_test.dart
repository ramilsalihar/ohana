import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/core/utils/format_count.dart';

void main() {
  test('adds thousands separators', () {
    expect(formatCount(0), '0');
    expect(formatCount(7), '7');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1,000');
    expect(formatCount(1247), '1,247');
    expect(formatCount(123456), '123,456');
    expect(formatCount(1234567), '1,234,567');
    expect(formatCount(-1234), '-1,234');
  });
}
