// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library toml.test.tester.encoder;

import 'package:test/test.dart';
import 'package:toml/encoder.dart';

var _encoder = TomlEncoder();

/// Tests whether the result of encoding the [input] is the specified [output].
void testEncoder(String description,
    {Map<String, dynamic> input, String output}) {
  test(description, () {
    var result = _encoder.encode(input);
    expect(result, equals(output));
  });
}

/// Tests whether the [TomlEncoder] fails to encode [input].
///
/// Optionally tests whether a particular [error] is thrown.
void testEncoderFailure(String description,
    {Map<String, dynamic> input, dynamic error = anything}) {
  test(description, () {
    expect(() => _encoder.encode(input), throwsA(error));
  });
}
