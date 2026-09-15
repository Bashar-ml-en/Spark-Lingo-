import { StyleSheet, Text } from 'react-native';

import { StateBody, StateScreen, StateTitle } from './state-screen';

export function UnavailableScreen({ errors }: { errors: readonly string[] }) {
  return (
    <StateScreen>
      <StateTitle>Spark Lingo is unavailable</StateTitle>
      <StateBody>
        This build does not have valid public runtime configuration. No account
        or learning data was requested.
      </StateBody>
      {errors.map((error) => (
        <Text key={error} accessibilityRole="text" style={styles.error}>
          {error}
        </Text>
      ))}
    </StateScreen>
  );
}

const styles = StyleSheet.create({
  error: {
    color: '#FCA5A5',
    textAlign: 'center',
  },
});
