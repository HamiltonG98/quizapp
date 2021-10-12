import 'package:quiz_riverpod_app/controllers/quiz/quiz_state.dart';
import 'package:quiz_riverpod_app/models/question_model.dart';
import 'package:riverpod/riverpod.dart';

final quizControllerProvider =
    StateNotifierProvider.autoDispose<QuizController>((ref) => QuizController());

class QuizController extends StateNotifier<QuizState> {
  QuizController() : super(QuizState.initial());

  void submitAnswer(Question currentQuestion, String answer) {
    if (state.answered) return;
    if (currentQuestion.correctAnswer == answer) {
      state = state.copyWith(
          selectedAnswer: answer,
          correct: state.correct..add(currentQuestion),
          status: QuizStatus.correct);
    } else {
      state = state.copyWith(
          selectedAnswer: answer,
          incorrect: state.incorrect..add(currentQuestion),
          status: QuizStatus.incorrect);
    }
  }

  void nextQuestion(List<Question> questions, int currenIndex) {
    state = state.copyWith(
        selectedAnswer: '',
        status: currenIndex + 1 < questions.length
            ? QuizStatus.initial
            : QuizStatus.complete);
  }

  void reset() {
    state = QuizState.initial();
  }
}
