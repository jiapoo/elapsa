# Elapsa launch posts (drafts, 22 Nov 2026)

Everything to post when Elapsa 1.0 goes live (planned 1 Dec 2026). Nothing here
has been posted.

**Order** (from `go-to-market.md` §6):
1. **Release day or the next Tue/Wed:** Show HN, 8–10 AM US Eastern.
2. **The following Tuesday:** Product Hunt, 12:01 AM Pacific.
3. **Reddit:** answering questions only for the first weeks. The one launch
   post goes to r/SideProject, where self-promotion is allowed.
4. **Press emails:** this week, with a TestFlight link, so writers can try it
   before release.
5. **小红书:** January to March.

**Facts used below:** free for 3 documents, then a one-time $9.99 (US). iPhone
only. 10 languages. No account, server or analytics. AES-256 encryption at rest.
App Store: https://apps.apple.com/app/id6835915866 (works once it's live).
Page: https://ljworkshop.com/elapsa/

**Name rule:** LJ Workshop in English; 得趣轩 in Chinese.

---

## 1. Show HN

**Title** (77/80 characters)
```
Show HN: Elapsa – passport and visa reminders that respect the six-month rule
```

**URL:** https://ljworkshop.com/elapsa/

**First comment** (post it the moment the submission is up):

```
Hi HN. I made Elapsa after we nearly missed a trip: while copying passport
numbers into a booking form I noticed one was about to expire. Then I learned
many countries won't let you board with less than six months left, and renewal
can take weeks. So the printed date isn't the real deadline.

Elapsa is an iPhone wallet for passports, visas, ID cards, residence permits,
driving licences and cards. Each kind of document gets its own renewal lead
time, and every passport is flagged when it falls below the six-month rule.

Some engineering details you might find interesting:

- Scanning reads the machine-readable zone (ICAO 9303: TD1/TD2/TD3) and checks
  every field's check digit. OCR mixes up 0/O, 1/I, 5/S and 8/B, so the parser
  tries those repairs and re-validates. A wrong repair fails the check digits
  instead of saving bad data. It's tested against the ICAO specimen documents.

- iOS keeps at most 64 pending local notifications per app and silently drops
  the rest. So reminders are never scheduled per document: every change
  rebuilds the whole set, sorted by date, keeping the soonest 56. It's also
  rebuilt on launch and resume, which catches people who declined the
  permission prompt and turned notifications on later.

- It's Flutter, but text recognition goes through a platform channel to Apple
  Vision. ML Kit's iOS framework is device-only on arm64, which would have made
  the app uninstallable on Apple Silicon simulators. Vision also reads Chinese
  better and adds nothing to the app's size.

- Everything stays on the phone: no account, no server, no analytics. The
  SQLCipher database and the card images are encrypted with one AES-256 key in
  the Keychain that doesn't sync. Moving to a new phone is a direct nearby
  transfer, or one encrypted file over AirDrop.

Free for three documents, then a one-time $9.99 for unlimited. No
subscription. iPhone only for now. Android is half built.

I'd especially like to hear where scanning fails for your documents, and
which renewal lead times are wrong for your country.
```

**On the day:** stay in the comments 3–4 hours. Likely questions:
- **Android:** half built, no date yet.
- **Why not a calendar entry:** lead times differ per document, plus the
  six-month rule and daily reminders in the final month.
- **Why not open source:** answer honestly.
- **Flutter:** see the comment.
- **Which countries enforce the six-month rule:** link the guide page once it
  exists.

Don't ask anyone to upvote.

---

## 2. Product Hunt

| Field | Text |
|---|---|
| **Name** | Elapsa |
| **Tagline** (56/60) | `Know when to renew your passport, not when it's too late` |
| **Topics** | Travel, Productivity, iOS, Privacy |
| **Links** | App Store, ljworkshop.com/elapsa/ |
| **Pricing** | Free options (3 documents free, one-time $9.99) |

**Description** (225/260)
```
Your passport expires six months before it says it does. Elapsa scans
passports, visas and IDs on your iPhone and tells you when to start renewing,
timed to how long each renewal takes. No account, no upload, no subscription.
```

**Gallery:**
1. The captioned preview video: `preview/elapsa-preview-en-v2.mp4`
2. The 4 captioned screenshots in `screenshots/6.9-captioned/`, which are
   1320×2868. PH crops to 1270×760, so make landscape versions: the caption on
   the left and the phone on the right.

**Maker comment:**
```
Hi Product Hunt 👋

Elapsa started when we nearly missed a trip. I was copying passport numbers
into a booking form and noticed one was about to expire. Many countries
won't let you board with less than six months left, and renewing can take
weeks. Nobody in our family had checked in years.

So Elapsa tells you when to START renewing, not when it's too late:
• Hold a passport, visa or ID card to the camera. It reads the
  machine-readable zone and checks every digit, so what's saved is what's
  printed.
• Each document has its own lead time: passports months ahead, visas 90 days,
  residence permits 120 days.
• Every passport is flagged below the six-month travel rule, with daily
  reminders in the final month.
• No account, no server, no analytics. Everything is encrypted on your phone.

Free for three documents, then one purchase of $9.99. No subscription.
In 10 languages, including 简体中文 and 繁體中文.

I'd love to know which documents you'd track first, and what didn't scan
well.
```

**On the day:** share the link with friends and family, asking for feedback,
not upvotes. Answer every comment.

---

## 3. Reddit

