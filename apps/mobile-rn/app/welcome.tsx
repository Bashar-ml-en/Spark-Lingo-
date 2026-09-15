import { Redirect } from 'expo-router';

import { useAuthSession } from '../src/app/auth-session';
import { StateBody, StateScreen, StateTitle } from '../src/components/state-screen';

export default function WelcomeRoute() {
  const { session, status } = useAuthSession();

  if (status === 'ready' && session) {
    return <Redirect href="/onboarding/select-language" />;
  }

  return (
    <StateScreen>
      <StateTitle>Welcome to Spark Lingo</StateTitle>
      <StateBody>
        This is the secure React Native foundation. Authentication, consent,
        and language onboarding will be ported as the next verified slice.
      </StateBody>
    </StateScreen>
  );
}
