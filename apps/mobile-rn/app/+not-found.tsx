import { Link } from 'expo-router';
import { StyleSheet, Text } from 'react-native';

import { StateBody, StateScreen, StateTitle } from '../src/components/state-screen';

export default function NotFoundRoute() {
  return (
    <StateScreen>
      <StateTitle>Page not found</StateTitle>
      <StateBody>This route is not available in the React Native foundation.</StateBody>
      <Link href="/" accessibilityRole="link">
        <Text style={styles.link}>Return to Spark Lingo</Text>
      </Link>
    </StateScreen>
  );
}

const styles = StyleSheet.create({
  link: {
    color: '#93C5FD',
    fontSize: 16,
  },
});
