# Elapsa — go-to-market plan

iOS first · global English, 简体 / 繁體 secondary · free with a one-time unlock ·
solo, zero paid budget · written 19 Oct 2026

---

## 1. The strategic read

**The competition is not the other apps. It is Apple Reminders and nothing at all.**

Every app in this category launched in the last twelve months and none of them has
won. Passport Pro has too few ratings to show a score. RenewalKit has one rating.
DocTock, Expire Me, VisaStay, XPAT and Renu:Wise are all 2026 entrants with no
installed base. There is no incumbent to displace and no brand to outspend — but
also no proven demand curve, because the overwhelming majority of people who have
this problem currently solve it by forgetting about it.

That means the job of the marketing is **not** "pick Elapsa over RenewalKit." It is
"realise you have a problem at all." Everything below follows from that.

**The wedge is the six-month rule, not the reminder.**

A reminder app is a commodity and reads like one. The six-month travel rule is a
*surprising fact*: your passport stops working roughly six months before the date
printed on it, and most people do not know this. Surprising facts travel. Reminders
do not. Every piece of content, every screenshot caption and the subtitle should
lead with the gap between the printed date and the useful date.

The supporting fact is the one already in the README: US routine renewal runs about
4–6 weeks of processing plus mail on both ends, so 6–8 weeks door to door, and UK
renewals from overseas run three to four weeks with no fast-track available. An
alert three weeks out is not a warning, it is a notification of failure. Elapsa is
the only app in the set whose data model encodes renewal *lead time* as a first-class
concept separate from the expiry date. That is the defensible claim.

**Positioning statement**

> For people whose life runs on documents — expats, people on visas and residence
> permits, frequent travellers, families with four passports between them — Elapsa
> is a document wallet that tells you when it is time to *start* renewing, not when
> it is time to panic. Unlike the expiry-reminder apps, Elapsa knows how long each
> renewal actually takes and that a passport is unusable six months before it
> expires. Everything stays on the phone, encrypted, with no account and no server.

**Three messaging pillars**, in priority order:

1. **Early, not late.** "96 days left · start renewing now" — the app's own language.
2. **It reads the document, it doesn't make you type it.** MRZ check digits mean a
   scan that validates is near-certain to be right. This is a quality claim nobody
   else can make credibly.
3. **Nothing leaves the phone.** No account, no upload, AES-256 at rest. Table
   stakes to claim, decisive once someone is pointing a camera at their passport.

Pillar 3 is a *closer*, not an opener. Privacy does not make anyone download an app
they didn't know they needed; it makes them finish the scan.

---

## 2. What has to be true before any of this runs

These are launch blockers, not marketing tasks, but the plan is worthless if they
slip. Honest status from the repo:

| Blocker | State | Why it gates launch |
|---|---|---|
| Camera on real hardware | **Never tested** — scanner has only run against the photo library | The scanner is the hero of every screenshot and the first thing a new user does. A camera bug on day one is a 1-star review that never washes out |
| In-app purchase | **Not built** — no `in_app_purchase` in `pubspec.yaml` | The whole monetisation model below assumes it |
| Android | OCR channel half-done, no SDK on this machine, nothing built or tested | **Do not plan an Android launch.** Treat it as a month-3+ decision |
| Store metadata | Screenshots exist at `marketing/screenshots/6.9/`, captions do not | §4 |
| Landing page | Does not exist | Needed for Show HN, Reddit and the content asset |

Add to that: localisation ships EN / zh-Hans / zh-Hant, so list exactly those three
in App Store Connect and no more. Claiming languages you don't have earns refund
requests.

---

## 3. Pricing

**Recommendation: free up to 3 documents, then $12.99 one time. No subscription.**

Competitor anchors, for calibration:

- Passport Pro — $19.99 lifetime, $9.99/mo, $59.99/yr
- RenewalKit — $44.99 unlimited one-time, $59.99 unlimited, $4.99/mo, $34.99/yr
- Expire Me — $4.99 paid upfront
- DocTock — 2 documents free, then paid

$9.99 is leaving money on the table against a $19.99–$59.99 anchor. $12.99 reads as
deliberate rather than cheap, and for an app with no server costs a one-time price is
the *honest* one — which matters, because "no subscription" is a sentence you can put
in the subtitle region of the description and it converts.

Set the free tier at **3 documents**, not 1 or 2. Three covers passport, licence and
one more — enough that the app proves itself and earns a review before it asks for
money. The wall then lands exactly where the app becomes valuable: the second person
in the household, or the visa + residence permit stack. That is the moment someone
pays, and they will not resent it.

**Launch tactic — Founding users.** Ship 1.0 with the purchase built but unlocked
free for everyone who installs in the **first 30 days**, stated plainly in the
description and in-app. It costs almost nothing (there is no revenue to forgo at zero
installs), it converts the app's biggest weakness — zero ratings — into a reason to
act now, and the people who take it are precisely the ones who leave reviews and tell
other expats. Set a hard date; do not extend it.

