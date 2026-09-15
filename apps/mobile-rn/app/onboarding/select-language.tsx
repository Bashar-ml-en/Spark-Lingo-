import { Link, Redirect } from 'expo-router';
import { StyleSheet, Text } from 'react-native';

import { useAuthSession } from '../../src/application/auth-session';
import { StateBody, StateScreen, StateTitle } from '../../src/components/state-screen';

export default function SelectLanguageRoute() {
  const { session, status } = useAuthSession();

  if (status !== 'loading' && !session) {
    return <Redirect href="/welcome" />;
  }

  return (
    <StateScreen>
      <StateTitle>Language selection is next</StateTitle>
      <StateBody>
        No language preference is written by this foundation build. The upcoming
        onboarding slice will use the existing RLS-protected profile contract.
      </StateBody>
      <Link href="/settings/consent" accessibilityRole="link">
        <Text style={styles.link}>Review privacy permissions</Text>
      </Link>
    </StateScreen>
  );
}

const styles = StyleSheet.create({
  link: { color: '#93C5FD', fontSize: 16 },
});
