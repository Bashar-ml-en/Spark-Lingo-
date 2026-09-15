import { useMemo, useState } from 'react';
import {
  Button,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { useSupabaseClient } from '../../application/app-providers';
import type { CurriculumLesson, PublishedCourseRelease } from './curriculum-repository';
import {
  completePublishedLesson,
  LearningSessionError,
  recordCardReview,
  recordLessonExerciseResponse,
} from './lesson-session-service';

type StudyLessonProps = {
  lesson: CurriculumLesson;
  release: PublishedCourseRelease;
  onCompleted: () => void;
};

export function StudyLesson({ lesson, release, onCompleted }: StudyLessonProps) {
  const client = useSupabaseClient();
  const [exerciseIndex, setExerciseIndex] = useState(0);
  const [response, setResponse] = useState('');
  const [message, setMessage] = useState<string | undefined>();
  const [readyToComplete, setReadyToComplete] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);
  const currentExercise = lesson.exercises[exerciseIndex];

  const options = useMemo(() => {
    if (!currentExercise || currentExercise.kind !== 'recognition') {
      return [];
    }
    return [...new Set([...currentExercise.acceptedAnswers, ...currentExercise.distractors])];
  }, [currentExercise]);

  if (!currentExercise) {
    return (
      <View style={styles.panel}>
        <Text style={styles.error}>
          This lesson has no verified exercises. No progress can be recorded.
        </Text>
      </View>
    );
  }

  const submitResponse = (): void => {
    if (!response.trim()) {
      setMessage('Enter or select an answer before continuing.');
      return;
    }

    void (async () => {
      setIsSubmitting(true);
      setMessage(undefined);
      try {
        const result = await recordLessonExerciseResponse(client, {
          lessonId: lesson.id,
          exerciseId: currentExercise.id,
          languageCode: release.targetLanguageCode,
          contentVersion: release.contentVersion,
          response,
        });

        if (!result.isCorrect) {
          setMessage(currentExercise.remediation);
          return;
        }

        // A new card is scheduled only after its answer was verified by the
        // server. Review scheduling failure remains visible but never turns a
        // failed server mutation into a local success state.
        let schedulingMessage: string | undefined;
        if (currentExercise.flashcardId) {
          try {
            await recordCardReview(client, {
              cardId: currentExercise.flashcardId,
              languageCode: release.targetLanguageCode,
              rating: 'good',
            });
          } catch (error) {
            schedulingMessage =
              error instanceof LearningSessionError
                ? `${error.message} Your verified exercise answer is still saved.`
                : 'Your answer was verified, but its review schedule could not be saved.';
          }
        }

        if (result.lessonComplete) {
          setReadyToComplete(true);
          setMessage(
            `${schedulingMessage ? `${schedulingMessage} ` : ''}All required exercises are verified. Record lesson completion when you are ready.`,
          );
          return;
        }

        setMessage(
          `${schedulingMessage ? `${schedulingMessage} ` : ''}Correct. ${result.completedRequiredExercises} of ${result.totalRequiredExercises} required exercises verified.`,
        );
        setResponse('');
        setExerciseIndex((index) => index + 1);
      } catch (error) {
        setMessage(
          error instanceof LearningSessionError
            ? error.message
            : 'Your response could not be verified. No lesson completion was recorded.',
        );
      } finally {
        setIsSubmitting(false);
      }
    })();
  };

  const completeLesson = (): void => {
    void (async () => {
      setIsCompleting(true);
      setMessage(undefined);
      try {
        await completePublishedLesson(client, {
          lessonId: lesson.id,
          languageCode: release.targetLanguageCode,
          contentVersion: release.contentVersion,
        });
        setMessage('Lesson completion was recorded by the server.');
        onCompleted();
      } catch (error) {
        setMessage(
          error instanceof LearningSessionError
            ? error.message
            : 'The server could not record this lesson. Try again.',
        );
      } finally {
        setIsCompleting(false);
      }
    })();
  };

  return (
    <View style={styles.panel}>
      <Text style={styles.progress}>
        Practice {exerciseIndex + 1} of {lesson.exercises.length}
      </Text>
      <Text accessibilityRole="header" style={styles.prompt}>
        {currentExercise.prompt}
      </Text>
      <Text style={styles.hint}>{currentExercise.hint}</Text>
      {currentExercise.kind === 'recognition' ? (
        <View style={styles.options}>
          {options.map((option) => (
            <Button
              key={option}
              title={option}
              disabled={isSubmitting || readyToComplete}
              onPress={() => setResponse(option)}
              color={response === option ? '#38BDF8' : undefined}
            />
          ))}
        </View>
      ) : (
        <TextInput
          accessibilityLabel="Your answer"
          autoCapitalize="sentences"
          editable={!isSubmitting && !readyToComplete}
          maxLength={300}
          multiline={currentExercise.kind === 'guided_writing'}
          onChangeText={setResponse}
          placeholder="Type your answer"
          placeholderTextColor="#94A3B8"
          style={[styles.input, currentExercise.kind === 'guided_writing' && styles.multilineInput]}
          value={response}
        />
      )}
      {!readyToComplete ? (
        <Button
          title={isSubmitting ? 'Checking…' : 'Check answer'}
          disabled={isSubmitting}
          onPress={submitResponse}
        />
      ) : (
        <Button
          title={isCompleting ? 'Recording…' : 'Record lesson completion'}
          disabled={isCompleting}
          onPress={completeLesson}
        />
      )}
      {message ? <Text accessibilityLiveRegion="polite" style={styles.message}>{message}</Text> : null}
      <Text style={styles.disclosure}>
        This checks only the current reviewed answer pattern. It does not assess fluency,
        pronunciation, or a language level.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    backgroundColor: '#17203A',
    borderColor: '#334155',
    borderRadius: 14,
    borderWidth: 1,
    gap: 14,
    padding: 18,
  },
  progress: { color: '#93C5FD', fontSize: 14, fontWeight: '700' },
  prompt: { color: '#F8FAFC', fontSize: 21, fontWeight: '700', lineHeight: 30 },
  hint: { color: '#CBD5E1', fontSize: 15, lineHeight: 22 },
  options: { gap: 10 },
  input: {
    backgroundColor: '#0B1020',
    borderColor: '#475569',
    borderRadius: 10,
    borderWidth: 1,
    color: '#F8FAFC',
    fontSize: 16,
    padding: 14,
  },
  multilineInput: { minHeight: 100, textAlignVertical: 'top' },
  message: { color: '#FDE68A', fontSize: 15, lineHeight: 22 },
  disclosure: { color: '#94A3B8', fontSize: 13, lineHeight: 19 },
  error: { color: '#FCA5A5', fontSize: 16, lineHeight: 24 },
});
