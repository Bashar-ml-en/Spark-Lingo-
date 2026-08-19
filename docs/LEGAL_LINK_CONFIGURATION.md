# Legal, support, and data-rights links

Spark Lingo does not bundle policy text, contact details, or a placeholder
support destination. The **Settings & help** screen displays only externally
hosted HTTPS destinations supplied by the release build. Missing or invalid
values are shown as unavailable and cannot be opened.

These values are public build configuration, not secrets. Set them in a
protected release pipeline only after the relevant page has been approved and
published by its accountable owner.

| Build-time key | Required for | Expected destination |
| --- | --- | --- |
| `TERMS_OF_SERVICE_URL` | Legal access; store purchases | Public Terms of Service |
| `PRIVACY_POLICY_URL` | Legal access; store purchases | Public Privacy Policy |
| `AI_AND_VOICE_NOTICE_URL` | AI/voice disclosure | Public AI and voice-processing notice |
| `SUPPORT_URL` | Help & support | Public support/help page |
| `ACCOUNT_DELETION_URL` | External deletion requests | Public request path that works after uninstall |
| `DATA_EXPORT_URL` | Data-rights requests | Public export-request path |
| `SUBSCRIPTION_MANAGEMENT_URL` | Subscription help | Public subscription-management guidance or portal |

The app accepts only HTTPS URLs with a host and rejects URLs containing
embedded credentials. It cannot prove that a URL contains an approved policy;
that is a release-owner and legal/privacy-owner responsibility.

Before distributing a build, the release owner must verify on a physical
Android and iOS device that every configured link opens the intended live page.
The privacy policy, Terms, support page, external deletion path, and data
export process must also be tested from a browser while signed out. Record the
policy version, approval owner, test date, and evidence in the release tracker.

Do not enable store purchases merely because URLs render. Billing remains a
separate release gate requiring approved legal copy and server-verified
entitlements.
