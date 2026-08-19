const fs = require('fs');
const path = require('path');

function requiredEnvironment(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}.`);
  }
  return value;
}

function isProjectRef(value) {
  return /^[a-z0-9]{20}$/.test(value);
}

function assertStagingOnlyTarget() {
  if (process.env.SPARK_LINGO_SEED_ENV !== 'staging') {
    throw new Error('This seed uploader is staging-only. Refusing to run outside the staging environment.');
  }

  const projectRef = requiredEnvironment('SUPABASE_PROJECT_REF');
  const stagingRef = requiredEnvironment('SPARK_LINGO_STAGING_PROJECT_REF');
  const productionRef = requiredEnvironment('SPARK_LINGO_PRODUCTION_PROJECT_REF');

  if (![projectRef, stagingRef, productionRef].every(isProjectRef)) {
    throw new Error('A configured Supabase project reference is invalid.');
  }
  if (projectRef !== stagingRef || projectRef === productionRef) {
    throw new Error('The target must exactly match the configured staging project and differ from production.');
  }

  const accessToken = requiredEnvironment('SUPABASE_ACCESS_TOKEN');
  return { projectRef, accessToken };
}

async function main() {
  if (!process.argv.slice(2).includes('--apply')) {
    console.error('Refusing to upload seed SQL without an explicit --apply confirmation. No request was sent.');
    process.exitCode = 2;
    return;
  }

  let target;
  try {
    target = assertStagingOnlyTarget();
  } catch (error) {
    // Do not include environment values or tokens in output.
    console.error(`Refusing to upload seed SQL: ${error.message}`);
    process.exitCode = 2;
    return;
  }

  const query = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
  try {
    const response = await fetch(
      `https://api.supabase.com/v1/projects/${encodeURIComponent(target.projectRef)}/query`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${target.accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      },
    );

    if (!response.ok) {
      console.error(`Seed upload failed with HTTP ${response.status}.`);
      process.exitCode = 1;
      return;
    }
  } catch {
    console.error('Seed upload failed before a response was received.');
    process.exitCode = 1;
    return;
  }

  console.log('Staging seed SQL executed successfully.');
}

main();
