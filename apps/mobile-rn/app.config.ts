/// <reference types="node" />

import type { ConfigContext, ExpoConfig } from 'expo/config';

type BuildEnvironment = 'development' | 'staging' | 'production';

const buildEnvironmentValues: readonly BuildEnvironment[] = [
  'development',
  'staging',
  'production',
];

function readBuildEnvironment(value: string | undefined): BuildEnvironment {
  const environment = value ?? 'development';
  if (buildEnvironmentValues.includes(environment as BuildEnvironment)) {
    return environment as BuildEnvironment;
  }

  throw new Error(
    'SPARK_LINGO_BUILD_ENV must be development, staging, or production.',
  );
}

function requiredOutsideDevelopment(
  name: string,
  value: string | undefined,
  developmentFallback: string,
  environment: BuildEnvironment,
): string {
  if (value) {
    return value;
  }
  if (environment === 'development') {
    return developmentFallback;
  }

  throw new Error(`${name} must be supplied for ${environment} builds.`);
}

export default ({ config }: ConfigContext): ExpoConfig => {
  const environment = readBuildEnvironment(process.env.SPARK_LINGO_BUILD_ENV);
  const iosBundleIdentifier = requiredOutsideDevelopment(
    'SPARK_LINGO_IOS_BUNDLE_ID',
    process.env.SPARK_LINGO_IOS_BUNDLE_ID,
    'com.sparklingo.sparkLingo.development',
    environment,
  );
  const androidPackage = requiredOutsideDevelopment(
    'SPARK_LINGO_ANDROID_PACKAGE',
    process.env.SPARK_LINGO_ANDROID_PACKAGE,
    'com.sparklingo.spark_lingo.development',
    environment,
  );
  const scheme = requiredOutsideDevelopment(
    'SPARK_LINGO_URL_SCHEME',
    process.env.SPARK_LINGO_URL_SCHEME,
    'sparklingo-development',
    environment,
  );

  return {
    ...config,
    name: environment === 'production' ? 'Spark Lingo' : `Spark Lingo (${environment})`,
    slug: 'spark-lingo',
    version: '0.1.0',
    orientation: 'portrait',
    userInterfaceStyle: 'automatic',
    scheme,
    icon: './assets/icon.png',
    plugins: ['expo-router', 'expo-dev-client', 'expo-secure-store'],
    ios: {
      supportsTablet: true,
      bundleIdentifier: iosBundleIdentifier,
    },
    android: {
      package: androidPackage,
      adaptiveIcon: {
        backgroundColor: '#0B1020',
        foregroundImage: './assets/icon.png',
      },
    },
    web: {
      favicon: './assets/icon.png',
    },
    experiments: {
      typedRoutes: true,
    },
    extra: {
      appEnvironment: environment,
      // These are intentionally empty unless build/runtime configuration
      // supplies public values. There is no production fallback in source.
      supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL ?? '',
      supabasePublishableKey:
        process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? '',
    },
  };
};
