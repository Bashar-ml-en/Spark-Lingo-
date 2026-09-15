import type { PropsWithChildren } from 'react';
import { StyleSheet, Text, View } from 'react-native';

export function StateScreen({ children }: PropsWithChildren) {
  return <View style={styles.container}>{children}</View>;
}

export function StateTitle({ children }: PropsWithChildren) {
  return (
    <Text accessibilityRole="header" style={styles.title}>
      {children}
    </Text>
  );
}

export function StateBody({ children }: PropsWithChildren) {
  return <Text style={styles.body}>{children}</Text>;
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    backgroundColor: '#0B1020',
    flex: 1,
    gap: 12,
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    color: '#F8FAFC',
    fontSize: 24,
    fontWeight: '700',
    textAlign: 'center',
  },
  body: {
    color: '#CBD5E1',
    fontSize: 16,
    lineHeight: 24,
    maxWidth: 480,
    textAlign: 'center',
  },
});
