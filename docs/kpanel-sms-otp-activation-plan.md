# KPanel SMS and customer OTP activation plan

## Confirmed provider and purchase

- The selected and purchased SMS panel is **KPanel (کاپنل)**. Do not recommend buying another SMS panel unless the user explicitly changes this decision.
- The purchased plan is the **Copper / مسی** plan: 77,000 toman, including 70,000 toman initial SMS credit.
- The user has already created an API key in KPanel. Never request the key in chat or commit it to the repository; configure it later as a server-side secret/environment variable.
- The user previously checked the shared service-line capability. The working decision was that the Copper plan's shared service lines can support transactional OTP; do not ask them to buy a dedicated line unless KPanel support or current account evidence proves otherwise.

## Why the OTP pattern is pending

- The user entered KPanel's pattern-management section and started creating a dedicated OTP pattern.
- KPanel's pattern form requires the business/company name to appear in the message text.
- KPanel indicated that an app-store listing URL may be used in place of the business name only when the app is actually published and the URL is available, valid HTTPS, relevant to the message/service, and stable.
- The app URL, business name, and URL are fixed text, not pattern variables. The OTP itself is the variable.
- Therefore, do not submit or invent a placeholder store URL. The agreed dependency is to complete the Android app release and obtain its real public listing URL first.

## Agreed sequence

1. Finish the customer-facing Android app while preserving the approved existing UI.
2. Complete release prerequisites documented in mobile/RELEASE.md: confirm permanent application ID, privacy-policy URL and support contact, real screenshots, physical-device checks, API connectivity, and release signing.
3. Publish the app through a suitable marketplace (e.g. Bazaar, Myket, or Google Play, subject to their current publication requirements).
4. Obtain the actual public HTTPS listing URL.
5. Return to KPanel, create and submit the dedicated OTP pattern using the approved fixed company/app identification text and the OTP variable, then wait for KPanel approval.
6. Only after approval, configure KPanel's actual API credentials and approved pattern identifier securely on the backend, implement/verify the correct KPanel API adapter, and test real OTP delivery end-to-end.
7. Enable customer OTP sign-in only after the real delivery test succeeds.

## Implementation cautions

- The repository currently contains an IppanelOtpDelivery adapter targeting edge.ippanel.com. This does **not** establish that KPanel uses the same API or that the adapter is compatible. Do not wire KPanel credentials into this adapter or rename it as a KPanel integration without checking KPanel's official API documentation.
- Keep OTP delivery disabled (503 / unavailable) until the correct KPanel API contract, approved pattern code, sender configuration (if required), and server-side secrets are all verified.
- Do not expose API keys, pattern credentials, or other secrets in Flutter, Git, CI logs, screenshots, or user-facing documentation.
- Do not claim SMS/OTP is production-ready merely because the app is published or a pattern is submitted; require KPanel approval and a successful end-to-end delivery test.
- The user wants this work resumed after the app's public store listing exists; do not repeatedly ask them to re-explain the panel purchase or why the pattern is pending.
