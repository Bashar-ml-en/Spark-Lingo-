import { Redirect } from 'expo-router';

import { useAuthSession } from '../src/app/auth-session';
import { StateBody, StateScreen, StateTitle } from '../src/components/state-screen';

export default function IndexRoute() {
  const { session, status } = useAuthSession();

  if (status === 'loading') {
    return (
      <StateScreen>
        <StateTitle>Opening Spark Lingo</StateTitle>
        <StateBody>Restoring your secure session.</StateBody>
      </StateScreen>
    );
  }

  if (status === 'error') {
    return (
      <StateScreen>
        <StateTitle>Session unavailable</StateTitle>
        <StateBody>
          Your session could not be restored. Sign in again when authentication
          is ported.
        </StateBody>
      </StateScreen>
    );
  }

  return <Redirect href={session ? '/onboarding/select-language' : '/welcome'} />;
}
