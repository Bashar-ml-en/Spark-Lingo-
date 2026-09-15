import { Redirect } from 'expo-router';
import { useState } from 'react';
import { Alert, Button, ScrollView, StyleSheet, Text } from 'react-native';

import { useAuthSession } from '../../src/application/auth-session';
import { useSupabaseClient } from '../../src/application/app-providers';
import { AuthActionError, signOut } from '../../src/features/auth/auth-service';
import { ConsentControl } from '../../src/features/consent/consent-control';

export default function ConsentSettingsRoute() {
  const { session, status } = useAuthSession();
  const client = useSupabaseClient();
  const [isSigningOut, setIsSigningOut] = useState(false);
  if (status !== 'loading' && !session) {
    return <Redirect href="/welcome" />;
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text accessibilityRole="header" style={styles.title}>
        Privacy permissions
      </Text>
      <Text style={styles.introduction}>
        These permissions are checked by the server for each governed action. Turning a
        permission off immediately prevents the related processing in this client.
      </Text>
      <ConsentControl
        purpose="analytics"
        title="Analytics"
        description="Allow privacy-governed product analytics when it is introduced in the React Native client."
      />
      <ConsentControl
        purpose="ai_processing"
        title="AI processing"
        description="Allow AI-assisted learning features when their verified migration slice is available."
      />
      <ConsentControl
        purpose="voice_processing"
        title="Voice processing"
        description="Allow voice processing when the microphone and speech feature slice is available."
      />
      <Button
        title={isSigningOut ? 'Signing out…' : 'Sign out'}
        disabled={isSigningOut}
        onPress={() => {
          void (async () => {
            setIsSigningOut(true);
            try {
              const result = await signOut(client);
              if (result.kind === 'local-session-cleared') {
                Alert.alert(
                  'Signed out on this device',
                  'We could not confirm remote-session revocation. Sign in from another device and change your password if you need to revoke that session.',
                );
              }
            } catch (error) {
              Alert.alert(
                'Sign-out unavailable',
                error instanceof AuthActionError
                  ? error.userMessage
                  : 'We could not sign you out securely. Try again.',
              );
            } finally {
              setIsSigningOut(false);
            }
          })();
        }}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0B1020',
    flexGrow: 1,
    gap: 16,
    padding: 24,
  },
  title: { color: '#F8FAFC', fontSize: 26, fontWeight: '700' },
  introduction: { color: '#CBD5E1', fontSize: 16, lineHeight: 24, marginBottom: 8 },
});