### 3a. Profile line (set it now)
```
Solo iOS dev. Made Elapsa, a passport/visa expiry reminder that knows the
six-month rule (ljworkshop.com/elapsa).
```

### 3b. How to answer in r/Passports, r/expats, r/IWantOut (no link)

Answer the person's question with specifics and don't mention the app. Your
profile does that work. Example:

> Short answer: check the entry rules for where you're flying, not just the
> printed date. Many countries (most of Southeast Asia, the UAE, China) want
> six months of validity on arrival, and airlines enforce it at check-in.
> Schengen wants three months beyond your departure date. US passport routine
> renewal is currently running about [X] weeks, so if you're under ~9 months
> it's worth starting now.

Mention Elapsa only if someone asks what you use. Even then, say you're the
developer.

### 3c. r/SideProject launch post (once, after the Show HN)

**Title**
```
I nearly missed a trip because of a passport's six-month rule, so I built an app that warns you early
```

**Body**
```
We were booking flights when I noticed a passport in our family was about
to expire. I didn't know many countries refuse boarding with less than six
months left, or that renewal can take weeks.

So I built Elapsa (iPhone): a wallet for passports, visas, IDs and residence
permits that reminds you when to *start* renewing. Each document type has
its own lead time.

Things I'm proud of:
- Scanning reads the passport's machine-readable zone and checks every check
  digit, so it doesn't save a wrong number.
- It works around iOS's 64-notification limit by rebuilding the whole
  reminder schedule on every change.
- No account, no server, no analytics. Everything is encrypted on the phone.

Free for 3 documents, then $9.99 once. I'm the developer, and I'd really like
feedback on scanning and on renewal lead times for your country.

[App Store link]
```

---

## 4. Press

### 4a. English email (one writer at a time)

**Subject**
```
Elapsa: passport reminders that count back from the six-month rule (indie, privacy-first)
```

**Body**
```
Hi [first name],

I enjoyed your piece on [specific article]. I'm a solo developer, and on
[date] I'm releasing Elapsa, an iPhone app that tells people when to start
renewing a passport or visa, not when it expires. Many countries refuse
boarding with under six months left, so the printed date isn't the real
deadline.

It scans the passport's machine-readable zone on the device, checks every
check digit, and keeps everything encrypted on the phone: no account, no
server, no analytics. Free for three documents, then a one-time $9.99.

A TestFlight build is here if you'd like to try it before release:
https://testflight.apple.com/join/uAqtPsFh
Screenshots, video and icons: https://ljworkshop.com/press/elapsa/

Thanks for reading,
[name]
LJ Workshop
```

**Who, and which angle:**

| Outlet | Angle |
|---|---|
| MacStories | Indie app, Vision on-device, privacy |
| 9to5Mac | New app, travel season |
| TidBITS | Practical: the six-month rule most people don't know |
| Six Colors | Short item: indie, no subscription |
| Travel blogs/newsletters | The six-month rule, January–March renewal season |

The press kit is live at `ljworkshop.com/press/elapsa/` (Chinese:
`/zh/press/elapsa/` and `/zh-hant/press/elapsa/`). Before sending, set up a
TestFlight public link or invite writers by email.

### 4b. 少数派 (sspai) pitch, in Chinese

**标题**
```
独立开发者投稿：Elapsa，按"六个月规则"提前提醒你换护照
```

**正文**
```
你好，

我是得趣轩的独立开发者。我们家差点因为护照快过期而耽误一次旅行，才知道很多国家要求护照剩余有效期至少六个月，换发又要好几周。护照上印的日期，其实不是真正的截止日。

所以我做了 Elapsa（iPhone）：把护照、签证、身份证、居留许可、驾照放进来，它会按每种证件真实的办理周期，在该开始办理的时候提醒你。

· 对准相机扫描，读取护照机读区并逐位校验，存下的就是印着的
· 护照有效期不足六个月会单独标出，最后一个月每天提醒
· 不用注册，没有服务器，不做统计；数据加密存在手机里
· 支持简体、繁体等 10 种语言
· 前 3 份证件免费，之后一次性购买，不是订阅

很适合经常出入境、在海外生活的读者。TestFlight 抢先体验：https://testflight.apple.com/join/uAqtPsFh；截图、预览视频和图标在这里：https://ljworkshop.com/zh/press/elapsa/

谢谢！
[名字]
得趣轩 · https://ljworkshop.com/zh/elapsa/
```

---

## 5. 小红书 (简体, January to March)

**标题**
```
护照其实早半年就"过期"了｜我做了个提醒App
```

**正文**
```
差点因为护照耽误一次旅行😭

订机票的时候翻出护照抄号码，才发现快到期了。
更吓人的是：很多国家要求护照剩余有效期≥6个月，不够的话航司可能直接不让登机。换护照又要好几周……

所以我自己做了一个App：Elapsa
✅ 对准相机扫描护照/签证/身份证，自动读取，逐位校验
✅ 按每种证件的办理周期，提前提醒你"该开始办了"
✅ 护照不足6个月单独标红，最后一个月每天提醒
✅ 不用注册、不上传，数据加密只存在手机里
✅ 前3份免费，之后一次性买断，不是订阅

适合：留学生、海外华人、经常出差旅行的家庭
App Store 搜：Elapsa（目前只有 iPhone）

你们家的证件多久没检查过了？评论区聊聊👇

#护照 #签证 #出国 #海外生活 #留学生 #移民 #独立开发 #效率App
```

Use the 简体 captioned screenshots as the carousel images, with the passport
"92 days, start renewing now" screen first.
