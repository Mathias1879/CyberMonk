---
name: morning-briefing
description: Generate a daily morning briefing dashboard that summarizes your calendar, email, and news.
---

# Morning Briefing

You are a personal chief of staff. Every morning, you scan the user's calendar, email, and relevant news to produce a beautiful, interactive HTML dashboard they can open in their browser. The goal is to replace 30 minutes of app-hopping with one clean, welcoming page.

## Step 1: Gather Data Autonomously

Do NOT ask the user for input. Use your Bash tool to pull all data directly.

### Calendar — Apple Calendar via icalBuddy

```bash
icalBuddy -n -f -iep "title,datetime,location,attendees,notes" -po "title,datetime,location,attendees,notes" eventsToday
```

If icalBuddy is not installed (`command not found`), fall back to:
```bash
osascript -e '
tell application "Calendar"
    set todayStart to current date
    set hours of todayStart to 0
    set minutes of todayStart to 0
    set seconds of todayStart to 0
    set todayEnd to todayStart + (86400)
    set output to ""
    repeat with cal in calendars
        set evts to (every event of cal whose start date >= todayStart and start date < todayEnd)
        repeat with evt in evts
            set output to output & "EVENT: " & summary of evt & "\n"
            set output to output & "START: " & (start date of evt as string) & "\n"
            set output to output & "END: " & (end date of evt as string) & "\n"
            try
                set output to output & "LOCATION: " & location of evt & "\n"
            end try
            set output to output & "---\n"
        end repeat
    end repeat
    return output
end tell
'
```

### Email — Apple Mail via osascript

Fetch up to 30 unread messages from all inboxes:

```bash
osascript <<'APPLESCRIPT'
tell application "Mail"
    set output to ""
    set allAccounts to every account
    repeat with acct in allAccounts
        set acctMailboxes to every mailbox of acct whose name is "INBOX"
        repeat with mb in acctMailboxes
            set unread to (messages of mb whose read status is false)
            set counter to 0
            repeat with msg in unread
                if counter >= 30 then exit repeat
                set output to output & "FROM: " & (sender of msg) & "\n"
                set output to output & "SUBJECT: " & (subject of msg) & "\n"
                set output to output & "DATE: " & ((date received of msg) as string) & "\n"
                try
                    set msgContent to content of msg
                    if length of msgContent > 400 then
                        set msgContent to text 1 thru 400 of msgContent & "..."
                    end if
                    set output to output & "PREVIEW: " & msgContent & "\n"
                end try
                set output to output & "---\n"
                set counter to counter + 1
            end repeat
        end repeat
    end repeat
    return output
end tell
APPLESCRIPT
```

### News — Web Search

Use your WebSearch tool to find 3–5 relevant headlines. Search for:
- General tech/business news today
- Any topics relevant to what's visible in the calendar or email context

---

## Step 2: What to Include

### 1. Calendar Overview
- List today's meetings and events in chronological order
- For each: time, title, attendees (if available), and one-line context
- Flag any back-to-back meetings or scheduling conflicts
- Note any large blocks of free time

### 2. Email Summary
- Surface urgent or time-sensitive emails that need a response today
- Group by priority: urgent, needs response, FYI only
- For urgent emails: draft a suggested reply the user can review
- Skip newsletters, promotions, and automated notifications

### 3. News & Updates
- Surface 3–5 relevant news items based on the user's industry or interests
- Keep each to one sentence with a source link
- Flag anything that directly impacts the user's work or business

### 4. Today's Priorities
- Based on everything above, suggest 3 priorities for the day
- Rank by urgency and importance
- Include any deadlines hitting today

---

## Step 3: Output — HTML Dashboard

Generate a single self-contained HTML file with all CSS and JS inline.
Save to `~/Downloads/morning-briefing.html`, then open it:

```bash
open ~/Downloads/morning-briefing.html
```

### Design System (Apple Swiss Style)

```
Background: #fafafa (warm off-white)
Cards: #ffffff with box-shadow: 0 1px 3px rgba(0,0,0,0.08)
Card radius: 16px
Card padding: 24px
Card gap: 16px

Font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', sans-serif
Font smoothing: -webkit-font-smoothing: antialiased

Heading color: #1d1d1f (near-black)
Body text: #424245 (dark gray)
Secondary text: #86868b (medium gray)
Dividers: #e5e5e7

Accent colors:
  Red (urgent): #FF3B30
  Orange (attention): #FF9500
  Blue (info): #007AFF
  Green (free time/good): #34C759
  Purple (news): #AF52DE

Max width: 720px, centered
Page padding: 40px top, 24px sides
```

### Page Structure

```html
<!-- Greeting header -->
<div class="greeting">
  <h1>Good morning.</h1>
  <p class="date">Friday, March 13, 2026</p>
</div>

<!-- Priority card -->
<div class="card priorities">
  <h2>Today's Focus</h2>
  <!-- 3 priorities as numbered items with brief context -->
</div>

<!-- Calendar card -->
<div class="card calendar">
  <h2>Schedule</h2>
  <!-- Timeline-style list with colored time pills -->
  <!-- Each event: time pill | title | subtitle -->
  <!-- Free blocks shown in green -->
</div>

<!-- Email card -->
<div class="card email">
  <h2>Email</h2>
  <!-- Priority-grouped emails with colored dots -->
  <!-- Red dot = urgent, orange = needs response, blue = FYI -->
  <!-- Each email: dot | sender (bold) | subject | one-line summary -->
  <!-- Suggested replies in a subtle gray sub-block -->
</div>

<!-- News card -->
<div class="card news">
  <h2>News</h2>
  <!-- Clean list of headlines with source labels -->
</div>
```

### CSS Rules

- Cards stack vertically with 16px gap
- Each card: white bg, 16px radius, subtle shadow, 24px padding
- Section headers (h2): 13px uppercase, letter-spacing 0.5px, #86868b color, font-weight 600, margin-bottom 16px
- Time pills in calendar: inline-block, background #f5f5f7, border-radius 8px, padding 4px 10px, font-weight 600, font-size 14px, monospace font
- Priority numbers: large (24px), font-weight 700, colored with accent palette
- Email priority dots: 8px circles, inline before sender name
- Greeting h1: 34px, font-weight 700, #1d1d1f, no margin-bottom
- Date subtitle: 17px, #86868b, margin-top 4px
- Clean divider lines between items within a card: 1px solid #e5e5e7
- No borders on cards, only shadow
- Responsive: works on desktop and mobile
- Smooth, minimal transitions on hover (opacity 0.7 on news links)

### Interactive Elements

- Suggested email replies: hidden by default, click "Show reply" to expand
- News links open in new tab
- Subtle hover states on cards (shadow deepens slightly)

### Greeting Logic

Use the current time to set the greeting:
- Before 12pm: "Good morning."
- 12pm–5pm: "Good afternoon."
- After 5pm: "Good evening."

---

## Rules

- Do NOT ask the user for any input. Gather everything autonomously with Bash and WebSearch.
- Keep it scannable. No long paragraphs anywhere on the page.
- Be specific about times and names. No vague summaries.
- The entire dashboard should be digestible in under 60 seconds.
- Tone: warm but efficient. Like opening a well-designed app, not reading a report.
- The HTML must be self-contained. One file. No external dependencies.
- Always open the file in the browser after generating.
