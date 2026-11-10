# Gradleless — Launch Pack
Drafts for the loud launch. Post AFTER the GitHub push. Written 17 Oct 2026.

---

## 1. LinkedIn Post

**I got tired of waiting for Gradle. So I built my own APK builder.**

Every small Android project I built, Gradle took minutes just to say hello.
For tiny apps, that's overkill. So I spent a week building **Gradleless** —
a dependency-free CLI that turns a project folder into a signed, zipaligned
APK using only `aapt2` + `d8`. No Gradle. No Android Studio. No network.

- Full build of the starter app: **seconds**, not minutes
- Zero network calls — builds fully offline
- 5 explicit pipeline stages you can read in one shell script

And I didn't ship it untested — every sample APK was verified with
`aapt dump badging` + `apksigner verify` before I pushed.

🔗 GitHub: https://github.com/iamcipherdev/gradleless
📦 MIT licensed. PRs welcome — especially the parts I got wrong.

If you've ever stared at a Gradle progress bar and questioned your life
choices, this one's for you.

#AndroidDev #OpenSource #BuildTools #Kotlin #Java

---

## 2. Reddit r/androiddev

**Title:** I built a Gradle-free APK builder (aapt2 + d8 pipeline as a CLI) — looking for brutal feedback

**Body:**

Hey r/androiddev — I kept hitting the same wall: tiny Android apps that take
Gradle minutes to build. So I built **Gradleless**, a small CLI that compiles a
simple project folder straight to a signed APK using only the SDK build-tools
(`aapt2`, `d8`, `zipalign`, `apksigner`) + a JDK. No Gradle, no Android Studio,
no network access at all.

What's in it:
- One shell script, 5 pipeline stages (compile → link → javac → d8 → package/sign)
- Starter template + a WebView-wrapper example ("URL do, APK lo" style)
- Auto debug keystore, asset/jar/jniLibs support

I test-before-publish as a rule: every sample APK was verified with
`aapt dump badging` + `apksigner verify` before I pushed.

Repo: https://github.com/iamcipherdev/gradleless (MIT)

Honest question for the room: where does this break for real-world apps?
I'm guessing manifest merging for big AARs and resource shrinking are the
first walls. Tell me what I'm missing — I want the roadmap to be driven by
actual Android devs, not my guesses.

---

## 3. Hacker News (Show HN)

**Title:** Show HN: Gradleless – Build signed Android APKs without Gradle

**Body:**

Gradleless is a dependency-free CLI that turns a simple project folder into a
signed, zipaligned APK using only the Android SDK build-tools (aapt2, d8,
zipalign, apksigner) and a JDK. No Gradle, no Android Studio, no network.

I built it because Gradle felt like overkill for small apps — full builds of
the starter template take seconds. The pipeline is 5 explicit stages in one
readable shell script, so there's no magic.

Every sample APK was verified with `aapt dump badging` + `apksigner verify` before I published.
MIT licensed: https://github.com/iamcipherdev/gradleless

---

## Posting checklist
- [ ] GitHub repo pushed + README renders correctly
- [ ] LinkedIn post (with repo link)
- [ ] Instagram reel (screen recording of a build: "Gradle vs Gradleless" speed demo)
- [ ] Reddit r/androiddev (follow sub rules — no self-promo spam, engage in comments)
- [ ] Hacker News Show HN (post in the morning US time for visibility)
