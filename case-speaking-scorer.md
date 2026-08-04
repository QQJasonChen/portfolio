# Case study source — Dutch Exam Ace speaking scorer

Working notes. The published version lives in `casestudy.html`.

## The situation

Dutch Exam Ace grades candidates' spoken Dutch against the DUO A2 criteria and
returns a score across seven dimensions. Candidates use that score to decide
whether they are ready to book the real exam — which costs money, takes weeks to
schedule, and has a failure cost measured in residency paperwork.

So the score is not a nice-to-have feature. It is a decision input.

## What was wrong

**1. It was scoring things it could not see.**
The scorer reported pronunciation errors. But the pipeline transcribes speech to
text first, and transcription normalises spelling — by the time the model sees the
answer, every word is spelled correctly regardless of how it was pronounced.
Pronunciation was structurally invisible, and the model was inventing plausible
errors to fill the field.

**2. It implied an authority it did not have.**
The UI read "DUO 官方 7 維度評分" — *official DUO seven-dimension scoring*. It is
not official. It is my approximation of the published criteria.

**3. The failing range was improvised.**
The rubric described what a 6 and an 8 looked like. It said nothing about 1–3 or
4–5. Every score in the range that actually matters — the range where a candidate
should not book the exam yet — was the model making it up.

**4. The free tier contradicted the marketing.**
Grading quota was one per day. A mock exam is twelve questions. So a free user
completed a full mock exam and received a score for question one. The landing page
promised a free mock exam. Both statements were true and together they were a lie.

**5. Feedback came back in the wrong language.**
The prompt said "respond in Traditional Chinese". Production returned whole
paragraphs of Dutch. The audience is Chinese speakers who do not yet read Dutch —
feedback they cannot read is not feedback.

## What I changed, and why that order

**Stopped claiming what the model cannot know.** Pronunciation and fluency are now
explicitly labelled AI inference, not measurement. The prompt forbids claiming the
official rubric and forbids inventing pronunciation errors.

**Then made fluency real instead of removing it.** Fluency *is* measurable — just
not from text. Transcription moved to word-level timestamps, and the service now
computes speaking rate, pause count and longest pause directly, then hands those to
the scorer as measured evidence. The dimension survived because it became true,
not because it sounded good.

**Anchored the failing bands.** Added explicit descriptions for 1–3 and 4–5, so the
scores that carry real consequence are the ones the rubric actually defines.

**Fixed the free tier to match the promise.** Quota moved to 15 for anonymous users
and 30 once logged in — enough to complete a full mock exam, which is what the page
had been promising all along.

**Made the model swap survivable.** Feedback in Dutch traced to a preview model with
weak instruction-following. I moved the endpoint to a stable model — with automatic
fallback to the previous one, because I could not verify the new model ID locally
and a model change must never be able to take grading down. The Chinese-output rule
was promoted to the highest-priority block with worked positive and negative
examples, then applied across the other four grading endpoints.

**Made the rate limiter fail closed.** When the limiter's backend errored it
previously let every request through — unbounded spend on an AI endpoint. It now
returns 503 "system busy", and deliberately *not* "quota exhausted", because a
misleading error trains users to distrust the real one.

## What I would tell a hiring panel

The interesting decision was not which model to use. It was noticing that a field
in my own output was structurally unknowable, and being willing to say so in the UI
of a product I wanted people to trust.

Everything downstream followed from that: measure what can be measured, label what
cannot, define the bands where the answer changes someone's behaviour, and make sure
no single model choice can take the feature down.

## Noted, not yet resolved

Twelve AI features still run on one preview model. I fixed the one where being wrong
had the highest cost to a user and wrote the rest down as known single-point risk
rather than pretending it was handled.
