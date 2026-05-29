import Foundation

/// Minimal pre-iOS-18 backport of `Synchronization.Mutex`.
///
/// Mirrors the standard library's API surface (`init(_:)`, `withLock`,
/// `withLockIfAvailable`) so that once the deployment target reaches iOS 18
/// this type can be deleted and replaced with `import Synchronization` with
/// no call-site changes.
///
/// Reference semantics are required: the lock and the value it guards must
/// stay paired, so this is a `final class` rather than a (copyable) struct.
///
/// The underlying lock is **non-reentrant**. Never call `withLock` or
/// `withLockIfAvailable` from inside another `withLock` body on the same
/// instance: re-acquiring via `withLock` deadlocks, and via
/// `withLockIfAvailable` returns `nil`. Keep lock bodies free of call-outs
/// (continuation resumes, callbacks, re-entrant accessors) for this reason.
final class Mutex<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ initialValue: Value) {
    self.value = initialValue
  }

  /// Runs `body` with exclusive access to the guarded value.
  ///
  /// Blocks until the lock is available. Must not be called re-entrantly
  /// from within another `withLock`/`withLockIfAvailable` on this instance.
  func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
    lock.lock()
    defer { lock.unlock() }
    return try body(&value)
  }

  /// Runs `body` with exclusive access if the lock can be taken without
  /// waiting; otherwise returns `nil` without running `body`.
  ///
  /// Returns `nil` if the lock is held by any thread, including the
  /// current one (the lock is non-reentrant).
  func withLockIfAvailable<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result? {
    guard lock.try() else { return nil }
    defer { lock.unlock() }
    return try body(&value)
  }
}
