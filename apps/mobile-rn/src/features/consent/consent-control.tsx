import { useState } from 'react';
import { Button, Linking, StyleSheet, Text, View } from 'react-native';

import type { ConsentPurpose } from './legal-notices';
import { useConsent } from './use-consent';

export function ConsentControl({
  purpose,
  title,
  description,
}: {
  purpose: ConsentPurpose;
  title: string;
  description: string;
}) {
  const consent = useConsent(purpose);
  const [noticeError, setNoticeError] = useState<string | undefined>(undefined);
  const errorMessage =
    noticeError ??
    (consent.error instanceof Error
      ? consent.error.message
      : 'We could not update this permission. Try again.');

  return (
    <View style={styles.card}>
      <Text accessibilityRole="header" style={styles.title}>
        {title}
      </Text>
      <Text style={styles.description}>{description}</Text>
      {consent.notice ? (
        <Button
          title={`Read ${consent.notice.title}`}
          onPress={() => {
            void (async () => {
              try {
                await Linking.openURL(consent.notice!.url);
                setNoticeError(undefined);
              } catch {
                setNoticeError('The privacy notice could not be opened. Try again.');
              }
            })();
          }}
        />
      ) : null}
      {consent.status === 'loading' ? <Text style={styles.status}>Checking permission…</Text> : null}
      {consent.status === 'unavailable' ? (
        <Text style={styles.status}>
          The current approved notice is unavailable, so this permission stays off.
        </Text>
      ) : null}
      {consent.error || noticeError ? <Text style={styles.error}>{errorMessage}</Text> : null}
      {consent.status === 'granted' ? (
        <>
          <Text style={styles.status}>Allowed for notice version {consent.notice?.version}.</Text>
          <Button
            title={consent.isMutating ? 'Updating…' : 'Withdraw permission'}
            disabled={consent.isMutating}
            onPress={() => {
              void consent.withdraw();
            }}
          />
        </>
      ) : null}
      {consent.status === 'denied' ? (
        <Button
          title={consent.isMutating ? 'Updating…' : 'Allow'}
          disabled={consent.isMutating}
          onPress={() => {
            void consent.accept();
          }}
        />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#17203A',
    borderColor: '#334155',
    borderRadius: 12,
    borderWidth: 1,
    gap: 10,
    padding: 16,
  },
  title: { color: '#F8FAFC', fontSize: 18, fontWeight: '700' },
  description: { color: '#CBD5E1', fontSize: 14, lineHeight: 20 },
  status: { color: '#C4B5FD', fontSize: 14, lineHeight: 20 },
  error: { color: '#FCA5A5', fontSize: 14, lineHeight: 20 },
});
