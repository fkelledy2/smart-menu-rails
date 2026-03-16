For a Rails app, the strongest shortlist is usually:

1. Brakeman — first install, non-negotiable.
   It statically scans Rails code for common security issues without running the app, and both the Rails security guide and OWASP point to code review/scanning as part of a solid Rails security posture.

2. bundler-audit — catches vulnerable dependencies.
   This is the easiest way to detect known CVEs in gems from your Gemfile.lock, which matters because Rails app risk often comes from dependency drift as much as app code.

3. rack-attack — best for brute-force and abuse protection.
   It is a Rack middleware for throttling and blocking abusive requests, and it is commonly recommended for slowing credential stuffing and protecting login/reset endpoints.

4. devise-security — useful if you use Devise and want stronger auth controls.
   This is not required for every app, but it’s a good add-on when you want things like password expiry/history, session limits, and extra hardening around Devise-style authentication flows.

5. secure_headers — helpful if you want stricter browser-side protections.
   It’s commonly used to enforce security headers such as HSTS, frame restrictions, and content-type protections beyond defaults or in a more centralized way.

6. invisible_captcha — good lightweight anti-bot protection for forms.
   For signups/contact forms where full CAPTCHA hurts UX, a honeypot-style approach can be a good first layer. It will not replace rate limiting, but it can reduce low-effort bot noise.

7. active_storage_validations — important if users upload files.
   It helps enforce attachment constraints like file type and size, which is a practical security control for upload surfaces.

My practical recommendation for most production Rails apps:

Always: brakeman, bundler-audit

Usually: rack-attack

If using Devise: devise-security

If handling uploads: active_storage_validations

If exposed public forms: invisible_captcha

If you want tighter header policy: secure_headers