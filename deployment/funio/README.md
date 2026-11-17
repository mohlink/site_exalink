# EXALINK — Deployment to Funio (draft, not yet activated)

This repository is a **public preview** hosted on GitHub Pages. The existing WordPress website and DNS remain unchanged.

## What is already functional

- Bilingual pages with English as the default and French available through a switch.
- The About page, service details, and a contact **draft** generator.
- Contact drafts are built in the visitor's browser; no message is transmitted to EXALINK.

## Future production contact sending (Funio only)

The directory `deployment/funio/api` contains a PHP backend **prototype**. It is **not** used on GitHub Pages and is **not yet production-ready or tested on Funio**.

Before enabling it:

1. Confirm the recipient address (and make sure the future Funio mailbox is functional). Never add passwords to GitHub.
2. Check the specific Funio hosting account provides **PHP 8.1+**, `mbstring`, sessions, outbound SMTP access, and TLS.
3. Install PHPMailer through Composer into a private directory accessible to PHP, using `deployment/funio/composer.json` as a dependency reference.
4. Copy `deployment/funio/config.example.php` to an actual configuration file **outside `public_html`**, using the verified SMTP host, port, credentials, sender and recipient. Do not publish the private configuration file.
5. Configure an environment variable `EXALINK_CONFIG_PATH` pointing to that absolute private file (or arrange an equivalent secure server-side configuration mechanism).
6. Deploy `api/csrf.php` and `api/contact.php` in `public_html/api/` on Funio, with HTTPS and restrictive permissions. Their contents should not be exposed as downloadable source.
7. Add explicit frontend integration (currently **not enabled**): fetch a token from `/api/csrf.php`, then POST JSON to `/api/contact.php` with `token`, `name`, `company`, `email`, `phone`, `subject`, `message`, `website` (empty honeypot). Use server success response before displaying any "message sent" confirmation.
8. Test a successful delivery and failure cases: missing token, wrong Origin, invalid email, malformed JSON, honeypot, oversized request, repeated submits and SMTP unavailability.
9. Add a privacy notice identifying contact-data processing and retention, and a more robust anti-abuse layer (e.g. IP-based rate limits and a server-side bot challenge) before public launch.
10. Verify email DNS and delivery (SPF, DKIM, DMARC) without changing the current Microsoft 365 mail routing prematurely.

### Security guidance

- Never commit SMTP passwords, mailbox passwords or private customer information into this public repository.
- The current in-memory/session-based throttle is insufficient as a complete public abuse defense; additional IP or perimeter controls are recommended.
- Do not activate the PHP backend until it has been tested in the actual Funio environment.
- GitHub Pages **does not execute PHP**.
- Use a separate staging hostname/domain or temporary Funio URL to test. Do not point `exalink.ca` to the new site or cancel FastComet until everything is verified.
- Do not copy the public source files containing `deployment/` into the web root indiscriminately. Deploy only the appropriate static pages and validated server-side files.

## Publishing a static preview on GitHub Pages

GitHub Settings → Pages → Deploy from a branch → `main` → `/ (root)`.

The preview URL is:
https://mohlink.github.io/site_exalink/

## Final commercial validation

Before launch, confirm official contact details, wording of all advertised activities, image rights, privacy text, mobile appearance, and SEO metadata.


## Prepared frontend adapter (November 2026)

The file `contact-delivery.js` is now included by `contact.html`, but **remains inactive** because the page contains:

```html
<body data-page="contact" data-contact-mode="draft">
```

In this mode, a visitor may prepare an email draft addressed to **info@exalink.ca**, but the website does not send an email.

After the PHP backend is independently verified on an HTTPS Funio staging location, change **only the Funio staging copy** of the contact page to:

```html
<body data-page="contact" data-contact-mode="smtp">
```

**Do not change the GitHub Pages version to smtp mode.** The adapter checks for HTTPS and refuses to activate on `github.io`. On a configured Funio site, the browser obtains a same-origin CSRF token from `api/csrf.php` and submits to `api/contact.php`. It only displays a success confirmation if the server confirms `ok: true` and `message: sent`.

Files required in the Funio web root: `contact.html`, `corporate.js`, `corporate.css`, `contact-delivery.js`, the other public site assets, and the two PHP files under `api/`. Do not deploy the `deployment/` folder as public content. SMTP credentials must be stored outside the web root.

### Missing hosting information before live activation

- Confirm the Funio hosting plan's PHP version and `mbstring` extension, SMTP server name, supported TLS port, and whether external SMTP connections are permitted.
- Confirm which mailbox/account sends the message. A Microsoft 365 alias (`info@exalink.ca`) may receive messages without being able to authenticate by itself as an SMTP account.
- Confirm the commercial recipient `info@exalink.ca` receives mail with the current Microsoft 365 routing, then again after the migration.
- Confirm a privacy notice, anti-spam controls beyond a simple session rate limiter, and backend logging of failures without logging message bodies.
- Test all submit, validation, replay and failover cases in staging. The PHP backend here is a **prototype**, not a certified production service.

No changes to MX records, website DNS, WordPress, or Microsoft 365 are needed for this preparation.