---

## 4. ASO — the single highest-leverage thing you will do

With no budget, App Store search *is* the acquisition channel. Apple indexes the app
name, subtitle and keyword field together, so never repeat a word across them.

**App name (30 chars).** "Elapsa" alone wastes 24 characters of the most heavily
weighted field in the store. Use:

```
Elapsa: Passport & ID Expiry
```
(28 chars)

**Subtitle (30 chars).** Must carry the lead-time idea, not restate the category:

```
Renewal alerts that come early
```
(30 chars) — or `Know when to start renewing` (27) if you want it plainer.

**Keyword field (100 chars).** No spaces after commas; no words already used above;
no plurals, Apple handles those:

```
visa,document,renewal,reminder,tracker,expiration,date,license,licence,residence,permit,travel,green
```
(exactly 100) — `license` and `licence` are both there deliberately, US and
Commonwealth spellings are not matched to each other. `green` picks up "green card."

**Screenshots.** The first two carry most of the decision and are visible without
scrolling in search results. The current exports are raw screens with no captions —
that is a wasted asset. Required set, in order:

1. The wallet, captioned **"Your passport expires 6 months before it says it does."**
   The existing `01-wallet.png` already shows the `Below the 6-month travel rule`
   flag on a passport. Crop so that line is unmissable.
2. **"96 days left — and renewing takes 8 weeks. Start now."** The lead-time
   proposition, in one screen.
3. The scanner mid-capture: **"Scans the passport's machine-readable zone. Check
   digits, not guesses."**
4. **"No account. No upload. Encrypted on your phone."**
5. The notification on a lock screen: **"Told in time, by default."**

**Description.** First three lines are all that shows before "more" — spend them on
the six-month rule, not on a feature list. Put `No subscription. One purchase.` and
`Nothing leaves your phone.` in the first paragraph.

**Timing.** Passport and visa search demand peaks January–March, as people book
summer travel. **Submit in November.** That gives six to eight weeks to accumulate
ratings and let Apple's index settle before the one period of the year when the
category's demand triples. Launching in January means launching unrated into the
peak and wasting it.

---

## 5. Channels, in order of expected return

### 5.1 Show HN — do this, it is your unfair advantage

The `README.md` is already an excellent engineering post and almost nobody shipping
in this category can write one. The MRZ check-digit repair that re-validates rather
than corrupting data; iOS silently capping an app at 64 pending notifications; why
OCR is a platform channel because ML Kit's iOS framework is device-only arm64 and
would make the app uninstallable on an Apple Silicon simulator; registering the
channel in `didInitializeImplicitFlutterEngine` because `window` is nil under the
scene lifecycle. That is a real post.

Write it as **"Show HN: Elapsa — a document expiry tracker that warns you when
renewal starts, not when it ends."** Lead with the product in two sentences, then go
straight into the engineering. Post Tuesday–Thursday, 8–10am US Eastern. Be in the
comments all day. Expect a few thousand visits if it catches, several hundred if it
doesn't, and — more valuable than either — a handful of the exact technical people
who will actually file good bug reports.

Cost: one day of writing. Do not skip it.

### 5.2 Communities — slow, compounding, the real engine

Where the audience actually is:

- **r/Passports** — the highest-intent subreddit on the internet for this. It is
  wall-to-wall panic posts about timelines.
- **r/expats, r/IWantOut, r/digitalnomad, r/immigration**
- Country-specific: **r/germany, r/JapanLife, r/singapore, r/HongKong, r/ukvisa** —
  residence permits and long-stay visas are where the pain is worst and where
  Elapsa's 120-day lead time for residence permits reads as expertise
- **FlyerTalk** and TripAdvisor forums for the six-month rule
- **小红书** for the Chinese build — 签证到期 / 护照换发 content performs well there,
  and almost nothing in this category is localised into 繁體

**The rule: answer the question, do not post the link.** Spend the first month
answering timeline questions with genuinely useful specifics and no mention of the
app. Put Elapsa in your profile. Mention it only when someone asks what you use.
Reddit will remove you and remember you otherwise, and r/Passports in particular is
unforgiving. Budget 20 minutes a day; this is the channel that still pays in month
six.

### 5.3 One content asset, reused everywhere

Build **one** page, not a blog:

> **"Your passport expires six months before it says it does."**
> What the six-month rule is, which countries enforce it, what the printed date
> actually means, and how long renewal really takes in the US, UK, EU, Canada and
> Australia — with a table.

It answers a question people genuinely search, it is linkable in Reddit answers
without being promotional, it is the Show HN landing page, and it is the thing
someone forwards to their partner. Every other piece of content you make for the next
six months is a cut-down of this one. Translate it into 简体 and 繁體 for 小红书.

