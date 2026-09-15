import { useQuery } from '@tanstack/react-query';
import { Link, Redirect, useLocalSearchParams } from 'expo-router';
import { Button, ScrollView, StyleSheet, Text, View } from 'react-native';

import { useAuthSession } from '../../src/application/auth-session';
import { useSupabaseClient } from '../../src/application/app-providers';
import {
  CurriculumRepositoryError,
  loadPublishedCourse,
  publishedCourseQueryKey,
} from '../../src/features/learning/curriculum-repository';
import { StateBody, StateScreen, StateTitle } from '../../src/components/state-screen';

function oneRouteValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default function CourseRoute() {
  const { session, status } = useAuthSession();
  const client = useSupabaseClient();
  const params = useLocalSearchParams<{ courseKey: string; version?: string }>();
  const courseKey = oneRouteValue(params.courseKey);
  const expectedVersion = oneRouteValue(params.version);
  const query = useQuery({
    queryKey: publishedCourseQueryKey(session?.user.id ?? 'missing-session', courseKey ?? 'missing-course', expectedVersion),
    queryFn: () => loadPublishedCourse(client, courseKey!, expectedVersion),
    enabled: Boolean(session && courseKey),
  });

  if (status !== 'loading' && !session) {
    return <Redirect href="/welcome" />;
  }
  if (!courseKey) {
    return <Redirect href="/onboarding/select-language" />;
  }
  if (query.isPending) {
    return (
      <StateScreen>
        <StateTitle>Loading reviewed course</StateTitle>
        <StateBody>Checking the current course version and lesson material.</StateBody>
      </StateScreen>
    );
  }
  if (query.isError || !query.data) {
    const message =
      query.error instanceof CurriculumRepositoryError
        ? query.error.message
        : 'This course could not be loaded. No progress was changed.';
    return (
      <StateScreen>
        <StateTitle>Course unavailable</StateTitle>
        <StateBody>{message}</StateBody>
        <Button title="Try again" onPress={() => void query.refetch()} />
        <Link href="/onboarding/select-language" accessibilityRole="link">
          <Text style={styles.link}>Return to course selection</Text>
        </Link>
      </StateScreen>
    );
  }

  const course = query.data;
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text accessibilityRole="header" style={styles.title}>{course.release.title}</Text>
      <Text style={styles.introduction}>
        Reviewed release {course.release.contentVersion}. This text-first course has no audio,
        AI, voice, level, or exam-readiness claim.
      </Text>
      {course.units.map((unit) => (
        <View key={unit.id} style={styles.unit}>
          <Text style={styles.unitTitle}>{unit.title}</Text>
          <Text style={styles.description}>{unit.description}</Text>
          {unit.lessons.map((lesson) => (
            <Link
              key={lesson.id}
              href={{
                pathname: '/learn/[courseKey]/lesson/[lessonId]',
                params: {
                  courseKey: course.release.courseKey,
                  lessonId: lesson.id,
                  version: course.release.contentVersion,
                },
              }}
              accessibilityRole="link"
              style={styles.lessonLink}
            >
              {lesson.title}
            </Link>
          ))}
        </View>
      ))}
      <Link href="/onboarding/select-language" accessibilityRole="link">
        <Text style={styles.link}>Change course</Text>
      </Link>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: '#0B1020', flexGrow: 1, gap: 16, padding: 24 },
  title: { color: '#F8FAFC', fontSize: 28, fontWeight: '700' },
  introduction: { color: '#CBD5E1', fontSize: 16, lineHeight: 24 },
  unit: {
    backgroundColor: '#17203A',
    borderColor: '#334155',
    borderRadius: 14,
    borderWidth: 1,
    gap: 10,
    padding: 18,
  },
  unitTitle: { color: '#F8FAFC', fontSize: 20, fontWeight: '700' },
  description: { color: '#CBD5E1', fontSize: 15, lineHeight: 22 },
  lessonLink: { color: '#93C5FD', fontSize: 16, paddingVertical: 8 },
  link: { color: '#93C5FD', fontSize: 16, textAlign: 'center' },
});
