import { Redirect } from 'expo-router';

import { useAuthSession } from '../../src/app/auth-session';
import { StateBody, StateScreen, StateTitle } from '../../src/components/state-screen';

export default function SelectLanguageRoute() {
  const { session, status } = useAuthSession();

  if (status === 'ready' && !session) {
    return <Redirect href="/welcome" />;
  }

  return (
    <StateScreen>
      <StateTitle>Language selection is next</StateTitle>
      <StateBody>
        No language preference is written by this foundation build. The upcoming
        onboarding slice will use the existing RLS-protected profile contract.
      </StateBody>
    </StateScreen>
  );
}
