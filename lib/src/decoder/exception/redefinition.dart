// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library toml.src.decoder.exception.redefinition;

/// An exception which is thrown when a table or key is defined more than once.
///
/// Example:
///
///     a = 1
///     a = 2
///
/// throws a [RedefinitionException] because `a` is defined twice.
class RedefinitionException implements Exception {
  /// Fully qualified name of the table or key.
  final String name;

  /// Creates a new exception for the table or key with the given name.
  RedefinitionException(this.name);

  @override
  bool operator ==(Object other) =>
      other is RedefinitionException && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Cannot redefine "$name"!';
}
