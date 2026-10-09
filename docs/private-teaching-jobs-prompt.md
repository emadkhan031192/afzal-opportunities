# DEVELOPMENT PROMPT: ADD PRIVATE TEACHING JOBS MODULE TO AFZAL E SERVICES

## 1. Project Context

There is a working Flutter Android application named **Afzal E Services** in the existing GitHub repository (`emadkhan031192/afzal-opportunities`, package `com.afzaleservices.opportunities`, currently v1.2.0).

The existing application already includes:

- Government job advertisements, Scholarships, Admissions, Other advertisements (Firestore collection: `advertisements`)
- Advertisement search, filters, category chips, sort
- Advertisement details screen with official application links
- Saved advertisements (bookmarks)
- Splash screen, home feed, closing-soon section
- User-designed UI (v1.2.0): pastel card system, A-mark logo, circle launcher icon
- Firebase: project `afzal-opportunities` (Spark plan, `asia-south1`), Email/Password Auth enabled, Firestore live. Collections in use: `advertisements`, `admins`, `categories`. **Firebase Storage is NOT enabled — enabling it requires the Blaze billing upgrade, which is a pending explicit decision by the owner. Do not enable Blaze or change billing without explicit authorization.**
- Web admin panel (exists, do not rebuild): https://emadkhan031192.github.io/afzal-opportunities/ — auto-deploys from `admin/` on push. Admin access = Firebase Auth user with an `admins/{uid}` document.
- CI: `.github/workflows/android-apk.yml` (format → analyze → test → release APK). All tests must keep passing and `flutter analyze` must stay clean.

The v1.3.0 plan (see `docs/v1.3.0-plan.md`) adds app-wide systems the new module **must reuse, not reinvent**:

- **Notifications:** periodic background checks (Workmanager) + local notifications — no Blaze, no server code. Users opt in per notification type. Promotional notifications are always optional.
- **Urdu language option:** full Urdu RTL localization with a persisted language selector.
- **Dark mode:** navy dark theme with a persisted theme toggle.
- **Deadline urgency badges:** green/amber/red by deadline proximity (already computed per ad).
- **Grid-card layout fix:** metadata grouped at top, title as headline, logo + organization as byline.

Your task is to add one completely new module called **"Private Teaching Jobs"** as an extension of the existing app, NOT a new application.

### App-wide features to include with this work

- **Push notifications:** hook the module into the existing notification system. Notify on: new approved teaching vacancies (opt-in), upcoming deadlines on saved/bookmarked teaching jobs, vacancy approval/rejection (for the submitting organization), application status changes. Users choose which notifications they want; promotional notifications must be optional. Never put private CV details or sensitive data in a notification.
- **WhatsApp and Facebook sharing:** add unobtrusive share icons to teaching-vacancy detail screens. Share the title, deadline, short description, and a link back to the item in the app.
- **Afzal E Services WhatsApp Channel:** add a small "Follow our WhatsApp Channel" link in the Profile/About section, with an optional subtle link on Home. No recurring pop-ups; never force users to join.
- **English and Urdu:** the module's UI must be fully localized from day one using the existing localization system, with proper Urdu RTL layout, readable Urdu fonts, and translated buttons, filters, forms, notifications, and error messages. Respect the saved language preference.

## 2. Critical Instructions — Protect the Existing App

Before writing any code:

1. Inspect the existing repository and understand its Flutter architecture.
2. Identify the current navigation system (`lib/screens/main_shell.dart`), theme, reusable widgets, state management, Firebase setup, and folder structure.
3. Inspect the existing bottom navigation bar and determine the safest way to add one new tab.
4. Reuse the existing code, theme, components, and dependencies wherever possible — including the v1.3.0 notification, localization, and theme systems.
5. Do not rebuild the existing app from scratch.
6. Do not redesign or remove any existing screens, features, advertisements, filters, or navigation items.
7. Do not replace the existing Firebase configuration or overwrite existing Firestore collections.
8. Do not modify existing advertisement logic unless an integration change is absolutely necessary.
9. Avoid introducing unnecessary dependencies.
10. Make changes incrementally and test existing functionality after each major change.

If the repository already implements a feature described below, reuse and extend it rather than creating a duplicate.

## 3. Branding and Design

Use the existing Afzal E Services branding:

- Night navy: `#1B1B2D`
- Mint green: `#59BF93`
- White: `#FFFFFF`
- Pastel card palette already in use (lavender splash, yellow/blue list cards, pink/blue grid cards)
- The A-mark logo asset (`assets/logo/a_mark.svg`) and existing fonts, spacing, rounded cards, icons, button styles, and typography

The new module must look like a natural part of the current application.

