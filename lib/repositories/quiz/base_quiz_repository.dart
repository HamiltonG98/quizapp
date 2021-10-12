
import 'package:quiz_riverpod_app/enums/difficulty.dart';
import 'package:quiz_riverpod_app/models/question_model.dart';

abstract class BaseQuizRepository {
  Future<List<Question>> getQuestions({
    int numQuestions,
    int categoryId,
    Difficulty difficulty,
  });
}