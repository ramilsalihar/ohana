# Ohana — Product Requirements Document (MVP)

| | |
|---|---|
| Status | Draft v0.1 |
| Owner | Ramil Salihar |
| Last updated | 2026-10-04 |
| Related | [Research](research.md) · [Product vision](product-vision.md) |

---

## 1. Summary

Ohana is a two-player mobile app for couples, dating or married. It helps partners stay close through small daily rituals that take about two minutes. Each MVP feature maps to a research-backed predictor of relationship satisfaction:

| Research factor | MVP feature |
|---|---|
| Perceived partner commitment (#1 predictor) | Partner activity: visible effort |
| Appreciation (#2 predictor) | Daily appreciation note |
| Love maps (Gottman) | Daily question with mutual reveal |
| Perceived partner satisfaction (#4 predictor) | Weekly check-in |
| Shared meaning, rituals | Together counter & important dates |

## 2. Problem

Most relationships don't end in one explosion; they end through **drift**. The top reasons cited for breakups are lack of intimacy, communication problems, and growing apart (see [research](research.md#2-why-couples-break-up)). Drift is slow and invisible: by the time a couple notices it, they have often stopped noticing each other.

Existing couple apps prove there is demand for daily prompts (Paired, Lovewick, Agapé). They struggle with retention, though, and have damaged user trust through aggressive paywalls.

## 3. Goals and non-goals

### Goals

1. Build a **daily two-person ritual** that both partners return to.
2. Make **appreciation and effort visible** between partners.
3. Surface **early drift signals** through the weekly check-in, without blame.
4. Earn trust through privacy-first design and fair pricing.

### Non-goals (MVP)

- Therapy, conflict coaching, or crisis support
- Finance or expense tracking
- Location sharing or any partner-monitoring feature
- Multi-partner or group spaces
- AI-generated insights (Phase 3)
- Monetization (MVP is free; the paywall arrives after retention is proven)

## 4. Target users

### Persona A: Dating couple ("Discovering")

- Together 6 months to 3 years, may live apart
- Wants to learn about each other, celebrate firsts, and talk about the big topics (kids, money, values)
- Risk: mismatched expectations, uncertainty about where the relationship is going

### Persona B: Married or long-term couple ("Sustaining")

- Together 3+ years, often busy with work and kids
- Wants to keep the spark alive inside routine and feel appreciated, not taken for granted
- Risk: drift, autopilot, the logistics-only relationship

**Shared need:** feeling known, feeling appreciated, and seeing that the partner is invested.

## 5. Success metrics

| Metric | Target (first 3 months post-launch) |
|---|---|
| Pairing completion (invite sent → partner joined) | ≥ 60% |
| D7 couple retention (both partners active) | ≥ 40% |
| D30 couple retention | ≥ 25% |
| Daily question both-answered rate | ≥ 50% of active couples per day |
| Appreciation notes per active couple per week | ≥ 4 |
| Weekly check-in completion (both partners) | ≥ 35% |

**North star:** *weekly connected couples*, meaning couples where both partners completed at least 3 shared rituals in a week.

Retention is measured at the **couple** level, because the app only delivers value when both partners use it.

---

## 6. Features

Priority: **P0** = must ship in MVP, **P1** = should ship, **P2** = later.

### F1. Onboarding and pairing (P0)

Each user creates an account and joins exactly one couple space with their partner.

**User stories**

- As a new user, I can sign up with Apple, Google, or email magic link.
- As a new user, I can create a couple space and share an invite link or 6-character code.
- As an invited partner, I can open the link (or enter the code) and join the space.
- As a user, I can set our "together since" date and my display name and avatar.

**Acceptance criteria**

- A couple has a maximum of 2 members.
- Invite codes expire after 7 days and become single-use once the partner joins.
- A user who is already in a couple cannot join another without unpairing first.
- Before the partner joins, the app shows a "waiting for partner" state that lets the user preview the daily question but does not reveal answers.
- Deep link opens the app if installed, otherwise the App Store / Play Store, and the invite survives install (deferred deep link).

**Edge cases**

- Both partners create separate couples → the joining flow offers "join partner's space instead" and deletes the empty space.
- Invite code shared publicly → single-use plus expiry limits abuse.

---

### F2. Daily question with mutual reveal (P0)

One question per couple per day. Each partner's answer stays hidden until both have answered.

**User stories**

- As a user, I see today's question on the home screen.
- As a user, I can answer in text (up to 500 characters).
- As a user, after answering, I see "Waiting for [partner]…" until they answer.
- As a user, once both have answered, I see both answers side by side and can react with an emoji or a short comment.
- As a user, I can browse past questions and answers in a history view.

**Acceptance criteria**

- The question rotates daily at 04:00 in the **couple's** time zone (set from the first member's device time zone, editable).
- The partner's answer is **never** returned by the API before the requesting user has answered. This rule is enforced server side through RLS or an RPC, not in the client.
- An answer can be edited until the partner answers; after both answers are revealed, it is locked.
- Missed days stay answerable from history, with no penalty for answering late.
- The question bank is tagged by category (fun, deep, future, memories, intimacy-light) and by relationship stage (dating, long-term, any), so it can serve both personas.

**Streak rules (gentle)**

- The streak counts days on which **both** answered.
- Each couple gets 2 freeze days per week, applied automatically.
- A broken streak shows "Start a new streak together"; there is no guilt copy and no indication of who missed.

---

### F3. Daily appreciation note (P0)

A short, low-effort way to tell your partner one thing you appreciated today.

**User stories**

- As a user, I can send an appreciation note (up to 280 characters) from the home screen in one or two taps.
- As a user, I can pick a starter prompt ("Thank you for…", "I loved when you…", "I admire how you…").
- As a user, I receive my partner's note with a gentle push notification.
- As a user, I can see all received notes in a "Love Jar" collection and favorite some of them.

**Acceptance criteria**

- No daily limit, but the home screen nudges once per day if no note has been sent yet.
- Notes are visible only to the couple.
- The sender can delete a note within 5 minutes of sending (to fix a typo or a mis-send); after that, it belongs to the recipient's jar.
- There is no "you sent X, they sent Y" comparison anywhere in the UI.

---

### F4. Partner activity: visible effort (P0)

Makes the partner's investment visible. This addresses perceived commitment, the strongest predictor of satisfaction.

**User stories**

- As a user, I see a small, warm activity strip on the home screen, for example "Sam answered today's question" or "Sam reacted ❤️ to your answer".
- As a user, I get notified when my partner completes a shared action that needs my turn ("Sam answered. Your turn!").

**Acceptance criteria**

- Only **positive actions** are shown: answered, reacted, sent a note, completed a check-in.
- No absence signals: no "last seen", no read receipts, no "Sam hasn't opened the app in 3 days".
- Activity items expire after 48 hours.

---

### F5. Weekly check-in (P1)

A 30-second private pulse on the relationship, shared with the partner.

**User stories**

- As a user, once a week (on a day the couple picks), I rate 4 areas from 1 to 5: **connection, communication, fun, support**.
- As a user, I can add an optional note: "One thing that would make next week better…".
- As a user, after both partners submit, we see each other's ratings and notes (mutual reveal, like F2).
- As a user, I can see a simple trend chart over the past 8 weeks.

**Acceptance criteria**

- Ratings are hidden until both partners submit, or until the week closes. If only one partner submits, that partner sees only their own ratings.
- When either partner rates an area 2 or lower, the app shows a soft conversation starter for that area, not an alarm.
- The trend chart shows each area as a combined couple score by default, with individual scores one tap away.
- The UI never shows framing like "your partner rated lower than you".

---

### F6. Together counter and important dates (P0 counter, P1 dates)

**User stories**

- As a user, I see "Day 1,247 together" on the home screen.
- As a user, I see a countdown to the next milestone (anniversary, every 100 days, or a custom date).
- As a user, I can add important dates (birthday, anniversary, first date, custom) with yearly recurrence.
- As a user, I get a reminder 7 days and 1 day before each important date.

**Acceptance criteria**

- Milestones are computed from the "together since" date: every 100 days, plus yearly anniversaries.
- Either partner can add, edit, or delete important dates, since they are shared.

---

### F7. Notifications (P0)

| Trigger | Copy (draft) | Default |
|---|---|---|
| New daily question | "Today's question is here 💬" | On, at the couple-chosen time |
| Partner answered | "Sam answered. Your turn to reveal!" | On |
| Both answered | "Your answers are revealed ✨" | On |
| Appreciation received | "Sam left something in your Love Jar 💛" | On |
| Check-in day | "30 seconds for us this week?" | On |
| Important date | "Your anniversary is in 7 days" | On |

**Acceptance criteria**

- No more than 3 push notifications per user per day (partner-triggered ones take priority).
- Quiet hours default to 22:00–08:00 local time and are configurable.
- Each category can be toggled individually in Settings.

---

### F8. Account, privacy, and unpairing (P0)

**User stories**

- As a user, I can unpair from my partner.
- As a user, I can export my data (JSON plus images, as a ZIP).
- As a user, I can delete my account.

**Acceptance criteria**

- Unpairing takes effect immediately for both partners. The partner gets a neutral notification: "Your shared space has been closed."
- After unpairing, each partner keeps **read-only access to their own authored content** for 30 days, can export it, and then it is deleted. Shared content (answers to shared questions) is deleted after 30 days.
- Account deletion removes all personal data within 30 days (GDPR/CCPA).
- There is no admin or partner access to the other partner's unrevealed content, ever.

---

### Phase 2 (P2, post-MVP)

- **Bids:** a "thinking of you" tap with quick responses
- **Good news:** share a win; the partner gets prompts to celebrate it (Gable's capitalization research)
- **Date idea deck and bucket list** (novelty research)
- **Memories timeline** with photos
- **Home and lock screen widgets** (counter, partner's latest note)

### Phase 3

- Opt-in desire match (only mutual "yes" answers are revealed)
- AI insights on check-in trends
- Guided conversation packs (money, kids, repair)
- Yearly recap
- Premium tier

---

## 7. UX principles (non-negotiable)

1. **Two-player design:** every screen answers "what does my partner see?"
2. **No scorekeeping:** never compare partners' activity.
3. **Gentle streaks:** freeze days, no guilt copy, no blame.
4. **No surveillance:** no last-seen, read receipts, or location.
5. **Warm, not cheesy:** a calm, grown-up tone.
6. **Graceful endings:** unpairing is respectful and the data is portable.

## 8. Technical requirements

| Area | Decision |
|---|---|
| Client | Flutter (iOS 15+, Android 8+/API 26+) |
| State management | Riverpod |
| Navigation | go_router |
| Backend | Supabase: Postgres, Auth, Realtime, Storage, Edge Functions |
| Authorization | Postgres Row Level Security: a user can only access rows where `couple_id` is in their membership |
| Mutual reveal | Postgres RPC or view that returns the partner's answer only if the caller has answered |
| Push | FCM (Android), APNs via FCM (iOS), sent from Edge Functions |
| Scheduling | `pg_cron` for daily question rotation and reminders |
| Analytics | Privacy-respecting product analytics (PostHog), with no answer content sent |
| Secrets | `.env` files are never committed; build-time config uses `--dart-define-from-file` |

### Data model (MVP)

```
profiles          (id = auth.uid, display_name, avatar_url, timezone)
couples           (id, together_since, timezone, question_time, created_at)
couple_members    (couple_id, user_id, joined_at)               -- max 2 per couple
invites           (code, couple_id, created_by, expires_at, used_at)
questions         (id, text, category, stage)
daily_questions   (couple_id, date, question_id)
answers           (id, couple_id, daily_question_date, user_id, body, created_at, updated_at)
answer_reactions  (answer_id, user_id, emoji, comment)
appreciations     (id, couple_id, from_user, body, favorited, created_at)
checkins          (id, couple_id, user_id, week_start, connection, communication, fun, support, note)
important_dates   (id, couple_id, title, date, kind, recurs_yearly)
activity          (id, couple_id, actor_id, type, ref_id, created_at)   -- 48h TTL
push_tokens       (user_id, token, platform)
```

### Non-functional

- Cold start in under 2 seconds on a mid-range device
- Home screen usable offline (cached); writes queue and sync when the device reconnects
- Accessibility: WCAG 2.1 AA contrast, Dynamic Type / font scaling, screen reader labels
- Localization-ready (ARB files) from day one; English at launch

## 9. Privacy and safety

- Intimate data: encrypted at rest (Supabase default) and TLS in transit.
- No ads, and no data sold or shared with third parties.
- Unrevealed content is protected at the database level.
- Abuse-aware design: no features that let one partner monitor or control the other.
- A clear privacy policy written in plain language.

## 10. Release plan

| Milestone | Scope |
|---|---|
| M0: Foundations | Flutter project, Supabase project, auth, CI, design tokens |
| M1: Pairing | F1 + profile + together counter (F6 counter) |
| M2: Core loop | F2 daily question + F4 activity + F7 push for F2 |
| M3: Appreciation | F3 + Love Jar |
| M4: Check-in & dates | F5 + F6 important dates + remaining F7 |
| M5: Trust | F8 unpair/export/delete, settings, polish |
| Beta | TestFlight / Play internal test with 10–20 couples |

## 11. Open questions

1. Launch segment: dating, married, or both? (The question bank tagging supports both.)
2. Tone and brand: playful or calm? (Affects copy and visual design.)
3. Should the appreciation note support photos in the MVP?
4. Check-in areas: are the four fixed areas right, or should couples customize them?
5. How should couples in different time zones (long-distance) be handled? The MVP uses one couple time zone.
6. Validate the "drift" problem with 5–8 couple interviews before M2.