Keep the UI minimal, fast, readable, and suitable for budget Android phones and users in Khyber Pakhtunkhwa, Pakistan.

Do not introduce unnecessary animations, complicated dashboards, or excessive filter controls.

## 4. Add One New Tab

Add a new bottom-navigation item named **Private Teaching Jobs**. Use an appropriate briefcase, school, or teaching-related icon.

Preserve all existing bottom-navigation items and their order. If adding the new item crowds the navigation bar, use the app's most appropriate existing overflow or secondary navigation pattern rather than redesigning it.

Users must be able to switch between the existing advertisement section and Private Teaching Jobs without losing their place unnecessarily.

## 5. Public Access Without Login

Anyone must be able to open Private Teaching Jobs and browse approved vacancies without registering or logging in.

The public section must contain:

- Search bar
- District filter, Subject filter, Qualification filter, Experience filter (keep it to these four — do not overload the screen)
- Approved teaching-vacancy list (paginated, small batches)
- Vacancy details screen with clear application instructions

Prioritize KP districts initially — Mardan, Peshawar, Swabi, Charsadda, Nowshera, Swat, and others — but design the data structure so additional districts and provinces can be added later.

Each vacancy card shows: job title, school/institution name, district and location, subjects required, required qualification, experience requirement (if any), salary or salary range (if provided), employment type (if provided), posting date, application deadline, vacancy status.

Use the existing deadline-urgency badge system to clearly distinguish closing-soon vacancies. Never invent missing information. Hide expired vacancies from the default feed or clearly mark them as expired.

## 6. Account Types and Authentication

Use Firebase Authentication with email and password. Implement two registration flows within this module:

**A. Organization Account** (private schools, academies, colleges): institution name, institution type, contact person's name, email, password, district, city/locality, contact number, institution address/location description. Optional supporting documents for verification.

**B. Teacher Account** (graduates, teachers, job seekers): full name, email, password, district, qualification, subjects they can teach, teaching experience, preferred employment type, short professional introduction, optional CV upload. Teachers can update their profile and replace their CV.

Do not require login merely to browse vacancies. Use Firebase email-verification and password-reset. Require verified email before a user can submit vacancies or make a teacher profile visible for recruitment. No SMS OTP, no paid phone auth.

## 7. Organization Dashboard

After login, an organization sees: Institution profile · Submit a Vacancy · My Vacancies (Pending / Approved / Rejected) · Edit Profile · Logout.

**Submit a Vacancy form:** job title · institution name (from profile where possible) · district · city/locality · subjects required · classes/grade levels · minimum qualification · required experience · number of positions · salary range (optional) · employment type · gender eligibility (only when legitimately specified) · job description · application deadline · application method · contact/application instructions.

Validate all required fields; reject invalid dates. New submissions get status `pending` — **never auto-publish**. An organization may only create, edit, and view its own submissions. Pending vacancies are editable; material changes to an approved vacancy require admin re-approval.

## 8. Teacher Dashboard

After login, teachers see: My Teacher Profile · Edit Profile · Upload/Replace CV · Browse Teaching Jobs · Saved Teaching Jobs · My Applications (only if in-app applications are implemented) · verification status · Logout.

Teachers must not need to complete every optional field before browsing.

**Privacy (non-negotiable):** teacher profiles are private by default. A teacher may opt in to make their professional profile visible to approved institutions, subject to admin review. Never publish a CV's public download URL; never expose a teacher's private email, phone, or documents to anonymous users. Store CVs at private Storage paths with authorization checks or short-lived access links. Never let organizations bulk-browse private CVs.

## 9. Application Methods

Keep recruitment simple for the initial release:

1. Direct contact with the institution via the method in the approved vacancy.
2. Official application URL, if provided.
3. In-app applications **only** if implementable securely without significantly complicating the project. If implemented: apply with profile + optional CV, and teachers can see application status.

Never force in-app applications when an institution prefers direct contact.

## 10. Admin Approval Panel

**The admin panel already exists** (web, URL in section 1) — extend it, do not build a separate one. Add review sections for:

- **Organizations:** view registration requests, review institution details, approve/reject, suspend/reactivate, view their submissions.
- **Teachers:** review profiles when verification is required, approve/reject public-profile publication, suspend/reactivate, handle reported/misleading profiles.
- **Vacancies:** view pending queue, inspect full submission, approve & publish, reject with optional reason, edit/correct, unpublish/expire, review reported vacancies.

Only the administrator approves institutions, teacher-profile publication, and vacancies. No hardcoded passwords, no editable client-side role fields, no hidden buttons. Use a secure server-side role mechanism (Firebase custom claims or equivalent), verified in Firestore Security Rules. A newly registered user must never be able to grant themselves the admin role.

