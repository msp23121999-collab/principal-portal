import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/principal_profile_mock_data.dart';
import '../models/principal_profile.dart';

final principalProfileProvider = FutureProvider<PrincipalProfile>((ref) {
  return mockDelay(PrincipalProfileMockData.profile);
});
