import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/result_mock_data.dart';
import '../models/semester_result.dart';

final selectedSemesterProvider = StateProvider<String>(
  (ref) => ResultMockData.semesters.first,
);

final semesterResultProvider = FutureProvider<SemesterResult>((ref) {
  final semester = ref.watch(selectedSemesterProvider);
  return mockDelay(() => ResultMockData.resultsBySemester[semester]!);
});

final rankHoldersProvider = FutureProvider<List<RankHolder>>((ref) {
  final semester = ref.watch(selectedSemesterProvider);
  return mockDelay(
    () => ResultMockData.rankHoldersBySemester[semester] ?? const [],
  );
});
