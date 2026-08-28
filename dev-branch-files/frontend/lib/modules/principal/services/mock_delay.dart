/// Simulated network latency for FutureProviders backed by mock data, so
/// loading states (skeletons) are exercised the same way they will be once
/// real API calls replace these sources.
Future<T> mockDelay<T>(T Function() build, {int milliseconds = 400}) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
  return build();
}
