import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useMemo } from 'react';

import { AppProviders } from '../src/application/app-providers';
import { UnavailableScreen } from '../src/components/unavailable-screen';
import { loadExpoRuntimeConfig } from '../src/config/expo-runtime-config';

export default function RootLayout() {
  const runtimeConfig = useMemo(() => loadExpoRuntimeConfig(), []);

  if (!runtimeConfig.ok) {
    return <UnavailableScreen errors={runtimeConfig.errors} />;
  }

  return (
    <AppProviders config={runtimeConfig.config}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          contentStyle: { backgroundColor: '#0B1020' },
          headerTintColor: '#F8FAFC',
          headerStyle: { backgroundColor: '#0B1020' },
        }}
      >
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="welcome" options={{ title: 'Welcome' }} />
        <Stack.Screen name="settings/consent" options={{ title: 'Privacy permissions' }} />
        <Stack.Screen
          name="onboarding/select-language"
          options={{ title: 'Choose a language' }}
        />
        <Stack.Screen name="learn/[courseKey]" options={{ title: 'Course' }} />
        <Stack.Screen name="learn/[courseKey]/lesson/[lessonId]" options={{ title: 'Lesson' }} />
        <Stack.Screen name="home/[langCode]" options={{ title: 'Spark Lingo' }} />
      </Stack>
    </AppProviders>
  );
}
