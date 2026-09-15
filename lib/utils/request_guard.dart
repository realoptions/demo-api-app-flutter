/// Guards a single logical request slot so that only the newest request is
/// allowed to publish a result.
///
/// A submit that triggers network work can be superseded before the response
/// comes back: the user edits the parameters and submits again, or flips the
/// model in the app bar a second time. Responses come back in whatever order
/// the network decides, so a handler that simply `emit`s whatever it awaited
/// can publish an *older* result on top of a newer one. On a pricing demo that
/// means charts showing numbers that do not belong to the parameters on screen.
///
/// The pattern at each call site is:
///
/// ```dart
/// final int request = _guard.begin();          // claim "newest"
/// final result = await service.fetch(...);
/// if (!_guard.isCurrent(request)) return;     // someone superseded us: drop it
/// emit(Data(result));
/// ```
///
/// [begin] is called *before* the await, so a superseding request always
/// takes the slot before the older one can check it. Tokens are monotonic and
/// never reused, so a token can never be mistaken for a current one.
///
/// This deliberately drops the result rather than cancelling the underlying
/// request: the HTTP layer here is the package-level `http.get`/`http.post`,
/// which exposes no cancellation handle. Dropping the result is what protects
/// the user-visible state, which is the thing that matters.
class RequestGuard {
  int _latest = 0;

  /// Marks a new request as the newest one and returns its token.
  int begin() => ++_latest;

  /// Whether [token] still refers to the newest request.
  ///
  /// Returns false as soon as [begin] (or [invalidate]) has been called again,
  /// which is exactly the condition under which a response must not be shown.
  bool isCurrent(int token) => token == _latest;

  /// Drops the current token so that an in-flight request publishes nothing.
  ///
  /// Useful when the result becomes meaningless for a reason other than a new
  /// request arriving (sign-out, for instance).
  void invalidate() => _latest++;

  /// The token of the newest request, for diagnostics.
  int get latest => _latest;
}
