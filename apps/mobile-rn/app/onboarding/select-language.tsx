import { useQuery } from '@tanstack/react-query';
import { Link, Redirect } from 'expo-router';
import { Button, ScrollView, StyleSheet, Text, View } from 'react-native';

import { useAuthSession } from '../../src/application/auth-session';
import { useSupabaseClient } from '../../src/application/app-providers';
import { StateBody, StateScreen, StateTitle } from '../../src/components/state-screen';
import {
  CurriculumRepositoryError,
  listPublishedCourses,
  publishedCoursesQueryKey,
} from '../../src/features/learning/curriculum-repository';

export default function SelectLanguageRoute() {
  const { session, status } = useAuthSession();
  const client = useSupabaseClient();
  const coursesQuery = useQuery({
    queryKey: publishedCoursesQueryKey(session?.user.id ?? 'missing-session'),
    queryFn: () => listPublishedCourses(client),
    enabled: Boolean(session),
  });

  if (status !== 'loading' && !session) {
    return <Redirect href="/welcome" />;
  }

  if (coursesQuery.isPending) {
    return (
      <StateScreen>
        <StateTitle>Loading reviewed courses</StateTitle>
        <StateBody>Checking the current release catalogue.</StateBody>
      </StateScreen>
    );
  }

  if (coursesQuery.isError) {
    const message =
      coursesQuery.error instanceof CurriculumRepositoryError
        ? coursesQuery.error.message
        : 'Reviewed courses could not be loaded. Try again.';
    return (
      <StateScreen>
        <StateTitle>Course catalogue unavailable</StateTitle>
        <StateBody>{message}</StateBody>
        <Button title="Try again" onPress={() => void coursesQuery.refetch()} />
        <Link href="/settings/consent" accessibilityRole="link">
          <Text style={styles.link}>Review privacy permissions</Text>
        </Link>
      </StateScreen>
    );
  }

  const courses = coursesQuery.data ?? [];
  if (courses.length === 0) {
    return (
      <StateScreen>
        <StateTitle>No reviewed course is available yet</StateTitle>
        <StateBody>
          Courses appear here only after a server-side release has completed rights and
          human-review checks. Draft content is intentionally hidden from learners.
        </StateBody>
        <Button title="Refresh catalogue" onPress={() => void coursesQuery.refetch()} />
        <Link href="/settings/consent" accessibilityRole="link">
          <Text style={styles.link}>Review privacy permissions</Text>
        </Link>
      </StateScreen>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text accessibilityRole="header" style={styles.title}>Choose a reviewed course</Text>
      <Text style={styles.introduction}>
        Only current, server-published course versions are available. A missing course is
        not treated as an empty course.
      </Text>
      {courses.map((course) => (
        <View key={course.id} style={styles.course}>
          <Text style={styles.courseTitle}>{course.title}</Text>
          <Text style={styles.courseMeta}>
            Target language: {course.targetLanguageCode} · Version {course.contentVersion}
          </Text>
          <Link
            href={{
              pathname: '/learn/[courseKey]',
              params: { courseKey: course.courseKey, version: course.contentVersion },
            }}
            accessibilityRole="link"
            style={styles.link}
          >
            Open course
          </Link>
        </View>
      ))}
      <Link href="/settings/consent" accessibilityRole="link">
        <Text style={styles.link}>Review privacy permissions</Text>
      </Link>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: '#0B1020', flexGrow: 1, gap: 16, padding: 24 },
  title: { color: '#F8FAFC', fontSize: 27, fontWeight: '700' },
  introduction: { color: '#CBD5E1', fontSize: 16, lineHeight: 24 },
  course: {
    backgroundColor: '#17203A',
    borderColor: '#334155',
    borderRadius: 14,
    borderWidth: 1,
    gap: 9,
    padding: 18,
  },
  courseTitle: { color: '#F8FAFC', fontSize: 19, fontWeight: '700' },
  courseMeta: { color: '#CBD5E1', fontSize: 14, lineHeight: 20 },
  link: { color: '#93C5FD', fontSize: 16 },
});
