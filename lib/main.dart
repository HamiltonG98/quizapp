import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:quiz_riverpod_app/controllers/quiz/quiz_controller.dart';
import 'package:quiz_riverpod_app/controllers/quiz/quiz_state.dart';
import 'package:quiz_riverpod_app/enums/difficulty.dart';
import 'package:quiz_riverpod_app/models/failure_model.dart';
import 'package:quiz_riverpod_app/models/question_model.dart';
import 'package:quiz_riverpod_app/repositories/quiz/quiz_repository.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Riverpod Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.transparent),
      ),
      home: QuizScreen(),
    );
  }
}

final quizQuestionsProvider = FutureProvider.autoDispose<List<Question>>(
  (ref) => ref.watch(quizRepositoryProvider).getQuestions(
      numQuestions: 5,
      categoryId: Random().nextInt(24) + 9,
      difficulty: Difficulty.any),
);

class QuizScreen extends ConsumerWidget {
  final pageController = PageController();

  @override
  Widget build(BuildContext context, watch) {
    final quizQuestions = watch(quizQuestionsProvider);
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xffd4418e), Color(0xff0652c5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: quizQuestions.when(
          data: (questions) => _buildBody(context, pageController, questions),
          loading: () => Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => QuizError(
              message:
                  error is Failure ? error.message : 'Something went wrong!'),
        ),
        bottomSheet: quizQuestions.maybeWhen(
          data: (questions) {
            final quizState = watch(quizControllerProvider.state);
            if (!quizState.answered) return SizedBox.shrink();
            return CustomButton(
              title: pageController.page.toInt() + 1 < questions.length
                  ? 'Next Question'
                  : 'See Results',
              onTap: () {
                context
                    .read(quizControllerProvider)
                    .nextQuestion(questions, pageController.page.toInt());
                if (pageController.page.toInt() + 1 < questions.length) {
                  pageController.nextPage(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.linear);
                }
              },
            );
          },
          orElse: () => SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PageController pageController,
      List<Question> questions) {
    if (questions.isEmpty) return QuizError(message: 'No questions found.');

    return Consumer(
      builder: (context, watch, child) {
        final quizState = watch(quizControllerProvider.state);

        return quizState.status == QuizStatus.complete
            ? QuizResults(state: quizState, questions: questions)
            : QuizQuestions(
                pageController: pageController,
                state: quizState,
                questions: questions);
      },
    );
  }
}

class QuizError extends StatelessWidget {
  final String message;

  const QuizError({Key key, @required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 20.0),
          ),
          SizedBox(
            height: 20.0,
          ),
          CustomButton(
              title: 'Retry',
              onTap: () => context.refresh(quizRepositoryProvider))
        ],
      ),
    );
  }
}

final List<BoxShadow> boxShadow = [
  BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4.0)
];

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  CustomButton({Key key, @required this.title, @required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(20.0),
        height: 50.0,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.yellow,
            boxShadow: boxShadow,
            borderRadius: BorderRadius.circular(25.0)),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class QuizResults extends StatelessWidget {
  final QuizState state;
  final List<Question> questions;

  const QuizResults({Key key, @required this.state, @required this.questions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${state.correct.length}/${questions.length}',
          style: TextStyle(
              color: Colors.white, fontSize: 60.0, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          'CORRECT',
          style: TextStyle(
              color: Colors.white, fontSize: 48.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 40.0,
        ),
        CustomButton(
          title: 'New Quiz',
          onTap: () {
            context.refresh(quizRepositoryProvider);
            context.read(quizControllerProvider).reset();
          },
        ),
      ],
    );
  }
}

class QuizQuestions extends StatelessWidget {
  final PageController pageController;
  final QuizState state;
  final List<Question> questions;

  const QuizQuestions(
      {Key key,
      @required this.pageController,
      @required this.state,
      @required this.questions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      physics: NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question ${index + 1} of ${questions.length}',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                HtmlCharacterEntities.decode(question.question),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Divider(
              color: Colors.grey[200],
              height: 32,
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            Column(
              children: question.answers
                  .map((e) => AnswerCard(
                      answer: e,
                      isSelected: e == state.selectedAnswer,
                      isCorrect: e == question.correctAnswer,
                      isDisplayingAnswer: state.answered,
                      onTap: () => context
                          .read(quizControllerProvider)
                          .submitAnswer(question, e)))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class AnswerCard extends StatelessWidget {
  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool isDisplayingAnswer;
  final VoidCallback onTap;

  const AnswerCard(
      {Key key,
      @required this.answer,
      @required this.isSelected,
      @required this.isCorrect,
      @required this.isDisplayingAnswer,
      @required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: boxShadow,
            border: Border.all(
                color: isDisplayingAnswer
                    ? isCorrect
                        ? Colors.green
                        : isSelected ? Colors.red : Colors.white
                    : Colors.white,
                width: 4),
            borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                HtmlCharacterEntities.decode(answer),
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: isDisplayingAnswer && isCorrect
                        ? FontWeight.bold
                        : FontWeight.w400),
              ),
            ),
            () {
              if (isDisplayingAnswer) {
                return isCorrect
                    ? CircularIcon(icon: Icons.check, color: Colors.green)
                    : isSelected
                        ? CircularIcon(icon: Icons.close, color: Colors.red)
                        : SizedBox.shrink();
              }else{
                return Container();
              }
            }()
          ],
        ),
      ),
    );
  }
}

class CircularIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const CircularIcon({Key key, @required this.icon, @required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
          color: color, shape: BoxShape.circle, boxShadow: boxShadow),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
