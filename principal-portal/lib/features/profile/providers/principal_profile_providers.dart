import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/principal_profile_repository.dart';
import '../models/principal_profile.dart';

final principalProfileRepositoryProvider = Provider(
  (ref) => const PrincipalProfileRepository(),
);

final principalProfileProvider = FutureProvider<PrincipalProfile>((ref) async {
  return (await ref.watch(principalProfileRepositoryProvider).fetch()).value;
});
