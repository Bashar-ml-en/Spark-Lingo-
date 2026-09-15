import { useQuery } from '@tanstack/react-query';
import { Link, Redirect, router, useLocalSearchParams } from 'expo-router';
import { Button, ScrollView, StyleSheet, Text } from 'react-native';

import { useAuthSession } from '../../../../src/application/auth-session';
import { useSupabaseClient } from '../../../../src/application/app-providers';
import { StateBody, StateScreen, StateTitle } from '../../../../src/components/state-screen';
import {
  CurriculumRepositoryError,
  loadPublishedCourse,
  publishedCourseQueryKey,
} from '../../../../src/features/learning/curriculum-repository';
import { StudyLesson } from '../../../../src/features/learning/study-lesson';

function oneRouteValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default function LessonRoute() {
  const { session, status } = useAuthSession();
  const client = useSupabaseClient();
  const params = useLocalSearchParams<{
    courseKey: string;
    lessonId: string;
    version?: string;
  }>();
  const courseKey = oneRouteValue(params.courseKey);
  const lessonId = oneRouteValue(params.lessonId);
  const expectedVersion = oneRouteValue(params.version);
  const query = useQuery({
    queryKey: publishedCourseQueryKey(session?.user.id ?? 'missing-session', courseKey ?? 'missing-course', expectedVersion),
    queryFn: () => loadPublishedCourse(client, courseKey!, expectedVersion),
    enabled: Boolean(session && courseKey),
  });

  if (status !== 'loading' && !session) {
    return <Redirect href="/welcome" />;
  }
  if (!courseKey || !lessonId) {
    return <Redirect href="/onboarding/select-language" />;
  }
  if (query.isPending) {
    return (
      <StateScreen>
        <StateTitle>Loading lesson</StateTitle>
        <StateBody>Checking the current reviewed lesson material.</StateBody>
      </StateScreen>
    );
  }
  if (query.isError || !query.data) {
    const message =
      query.error instanceof CurriculumRepositoryError
        ? query.error.message
        : 'This lesson could not be loaded. No progress was changed.';
    return (
      <StateScreen>
        <StateTitle>Lesson unavailable</StateTitle>
        <StateBody>{message}</StateBody>
        <Button title="Try again" onPress={() => void query.refetch()} />
      </StateScreen>
    );
  }

  const lesson = query.data.units.flatMap((unit) => unit.lessons).find((item) => item.id === lessonId);
  if (!lesson || lesson.exercises.length === 0) {
    return (
      <StateScreen>
        <StateTitle>Lesson unavailable</StateTitle>
        <StateBody>This lesson has no verified practice material. No progress was changed.</StateBody>
        <Link
          href={{
            pathname: '/learn/[courseKey]',
            params: { courseKey: query.data.release.courseKey, version: query.data.release.contentVersion },
          }}
          accessibilityRole="link"
        >
          <Text style={styles.link}>Return to the course</Text>
        </Link>
      </StateScreen>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
      <Text accessibilityRole="header" style={styles.title}>{lesson.title}</Text>
      <Text style={styles.description}>{lesson.description}</Text>
      <StudyLesson
        lesson={lesson}
        release={query.data.release}
        onCompleted={() => {
          router.replace({
            pathname: '/learn/[courseKey]',
            params: { courseKey: query.data!.release.courseKey, version: query.data!.release.contentVersion },
          });
        }}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: '#0B1020', flexGrow: 1, gap: 16, padding: 24 },
  title: { color: '#F8FAFC', fontSize: 28, fontWeight: '700' },
  description: { color: '#CBD5E1', fontSize: 16, lineHeight: 24 },
  link: { color: '#93C5FD', fontSize: 16 },
});
