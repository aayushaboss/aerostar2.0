# Desktop layout audit

Shared system: `lib/ui/tokens.dart` (container, spacing scale, type, colour, radius), `lib/ui/page_shell.dart` (PageShell, ContentWidth, 360px rail that stacks under 1100px), `lib/ui/components/components.dart` (PageHeader, SectionHeader, ListRow, UiCard, InfoBox, HighlightCard, UiTabs, UiButton, StatusText, UiProgress, UiField). The top bar (`AppTopNav`) sits in the same container, so the logo, page title and first content share one left edge.

Checked in the browser: Home at 1280, Network at 1920 (equal side space, logo and title on the same left edge). Not checked at 1440 or 1024.

| Route / screen | Type | State |
|---|---|---|
| /tabs Home | B1 | Rebuilt on PageShell: highlight card is the only highlight, rail without dividers |
| /tabs/profile Profile | B1 | Rebuilt on PageShell |
| /tabs/browse Applications | B2 table | Rebuilt: plain tabs with counts, uppercase headers, status dot and text |
| /tabs/network Network | B2 | Rebuilt: plain stats row, plain tabs, 4-col people grid, 3-col companies, invitations in rail |
| /saved, /recruiter-actions, /applications/recently-deleted, /tabs/sessions (Bookings) | B2 | Use PageFrame, which is now on PageShell and PageHeader; bodies are still list rows, not card grids |
| /opportunities (list, search) | B3 | Rebuilt: 220px filter column, 56px gap, results. Search results are not grouped by Internships / Jobs / Companies. Filters drawer not built |
| /opportunity/:id Detail | B4 | Rebuilt: 320px action card with facts and the one yellow action. Card does not stay fixed while scrolling |
| /tabs/career-dna Career Quiz | B9 | Rebuilt: zigzag path plus 420px Up next highlight card |
| /messages, /messages/:id | B5 | Container with 1px border, received grey, sent blue. Profile panel for chats opened from a profile not built |
| /application/:id, /search-appearances, /support | B4 / B6 | Use PageFrame; bodies are the earlier layouts (no horizontal timeline, no 2-column topic grid) |
| /college/resume, /person/:id, /company/:id | B4 | Not migrated: older frames, left edge not on the new container |
| /profile-edit | B6 | Not migrated |
| Career Quiz level intro, question, results | B7 | Not migrated (no top bar, not in container) |
| /booking, /booking-confirmed | B6 / B8 | Not migrated |
| Video profile (sheet) | B7 | Not migrated |
| /onboarding, /auth/*, /college/goals, /onboarding/profile, /onboarding/complete | B6 / B8 | Not migrated |
| /college/resume/chat, /college/resume/build, /college/resume/import | B7 | Not migrated |
| Notifications panel | panel | Placed under the 64px bar; not re-laid out |
| /story/:id, /dev/style-guide | - | Left as is |