## 11. Firebase Data Structure

Reuse the existing Firebase project and configuration; do not change existing collections. New collections:

- `teachingOrganizations`: ownerUid, institutionName, institutionType, contactPerson, email, district, city, address, contactNumber, approvalStatus, createdAt, updatedAt
- `teacherProfiles`: ownerUid, fullName, email, district, qualification, subjects, experienceYears, preferredEmploymentType, professionalSummary, cvStoragePath, profileVisibility, approvalStatus, createdAt, updatedAt
- `teachingVacancies`: organizationId, ownerUid, jobTitle, district, city, subjects, gradeLevels, qualification, experienceRequired, positionsCount, salaryMin, salaryMax, employmentType, genderEligibility, description, applicationDeadline, applicationMethod, applicationUrl, contactInstructions, approvalStatus, publishedAt, createdAt, updatedAt
- `teachingApplications` (only if in-app applications are implemented): vacancyId, teacherUid, organizationId, cvStoragePath, coverMessage, applicationStatus, createdAt, updatedAt

Server timestamps where appropriate. Consistent IDs and references; don't duplicate large profiles/CVs into vacancy docs. Never store passwords in Firestore.

## 12. Firebase Storage and Costs

Economical for ~100–1,000 monthly users: compress CVs/logos, enforce file-size limits, allow only PDF for CVs and images for logos, validate type/size client-side (and in rules), never download all CVs on list load, paginate vacancies, use private Storage paths for CVs, delete replaced/abandoned files, no paid SMS.

**Billing: Storage is currently not enabled. Do not enable Blaze or change billing without the owner's explicit authorization.** If a feature (e.g. CV upload) cannot work until Blaze is approved, implement everything else and clearly document the blocker — do not silently degrade security to work around it.

## 13. Security Rules

Write and test Firestore and Storage rules for the new module (extend the version-controlled `firestore.rules` / `storage.rules`):

- Anonymous: read only published, approved, non-expired vacancies and intentionally public data.
- Anonymous: no access to pending vacancies, private teacher profiles, private CVs, internal review notes.
- Organizations manage only their own profile and submissions; teachers only their own profile and applications.
- Users cannot set their own approvalStatus to approved, nor grant themselves admin.
- Only the administrator can approve/reject/suspend/publish.
- CV upload/download requires authorization; users cannot overwrite another user's files via path manipulation.
- No open `allow read, write: if true` rules. Verify with the Firebase Emulator Suite or equivalent, including negative tests.

## 14. User Experience

Simple and responsive: clear navigation, fast loading, readable cards, useful empty states, loading indicators, form validation, clear errors, confirmation before destructive actions, accessible tap targets, small-screen support, and the existing light/dark theme behavior.

## 15. Notifications

Reuse the app-wide notification system from the v1.3.0 plan (periodic background checks + local notifications; no Blaze required). Notify only for relevant, opted-in events: vacancy approval/rejection, organization approval/rejection, application status changes, new relevant teaching vacancies, closing-soon reminders on saved jobs. Never include private CV details or sensitive information in a notification.

## 16. Testing Requirements

Verify: (1) existing ads still load; (2) search/filters still work; (3) saved ads still work; (4) navigation and branding intact; (5) new tab opens; (6) anonymous browsing of approved vacancies; (7–8) org/teacher registration; (9) email verification + password reset; (10) orgs can't touch others' vacancies; (11) teachers can't touch others' profiles; (12) pending vacancies hidden from public; (13) only admin can approve/publish; (14) private CVs not anonymously accessible; (15) expired vacancies handled; (16) small-screen behavior; (17) rules pass authorization tests; (18) CI build green. Run Flutter tests, `flutter analyze`, and the Android build; fix regressions.

## 17. GitHub and Delivery

Work in the existing repository on the current default branch; preserve CI/CD. Focused, reviewable commits. Never commit service-account credentials, private keys, or secrets. Version-control the rules and any indexes. Add a README section for the module. Document every Firebase Console action the owner must perform manually (including the Blaze decision if it blocks a feature). Report all new/modified files, dependencies, and configuration. Provide a verified Actions build link for the APK. If a required config or credential is missing, explain exactly what's needed instead of inventing values.

## 18. Final Objective

Extend Afzal E Services with a secure, lightweight Private Teaching Jobs module connecting KP's private schools, academies, and institutions with teachers — preserving the existing app, reusing its branding, architecture, and v1.3.0 systems, with email/password registration, secure manual admin approval, protected CVs, and low ongoing Firebase costs.

**Start by inspecting the repository and presenting a short implementation plan. Then implement incrementally, test, and report results. Do not replace the working app.**
