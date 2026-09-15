import { Redirect, useLocalSearchParams } from 'expo-router';

import { useAuthSession } from '../../src/app/auth-session';
import { StateBody, StateScreen, StateTitle } from '../../src/components/state-screen';

const canonicalLanguageCode = /^[a-z]{2,3}(?:-[A-Z]{2})?$/;

export default function HomeRoute() {
  const { langCode } = useLocalSearchParams<{ langCode: string }>();
  const { session, status } = useAuthSession();

  if (status === 'ready' && !session) {
    return <Redirect href="/welcome" />;
  }

  if (!langCode || !canonicalLanguageCode.test(langCode)) {
    return <Redirect href="/onboarding/select-language" />;
  }

  return (
    <StateScreen>
      <StateTitle>Course shell: {langCode}</StateTitle>
      <StateBody>
        Curriculum is not loaded until the verified language and curriculum
        parity slice is implemented.
      </StateBody>
    </StateScreen>
  );
}
