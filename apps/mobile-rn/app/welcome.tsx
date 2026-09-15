import { Redirect } from 'expo-router';
import { useEffect, useState } from 'react';
import {
  Button,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { useAuthSession } from '../src/application/auth-session';
import { useRuntimeConfig, useSupabaseClient } from '../src/application/app-providers';
import {
  AuthActionError,
  signInAnonymously,
  signInWithEmail,
  signInWithOAuth,
  signUpWithEmail,
} from '../src/features/auth/auth-service';

type FormMode = 'sign-in' | 'sign-up';

export default function WelcomeRoute() {
  const { session, status, authMessage } = useAuthSession();
  const client = useSupabaseClient();
  const config = useRuntimeConfig();
  const [mode, setMode] = useState<FormMode>('sign-in');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [message, setMessage] = useState<string | undefined>(authMessage);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (authMessage) {
      setMessage(authMessage);
    }
  }, [authMessage]);

  if (status === 'ready' && session) {
    return <Redirect href="/onboarding/select-language" />;
  }

  const run = async (action: () => Promise<void>): Promise<void> => {
    setIsSubmitting(true);
    setMessage(undefined);
    try {
      await action();
    } catch (error) {
      setMessage(
        error instanceof AuthActionError
          ? error.userMessage
          : 'Authentication could not be completed. Try again.',
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const submitEmail = () => {
    void run(async () => {
      const result =
        mode === 'sign-in'
          ? await signInWithEmail(client, email, password)
          : await signUpWithEmail(client, email, password, displayName);
      if (result.kind === 'email-confirmation-required') {
        setMessage('Check your email to confirm your account, then return here to sign in.');
      }
    });
  };

  return (
    <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
      <Text accessibilityRole="header" style={styles.title}>
        Welcome to Spark Lingo
      </Text>
      <Text style={styles.introduction}>
        Sign in to continue securely, or start with a limited guest session.
      </Text>
      <View style={styles.modeRow}>
        <Button
          title="Sign in"
          disabled={isSubmitting || mode === 'sign-in'}
          onPress={() => setMode('sign-in')}
        />
        <Button
          title="Create account"
          disabled={isSubmitting || mode === 'sign-up'}
          onPress={() => setMode('sign-up')}
        />
      </View>
      {mode === 'sign-up' ? (
        <TextInput
          accessibilityLabel="Display name"
          autoComplete="name"
          maxLength={80}
          onChangeText={setDisplayName}
          placeholder="Display name"
          placeholderTextColor="#94A3B8"
          style={styles.input}
          value={displayName}
        />
      ) : null}
      <TextInput
        accessibilityLabel="Email address"
        autoCapitalize="none"
        autoComplete="email"
        inputMode="email"
        keyboardType="email-address"
        onChangeText={setEmail}
        placeholder="Email address"
        placeholderTextColor="#94A3B8"
        style={styles.input}
        textContentType="emailAddress"
        value={email}
      />
      <TextInput
        accessibilityLabel="Password"
        autoCapitalize="none"
        autoComplete={mode === 'sign-in' ? 'current-password' : 'new-password'}
        onChangeText={setPassword}
        placeholder="Password"
        placeholderTextColor="#94A3B8"
        secureTextEntry
        style={styles.input}
        textContentType={mode === 'sign-in' ? 'password' : 'newPassword'}
        value={password}
      />
      <Button
        title={isSubmitting ? 'Please wait…' : mode === 'sign-in' ? 'Sign in' : 'Create account'}
        disabled={isSubmitting}
        onPress={submitEmail}
      />
      {config.oauth?.googleEnabled ? (
        <Button
          title="Continue with Google"
          disabled={isSubmitting}
          onPress={() => {
            void run(async () => {
              const result = await signInWithOAuth(client, config, 'google');
              if (result.kind === 'cancelled') {
                setMessage('Sign-in was cancelled.');
              }
            });
          }}
        />
      ) : null}
      {config.oauth?.appleEnabled ? (
        <Button
          title="Continue with Apple"
          disabled={isSubmitting}
          onPress={() => {
            void run(async () => {
              const result = await signInWithOAuth(client, config, 'apple');
              if (result.kind === 'cancelled') {
                setMessage('Sign-in was cancelled.');
              }
            });
          }}
        />
      ) : null}
      <View style={styles.divider} />
      <Button
        title={isSubmitting ? 'Please wait…' : 'Continue as guest'}
        disabled={isSubmitting}
        onPress={() => {
          void run(() => signInAnonymously(client));
        }}
      />
      {message ? <Text accessibilityLiveRegion="polite" style={styles.message}>{message}</Text> : null}
      <Text style={styles.footnote}>
        Guest access is limited. Billing and governed AI features require the server-side
        checks that will be ported with those features.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0B1020',
    flexGrow: 1,
    gap: 14,
    justifyContent: 'center',
    padding: 24,
  },
  title: { color: '#F8FAFC', fontSize: 28, fontWeight: '700', textAlign: 'center' },
  introduction: { color: '#CBD5E1', fontSize: 16, lineHeight: 24, textAlign: 'center' },
  modeRow: { flexDirection: 'row', gap: 12, justifyContent: 'center' },
  input: {
    backgroundColor: '#17203A',
    borderColor: '#475569',
    borderRadius: 10,
    borderWidth: 1,
    color: '#F8FAFC',
    fontSize: 16,
    padding: 14,
  },
  divider: { backgroundColor: '#334155', height: 1, marginVertical: 6 },
  message: { color: '#FDE68A', fontSize: 15, lineHeight: 22, textAlign: 'center' },
  footnote: { color: '#94A3B8', fontSize: 13, lineHeight: 20, textAlign: 'center' },
});