Host it on your own domain with the App Store link at the bottom, not in the middle.

### 5.4 Product Hunt

Modest for mobile utilities, free, and worth one day. Launch Tuesday. Same copy as
Show HN with the engineering trimmed and the screenshots doing the work. Do not build
a campaign around it.

### 5.5 Reviews

The flywheel that matters most and costs nothing. Prompt with
`SKStoreReviewController` **after a successful scan**, never on launch and never on
a reminder — ask when the user has just watched the app do the impressive thing.
Cap at one ask per version. Twenty honest ratings will out-convert any copy you write.

---

## 6. Twelve weeks

**Weeks −2 to 0 (late Oct – early Nov) — unblock**
Test the camera on a real device. Build the IAP and the founding-user unlock. Rewrite
the store name, subtitle, keywords and description per §4. Caption the screenshots.
Put up the landing page with the six-month-rule article on it. Submit.

**Week 1 — launch**
Approval, then: Show HN on a Tuesday or Wednesday. Product Hunt the following
Tuesday. Post nothing to Reddit yet. Watch crash reports obsessively; a 1.0.1 inside
a week is a good sign, not a bad one.

**Weeks 2–6 — earn standing**
Daily 20 minutes in r/Passports and the expat subs, answering only. First 小红书
posts in 繁體 and 简体. Ship 1.0.x fixes fast and reply to every App Store review,
including the bad ones. Run an ASO iteration at week 4: change the subtitle *or* the
first screenshot, not both, and read the conversion rate.

**Weeks 7–12 — convert**
Founding-user window closes at day 30 — announce it ending, which is itself a reason
for people to install. Start mentioning the app in communities where you now have
history. Ship the feature the reviews ask for, whichever it turns out to be. Decide
on Android with real data in hand, not before.

**January** — the demand peak arrives and you are already indexed, rated and
answering questions in the places people ask them.

---

## 7. Measuring it, without lying to yourself

**A working renewal app looks dead in a retention chart.** Someone who scans four
documents in week one and does not open the app again for nine months is a *perfect*
outcome, and D7 retention will score it as a failure. Do not optimise against it, and
do not let a dashboard talk you into adding engagement features this app should not
have.

Track instead:

| Metric | Why | Rough target by week 12 |
|---|---|---|
| Product page conversion rate (App Store Connect) | The only honest read on whether the screenshots and subtitle work | 30%+ from search |
| **Documents added per install** | The real activation metric | 2.5+ |
| Notification permission grant rate | A denied prompt makes the app pointless; §README explains the timing already built for this | 70%+ |
| Scan-vs-manual entry share | Tells you whether the hero feature actually works in the wild | 50%+ |
| Ratings count, then average | Compounds into search ranking | 25+ ratings |
| Free→paid conversion, after day 30 | Validates the $12.99 | 3–5% |

Review the ASO numbers weekly, everything else monthly. With no paid spend there is
nothing to optimise daily and pretending otherwise just burns the one resource you
have, which is your own time.

---

## 8. The honest risks

- **The category is being flooded.** Seven-plus entrants in twelve months, all
  unrated. Someone will spend money on it. Elapsa's defence is not features, it is
  the lead-time concept and the engineering credibility — both of which are hard to
  copy quickly and neither of which shows up in a feature-comparison table.
- **The six-month-rule claim must stay accurate.** Enforcement varies by country and
  changes. Keep the in-app wording advisory, keep the "confirm with the embassy"
  disclaimer that Passport Pro also carries, and keep the article's country table
  dated.
- **Camera untested on hardware is the single biggest execution risk** to
  everything above.
- **iOS-only halves the addressable market**, and expats skew Android in exactly
  the countries where the pain is worst. Accept it for now; revisit at month three.

---

## 9. Arete

Decide the publisher identity *before* Elapsa ships, because it is almost impossible
to change afterwards: both apps under one App Store developer name, one domain with
two product pages, one support address. A second shipped app makes the first look
less like an experiment, and the App Store developer page becomes a real
cross-promotion surface the moment there are two things on it.

The rest depends on what Arete is — tell me and I will fold it in properly.

---

## Sources

- [RenewalKit on the App Store](https://apps.apple.com/us/app/id6758590671) —
  pricing, languages, positioning
- [Passport Pro: Travel Docs on the App Store](https://apps.apple.com/us/app/id6773447729) —
  pricing, positioning, disclaimer language
- [U.S. passport renewal timing, 2026](https://us.trip.com/guide/info/passport-renewal.html) —
  routine 4–6 weeks processing, plus mail
- [UK overseas passport renewal timing](https://www.barchart.com/story/news/35933931/new-2025-data-reveals-how-long-it-really-takes-to-renew-a-british-passport-overseas) —
  three to four weeks, no fast-track from abroad
- Check [travel.state.gov](https://travel.state.gov) for live US processing times
  before putting any number in the article or the app.
