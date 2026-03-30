# Demo Booking — User Guide

## Overview

The Demo Booking feature on the mellow.menu homepage lets prospective restaurant owners book a live product demonstration or watch a recorded walkthrough video. It captures key information about the restaurant (type, size, interests) so the sales team can prepare a relevant demo, and it sends an automatic confirmation email with next steps.

## Who This Is For

- **Prospective restaurant owners and operators** who want to learn more about mellow.menu before signing up.
- **The mellow.menu sales team** who receive lead information and follow up with prospects.

## Prerequisites

No account or login is required. The demo booking form is publicly accessible on the mellow.menu homepage.

## How To Use

### Booking a Live Demo

1. Visit the mellow.menu homepage.
2. Click **Book Live Demo** in the hero section.
3. A booking form appears. Fill in:
   - Your name
   - Your restaurant name
   - Your email address
   - Phone number (optional)
   - Restaurant type (e.g., casual dining, fine dining, cafe, fast casual)
   - Number of locations
   - What you are most interested in learning about (optional free text)
4. Read and accept the privacy policy (required — your email address is collected to send the confirmation and for the sales team to follow up).
5. Click **Request Demo**.
6. A Calendly scheduling widget appears. Choose a date and time that works for you to book your live session.
7. You will receive a confirmation email with your booking details and what to expect during the demo.

### Watching the Recorded Demo

1. Visit the mellow.menu homepage.
2. Click **Watch Demo** in the hero section.
3. The demo video plays in a modal. Watch at your own pace.
4. After watching, the **Book Live Demo** option is also available if you want to see a personalised walkthrough.

## What Happens After You Book

- You receive a confirmation email immediately with your demo date, a summary of what to expect, and a calendar invitation link.
- The mellow.menu sales team receives your details and will review them before your scheduled call.
- If you need to reschedule or cancel, use the link in the confirmation email to manage your Calendly booking.

## For the mellow.menu Sales Team

Demo booking submissions are accessible in the admin panel:

1. Sign in to the admin panel.
2. Go to **Demo Bookings** in the admin navigation.
3. The table shows all submissions with the prospect's details, restaurant type, location count, and booking status.
4. You can export the list as a CSV for reporting or import into other tools.

Each submission records:
- Contact name and email
- Restaurant name and type
- Number of locations
- Interests (free text)
- Submission date
- Conversion status (pending by default)

## Key Concepts

**Demo booking** — a lead record created when a prospect submits the homepage form. It captures context for the sales conversation.

**Conversion status** — the current state of a demo booking lead (pending, contacted, converted, etc.). Updated manually by the sales team.

**Calendly widget** — the scheduling interface that appears after a successful form submission. It shows the sales team's live availability and lets the prospect book a slot directly.

## Tips & Best Practices

For sales reps:
- Review the "interests" field before each demo call — it tells you what the prospect most wants to see.
- "Location count" is a strong signal for enterprise intent. Prospects with more than 3 locations should be prioritised.
- Export to CSV weekly for pipeline tracking.

## Limitations & Known Constraints

- The booking form is rate-limited: a maximum of 5 submissions per IP address per hour. Prospects who hit this limit will see an error message.
- CRM integration (HubSpot, Salesforce) is not available in v1. The `demo_bookings` table in the admin panel serves as the lead record.
- Automated follow-up email sequences are not available. Follow-up is manual.
- A/B testing of different demo videos is not available.
- The recorded demo video must be produced and hosted separately — the platform embeds an existing video.

## Frequently Asked Questions

**Q: I submitted the form but did not receive a confirmation email. What should I do?**
A: Check your spam or junk folder first. If it is not there, re-submit the form with your correct email address. The confirmation email is sent within 60 seconds of a successful submission.

**Q: Can I book a demo without scheduling via Calendly?**
A: The Calendly scheduling widget appears after you submit the form. If you cannot find a suitable time, email the mellow.menu team directly using the contact details in the footer of the confirmation email.

**Q: Will my details be used for marketing purposes?**
A: Your details are used by the mellow.menu sales team to prepare for and follow up on your demo. See the mellow.menu privacy policy (linked on the form) for full details.

**Q: I am an existing restaurant owner, not a prospect. Should I use this form?**
A: No — existing customers should contact support through the platform or via the support email address. The demo booking form is for new prospects only.
