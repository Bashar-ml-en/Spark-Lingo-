// Static, no-network guard for the controlled staging deployment workflow.
// It detects accidental removal of key safety controls before CI receives any
// staging credential. It reads source only and never loads environment values.

const fs = require('fs');
const path = require('path');

const workflowPath = path.join(__dirname, '..', '.github', 'workflows', 'staging-deploy.yml');
const workflow = fs.readFileSync(workflowPath, 'utf8');

const requiredFragments = [
  'workflow_dispatch:',
  "if: ${{ github.ref_type == 'tag' }}",
  'environment: staging',
  'apply_after_dry_run_review:',
  'group: spark-lingo-staging-deployment',
  'persist-credentials: false',
  'scripts/validate_staging_target.ts',
  'supabase db push --linked --dry-run',
  'supabase db push --linked',
  'supabase functions deploy sparky-ai',
  'supabase functions deploy delete-account',
  'inputs.deploy_billing_webhook',
  'supabase functions deploy revenuecat-webhook',
  'SUPABASE_STAGING_ACCESS_TOKEN',
  'SUPABASE_STAGING_DB_PASSWORD',
  'SUPABASE_PRODUCTION_PROJECT_REF',
  'SUPABASE_PRODUCTION_URL',
];

for (const fragment of requiredFragments) {
  if (!workflow.includes(fragment)) {
    throw new Error(`Staging deployment workflow is missing a required safety control: ${fragment}`);
  }
}

const guardIndex = workflow.indexOf('Run non-network staging target preflight');
const firstSecretIndex = workflow.indexOf('SUPABASE_STAGING_ACCESS_TOKEN');
const migrationIndex = workflow.indexOf('Apply forward-only staging migrations');
const functionIndex = workflow.indexOf('Deploy user-facing staging functions');

if (guardIndex < 0 || firstSecretIndex < 0 || guardIndex >= firstSecretIndex) {
  throw new Error('Staging credentials must not be scoped before the non-network target guard.');
}
if (migrationIndex < 0 || functionIndex < 0 || migrationIndex >= functionIndex) {
  throw new Error('Staging migrations must be applied before user-facing function deployment.');
}
if (!workflow.includes('if: ${{ inputs.apply_after_dry_run_review }}')) {
  throw new Error('Staging mutation steps must require explicit dry-run review approval.');
}
if (!workflow.includes('if: ${{ inputs.apply_after_dry_run_review && inputs.deploy_billing_webhook }}')) {
  throw new Error('Billing webhook deployment must require both staged-apply and billing approval.');
}
if (workflow.includes('--no-verify-jwt')) {
  throw new Error('User-facing staging deployment must not disable JWT verification.');
}
if (workflow.includes('--prune')) {
  throw new Error('Staging deployment must not prune remote functions.');
}

console.log('Staging deployment workflow static validation passed.');
