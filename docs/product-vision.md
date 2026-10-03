# Product Vision & MVP

## Positioning

**Fight the drift.** Small daily signals that you are known and appreciated — about two minutes a day, for dating and married couples alike.

## Core loop

```
Daily prompt → I answer → hidden → partner answers → both revealed → react/comment → streak +1
```

Why it works:

- **Curiosity gap** — you can't see your partner's answer until you answer.
- **Two-sided pull** — "Alex answered. Your turn." is the main retention driver.
- **Low effort** — ~60 seconds.
- **Compounding value** — after a year, answers become a shared memory book.

## MVP scope

1. **Couple pairing** — invite code / link, one shared couple space
2. **Daily question with mutual reveal** — love maps + daily habit
3. **Daily appreciation note** — #2 predictor of satisfaction; underused by competitors
4. **Visible partner effort** — activity cues that address perceived commitment (#1 predictor)
5. **Weekly 30-second check-in** — perceived satisfaction + early drift detection
6. **Relationship counter & important dates** — days together, anniversaries, reminders
7. **Push notifications**

### Phase 2

- "Thinking of you" bids and "good news" posts
- Novel date idea deck + bucket list
- Shared memory timeline
- Home / lock screen widgets (days together, partner mood)

### Phase 3

- Opt-in desire match
- AI insights on check-in trends
- Guided conversation packs (money, kids, conflict repair)
- Yearly recap

### Not early

Finance tracking, conflict coaching, AI therapist — high risk, hard to do well.

## UX principles

1. **Two-player design** — every screen asks "what does my partner see?"
2. **No scorekeeping** — never show "you did 70% of answers." Show shared progress only.
3. **Gentle streaks** — freeze days or "weeks connected"; a broken streak must not create guilt or blame.
4. **Warm, not cheesy** — calm and charming, not clip-art hearts.
5. **Graceful breakup** — unpair flow with archive / export / delete of shared data.
6. **Safety by design** — no location tracking or read-receipt surveillance that a controlling partner could misuse.
7. **Fair pricing** — one subscription per couple; never paywall features that were free.

## Data model (draft)

```
users ─┬─ couple_members ─── couples
       │                       ├── prompt_answers (couple_id, prompt_id, user_id, answer, revealed_at)
       │                       ├── appreciations   (couple_id, from_user, body, created_at)
       │                       ├── checkins        (couple_id, user_id, week, scores jsonb)
       │                       ├── important_dates (couple_id, title, date, recurrence)
       │                       └── memories        (couple_id, media, date, note)
```

The mutual-reveal rule must be enforced **server side** (RLS policy or RPC) so a partner cannot read the other's answer through the API before answering.

## Monetization (draft)

Freemium, priced **per couple** (~$5–8/month, one purchase unlocks both partners).

- Free: daily question, appreciation notes, counter, important dates
- Premium: question packs, check-in trends, widgets, yearly recap, AI insights

## Open questions

- Primary target segment for launch: dating, married, long-distance, or all?
- Tone: playful vs. calm and grown-up?
- Does "drift" resonate as a problem? → validate with 5–8 couple interviews
