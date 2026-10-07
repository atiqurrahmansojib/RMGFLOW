# RMGFlow Mobile App: User Manual

**App:** RMGFlow for Android (version 0.1.0). The icon on your phone's home screen is labelled **Tanabana**.
**Audience:** everyone at the buying house who uses the app: owners and managers, merchandisers, sampling, production, quality, commercial, accounts and factory coordinators.
**Last checked against the app:** 7 October 2026.

This manual describes only what the app does today. Anything that is planned but not built yet is listed under [Known limitations](#94-known-limitations).

---

## Contents

1. [What RMGFlow is and who it is for](#1-what-rmgflow-is-and-who-it-is-for)
2. [Installing the app and connecting to the server](#2-installing-the-app-and-connecting-to-the-server)
3. [Signing in, sessions and signing out](#3-signing-in-sessions-and-signing-out)
4. [The Home screen and how to get around](#4-the-home-screen-and-how-to-get-around)
5. [Modules, in business order](#5-modules-in-business-order)
   - [5.1 Buyers](#51-buyers)
   - [5.2 Factories and vendors](#52-factories-and-vendors)
   - [5.3 Inquiries](#53-inquiries)
   - [5.4 Styles](#54-styles)
   - [5.5 Costing](#55-costing)
   - [5.6 Quotations](#56-quotations)
   - [5.7 Approvals](#57-approvals)
   - [5.8 Sampling](#58-sampling)
   - [5.9 Orders and amendments](#59-orders-and-amendments)
   - [5.10 T&A calendar and templates](#510-ta-calendar-and-templates)
   - [5.11 Production](#511-production)
   - [5.12 Quality: inspections, defects and CAPA](#512-quality-inspections-defects-and-capa)
   - [5.13 Shipments](#513-shipments)
   - [5.14 Documents](#514-documents)
   - [5.15 Financials, receivables and payables](#515-financials-receivables-and-payables)
   - [5.16 Claims](#516-claims)
   - [5.17 Activity log (calls, emails, meetings, notes)](#517-activity-log-calls-emails-meetings-notes)
   - [5.18 Tasks](#518-tasks)
   - [5.19 Notifications](#519-notifications)
   - [5.20 My Day](#520-my-day)
   - [5.21 More, Reference data and Profile](#521-more-reference-data-and-profile)
6. [Reports](#6-reports)
7. [End-to-end walkthrough: from inquiry to payment](#7-end-to-end-walkthrough-from-inquiry-to-payment)
8. [Quick guides by role](#8-quick-guides-by-role)
9. [Troubleshooting and FAQ](#9-troubleshooting-and-faq)
10. [Glossary](#10-glossary)
11. [Recommendations for the next version](#11-recommendations-for-the-next-version)

---

## 1. What RMGFlow is and who it is for

RMGFlow is the day-to-day system for a Bangladesh garment buying house. It follows an order through its whole life:

```
Buyer asks for a price (Inquiry)
  -> you develop the garment (Style, Samples)
  -> you work out the cost (Costing) and offer a price (Quotation)
  -> the buyer places a PO (Order)
  -> you track every critical date (T&A), daily output (Production) and quality (Inspections)
  -> you ship the goods (Shipment) with the paperwork (Documents)
  -> you collect from the buyer and pay the factory (Financials)
  -> you handle any complaints (Claims)
```

Around that flow, the app gives you:

- **Approvals** for costings, quotations and sample revisions, with a full history of every decision.
- **Tasks**, an **activity log** and **notifications** so nothing gets forgotten.
- **My Day**, one screen that lists what needs your attention today.
- **Reports** with 15 business reports that you can view on screen and download as CSV (Excel) or PDF.

**Who uses it.** Each person signs in with their own account. What you see and what you can change depends on your **role**. There are 12 roles, explained in [section 3.4](#34-roles-and-demo-accounts) and [section 8](#8-quick-guides-by-role). The server checks every action. The app also hides the Home tiles your role cannot open.

**One company per account.** All data belongs to your organisation. You never see another company's buyers, orders or money.

---

## 2. Installing the app and connecting to the server

### 2.1 What you need

- An Android phone or tablet.
- The APK file `app-release.apk` (about 58 MB). Your administrator gives you this file or a download link.
- A network connection to the RMGFlow server. For a local demo, the phone must be on the **same Wi-Fi** as the computer running the server.

### 2.2 Install the APK

1. Download `app-release.apk` on the phone. For the office demo, open the link your administrator gives you in the phone's browser, for example `http://192.168.0.110:8081/app-release.apk`.
2. Open the downloaded file from the browser's download bar or from the **Files** or **Downloads** app.
3. If Android says *"For your security, your phone is not allowed to install unknown apps from this source"*:
   - Tap **Settings** in that message.
   - Turn on **Allow from this source** for the browser or Files app you used.
   - Press Back and tap **Install** again.
   - The exact wording varies by phone brand. On older phones the switch is under **Settings > Security > Unknown sources**.
4. If Google Play Protect warns that the app is unknown, tap **More details > Install anyway**. The app comes from your own company, not from the Play Store, so this warning is expected.
5. Tap **Open**, or find the **Tanabana** icon in your app drawer.

**Updating:** install the new APK over the old one. You stay signed in, and your remembered email is kept.

**Uninstalling:** long-press the icon and tap **Uninstall**. This signs you out and deletes downloaded files that are stored inside the app. Reports you saved to `Download/RMGFlow` stay on the phone.

### 2.3 Which server the app talks to

The server address is **built into the APK** when your administrator builds it. You cannot type a server address inside the app.

- To see which server your copy uses, sign in and go to **More > Profile & settings**. The **Server** line shows the address, for example `http://192.168.0.110:8090/api/v1`. Tap the copy icon to copy it.
- If the server's address changes (for example, the office PC gets a new IP address), your administrator must build a new APK. For the office demo they run `./scripts/demo.sh build`, and you install the new APK.

**For administrators (demo setup):** run `./scripts/demo.sh` on the server PC. It starts the database, starts the backend on port 8090 with demo data, and shares the APK at `http://<PC-IP>:8081/app-release.apk`. If the PC's IP address changed since the last build, run `./scripts/demo.sh build` instead. A real deployment must use HTTPS. The app only allows plain `http://` for the listed test addresses (`192.168.0.110`, `10.0.2.2` and `localhost`).

### 2.4 Light and dark mode

The app follows your phone's theme. Switch Android to dark mode and the app turns dark too.

---

## 3. Signing in, sessions and signing out

### 3.1 Signing in

1. Open the app. The top of the sign-in screen shows the RMGFlow logo, the line "Bangladesh buying-house operations, in your pocket" and "Sourcing · Costing · Orders · Shipments". The form below says **Welcome back, Sign in to continue**.
2. Type your **Email** and **Password**. Tap the eye icon (**Show password** / **Hide password**) to show or hide the password.
3. **Remember my email on this device** is ticked by default. When it is ticked, next time the email is filled in for you and you only type the password. Untick it on a shared phone.
4. Tap **Sign in**.

If you leave a field empty, the app shows "Enter a valid email" (the email must contain @) or "Enter your password" under the field before it contacts the server.

If the email or password is wrong, a red box shows the reason, for example "Invalid credentials". If the server cannot be reached, you see "Could not reach the server. Check your connection." See [Troubleshooting](#9-troubleshooting-and-faq).

### 3.2 How sessions work

- After you sign in, the app keeps you signed in. When you reopen it, you go straight to Home.
- Behind the scenes, the app renews your access every 15 minutes without asking you. A sign-in stays valid for **30 days** of non-use. After that you must sign in again.
- Your sign-in key is stored in Android's secure storage. Your password is never saved on the phone.
- If a session can't be renewed (it expired, or an administrator ended it), you see **"Your session has expired. Please sign in again."** and go back to the sign-in screen. Nothing you already saved is lost.

### 3.3 Signing out

You can sign out in two places:

- **Home:** tap the **sign-out icon** (arrow through a door) at the top right. This signs you out straight away.
- **More > Profile & settings > Sign out:** the app asks "Sign out? You will need your email and password to sign in again on this device." Tap **Sign out** to confirm.

Signing out ends the session on the server too.

### 3.4 Roles and demo accounts

The demo database has one account per role. **The password for every demo account is `Demo@1234`.** These accounts are for training and testing only.

| Role | Email | What this role does in the app | Data it sees |
|---|---|---|---|
| Super Admin | `demo.admin@rmgflow.test` | Everything, including deciding every approval type and every override. | Whole organisation |
| Owner / MD | `owner@rmgflow.test` | Everything a GM can do. Sees all money and all reports. | Whole organisation |
| General Manager | `gm@rmgflow.test` | Approves costings, quotations and samples. Cancels orders, approves amendments, overrides the factory-approval and quality-gate checks, authorises partial shipments, manages financials. | Whole organisation |
| Senior Merchandiser | `sr.merch@rmgflow.test` | Runs buyers, factories, inquiries, styles, costing and quotations. Approves costings, quotations and samples. Creates orders, requests amendments, generates T&A, manages T&A templates. Sees margins and financial reports. | All 6 demo buyers |
| Junior Merchandiser | `jr.merch@rmgflow.test` | Inquiries, styles, costing (cost figures hidden), quotations (cannot mark Approved), samples, amendment requests, claims, tasks. | Buyers NVK, BWC and PCB (in reports) |
| Sampling Coordinator | `sampling@rmgflow.test` | Requests samples, submits revisions, approves sample revisions, marks T&A milestones done. | All buyers and factories |
| Production Follow-up | `production@rmgflow.test` | Enters daily production updates and marks T&A milestones done. Read-only on quality, shipments and documents. | All buyers and factories |
| Quality Inspector | `quality@rmgflow.test` | Records inspections, logs defects, creates and closes CAPA, marks T&A milestones done. | All buyers and factories |
| Commercial Executive | `commercial@rmgflow.test` | Creates shipments and updates their status, adds and approves documents, raises and resolves claims. | All buyers and factories |
| Accounts & Finance | `accounts@rmgflow.test` | Order financials, receivables, payables, recording payments. Sees all financial reports. | Whole organisation |
| Factory Coordinator | `factory.coord@rmgflow.test` | Production updates and T&A updates for their factory. Read-only on orders, quality, shipments and documents. | Factory KNT-GZP (Gazipur Knit) |
| Management Viewer | `viewer@rmgflow.test` | Read-only across the business, plus 12 of the 15 reports. Cannot change anything. | Whole organisation |

> **Note:** "Data it sees" is applied in full to **reports**. In the regular module screens, every role currently sees the whole organisation's records for the modules it is allowed to open. See [Known limitations](#94-known-limitations).

To see your own roles, open **More > Profile & settings > Roles**.

---

## 4. The Home screen and how to get around

### 4.1 What is on Home

From top to bottom:

1. **Header**
   - A greeting ("Good morning", "Good afternoon" or "Good evening") and the app name.
   - Top-right icons: **Notifications** (bell), **More** (grid) and **Sign out**.
   - Two buttons: **My Day** and **Reports**.
2. **Needs attention today.** Four tiles fed by My Day. Tap any tile to open the related screen.
   - **Items need attention:** the total of the three numbers below. It shows "All clear today" when the total is zero.
   - **Pending approvals:** approvals waiting for a decision. Opens the Approvals inbox.
   - **Overdue T&A milestones:** milestones you are responsible for that are past due. Opens My Day.
   - **My overdue tasks:** opens My Tasks.
3. **Reports & Analytics banner:** "Business reports with CSV/PDF download". Opens the Reports hub.
4. **Module groups:** tiles grouped by area. You only see the tiles your role can open.

| Group | Tiles | What happens when you tap |
|---|---|---|
| **Sourcing & Development** | Buyers, Factories, Inquiries, Styles, Sampling | Opens the list straight away |
| **Commercial Pricing** | Costing, Quotations, Approvals (with a red count badge) | Opens the list straight away |
| **Order Execution** | Orders ("All orders") | Opens the order list |
| | T&A, Production, Quality, Shipment, Documents ("Pick order") | Asks you to **choose an order** first, then opens that module for the order |
| | Financial ("All orders"), Claims ("Register") | Opens the organisation-wide screen |
| **My Work** | Tasks (badge = your overdue tasks), Notifications, Reports, More ("Ledgers, setup") | Opens the screen |

Each group heading has a one-line hint under it: "Buyers, vendors, inquiries and styles", "Cost sheets, quotations and sign-off", "Tap a module, pick the order, and you are there" and "Tasks, alerts and analytics". A group whose tiles your role can't open is hidden completely.

**Pull down** on Home to refresh the numbers.

### 4.2 The order picker

When you tap an order-based tile (T&A, Production, Quality, Shipment or Documents), a sheet slides up titled, for example, *"Quality: choose an order"*.

- Type in **Search order no. or buyer PO** to narrow the list. For example, type `77810` to find PO-BWC-77810.
- Each row shows the order number, buyer PO, ex-factory date and status.
- Tap an order to open the module for it.
- If nothing matches, the sheet says "No matching orders." If the list can't load, tap **Could not load orders. Try again**.

The T&A tile needs an order with an ex-factory date and at least one item. Otherwise you see "T&A needs an ex-factory date and at least one item on …".

### 4.3 Navigation map

```
Sign in
 └─ Home
     ├─ Bell -> Notifications
     ├─ Grid -> More
     │    ├─ Receivables / Payables (Finance ledgers)
     │    ├─ Claims register
     │    ├─ T&A templates
     │    ├─ Reference data (seasons, currencies, countries, incoterms,
     │    │                  payment terms, document types, defect types, milestone types)
     │    └─ Profile & settings (roles, server, sign out)
     ├─ My Day  (late milestones, pending approvals, late tasks, quick link to More)
     ├─ Reports -> Report -> Filters / Results / Download CSV / Download PDF
     ├─ Buyers -> Buyer (edit) -> Contacts, Tasks, Activity
     ├─ Factories -> Factory (edit) -> Contacts | Capabilities | Certifications | Buyer approvals, Tasks, Activity
     ├─ Inquiries -> Inquiry -> Status, Factory candidates, Tasks, Activity
     ├─ Styles -> Style -> Spec revisions, Compare, New costing, Tasks, Activity
     ├─ Sampling -> Sample -> Revisions, Approval history
     ├─ Costing -> Costing -> Submit / Edit draft / New version / Approval history
     ├─ Quotations -> Quotation -> Status, New version, Approval history
     ├─ Approvals -> Approval decision (Approve / Return / Reject)
     ├─ Orders -> Order hub
     │     ├─ T&A calendar  ├─ Production  ├─ Inspections -> Defects -> CAPA
     │     ├─ Shipments -> Shipment -> Shipment documents
     │     ├─ Documents     ├─ Amendments  ├─ Financials  ├─ Claims
     │     └─ Tasks         └─ Activity
     ├─ Financial -> Receivables | Payables
     ├─ Claims -> All claims
     └─ Tasks -> My Tasks
```

### 4.4 Gestures and patterns used everywhere

| You see | What to do |
|---|---|
| A round **+** button at the bottom right (for example "Add buyer") | Tap it to create a new record. |
| A **search box** | Type to filter. Most lists filter as you type. |
| **Chips** under the search box (for example "All statuses", "Open", "Won") | Tap one to filter the list by that value. Tap **All …** to clear. |
| A **coloured status chip** on a row with a small arrow | Tap the chip to change status straight from the list. |
| **Swipe a row right** | The quick "positive" action: Approve, Done, Mark read, Receive or Pay. A green label shows what it will do. |
| **Swipe a row left** | The quick "negative" action, for example Reject. |
| **Long-press a row** | Opens a menu of every action for that row. |
| **Pull down** on a list | Refreshes it from the server. |
| A newly created record **tinted** in the list | This is the record you just added. |
| A **confirmation** box | Any change that can't be undone (approvals, payments, cancelling, closing) asks first. |
| A green bar at the bottom | Your change was saved. |
| A red bar at the bottom | The server refused. The message says why. |
| **Copy** icon next to a value | Copies it (for example an order number, B/L number or email). |

Empty screens always tell you what goes there and offer a button to add the first record. If a screen fails to load, it shows a short title and the server's message, and a **Try again** button. The title tells you the kind of problem:

| Title | Meaning |
|---|---|
| **Session expired** | Sign in again. |
| **No access** | Your role can't open this. |
| **Check the details** | A value you entered was refused. |
| **Record changed** | Someone else saved it first. Go back and reopen it. |
| **Server problem** | The server had an error. Try again later. |
| **Could not load** | Anything else, including no network. |

Pickers that load a list from the server (buyer, style, factory and so on) say "Could not load the list." if the list fails, and "No match for "…"" if your search finds nothing. The **×** in a search box (**Clear search**) empties it.

**Saving a form:** required fields show an error under the field if left empty. Dates open a calendar picker. Fields with a list (buyer, style, factory, currency, incoterm) open a searchable picker.

**Optimistic locking:** if two people edit the same buyer or factory at once, the second person to save sees "This record changed elsewhere. Refresh and try again." Go back, reopen the record and make your change again.

---

## 5. Modules, in business order

Each module below covers: what it is for, how to open it, the fields, the actions, the statuses, the rules you may hit, who can use it, and a **Try it** exercise using the demo data.

**Permissions key:**

- **View** means the role can open the screen.
- **Change** means the role can create or update records.
- When a role cannot do something, the button may still be visible, but the server refuses with "You don't have permission to do that."

### 5.1 Buyers

**Purpose:** the brands and retailers you source for. Every inquiry, style, order and receivable belongs to a buyer.

**Open it:** Home > **Buyers**.

**List screen ("Buyers")**

- Search box: **Search buyers by name or code**. The search runs on the server.
- Each row shows the buyer's initials, name, code, country, currency and an **Active** or **Inactive** chip.
- **Tap** a row to open the buyer.
- **Long-press** a row for **Edit buyer** and **Contacts**.
- **Add buyer** (+) opens a new buyer form.

**Buyer form (New Buyer / Edit Buyer)**

| Section | Field | Meaning |
|---|---|---|
| Identity | **Buyer code** (required) | A short unique code, for example `HM` or `NVK-SE`. Typed in capitals. |
| | **Buyer name** (required) | The full trading name. |
| | **Group** (optional) | The parent group, if any. |
| Trade defaults | **Country** | Two-letter ISO code (SE, US, DE…). Pick from the list. |
| | **Default currency** | Defaults to USD. Pre-filled on new inquiries, quotations and orders. |
| | **Default Incoterm** | Defaults to FOB. |

When you edit an existing buyer, the top of the screen also shows:

- A header with the code, an Active or Inactive chip, the currency and the Incoterm.
- **Contacts:** opens the buyer's contact people. You can also reach it from the contacts icon in the title bar.
- **Tasks** and **Activity & notes** for this buyer.

**Buttons:**

- **Create buyer** or **Save changes**.
- **Deactivate buyer** (red), which asks "Deactivate buyer?" first. A deactivated buyer no longer appears in pickers for new inquiries and orders. Existing records are kept.

**Contacts screen.** This shows the people at the buyer.

- **Add contact** asks for **Name** (required), **Department**, **Email**, **Phone** and a **Primary contact** switch. Tap **Save contact**.
- The primary contact shows a **Primary** chip.
- Tap the copy icon to copy an email or phone number.

**Who:**

- **View:** every role except Factory Coordinator.
- **Change:** Super Admin, Owner, GM and Senior Merchandiser. The Junior Merchandiser has "own buyer" edit rights.

**Try it.** Sign in as `sr.merch@rmgflow.test`, then:

1. Open **Buyers** and search `nordvik`.
2. Open **Nordvik Apparel AB (NVK-SE)**. Its trade defaults are EUR and FOB.
3. Tap **Contacts** to see its two contacts.
4. Go back and open **Activity & notes** to read the quarterly review meeting note.
5. Long-press **Pacific Coast Basics Inc. (PCB-CA)** > **Contacts**.

### 5.2 Factories and vendors

**Purpose:** everyone you place work with: garment factories and also fabric and trim suppliers, washing, printing and embroidery units, testing labs, inspection agencies and freight forwarders. Each factory also holds its compliance data, including the per-buyer approvals that control which orders you may place there.

**Open it:** Home > **Factories**. The screen is titled "Factories & Vendors".

**List screen**

- Search **name, code or country**.
- Filter chips by partner type: **All types**, Garment Factory, Fabric Supplier, Trim Supplier, Washing, Printing, Embroidery, Testing Lab, Inspection Agency, Freight Forwarder, Other.
- Each row shows the code, the type, the capacity in pcs/month and an Active chip.
- **Long-press** a row for **Edit factory**, **Contacts**, **Capabilities**, **Certifications** and **Buyer approvals**.
- **Add factory** (+). After you create a factory, its profile opens straight away so you can add contacts and approvals.

**Factory form**

| Section | Field | Meaning |
|---|---|---|
| Identity | **Partner type** | One of the 10 types above. |
| | **Factory code** (required) | For example `KNT-GZP`. |
| | **Name** (required) | |
| | **Legal entity name** | Optional. |
| Location & capacity | **Address** | Optional. |
| | **Country code** | Two letters. Defaults to `BD`. |
| | **Capacity per month** | Pieces per month. Optional. |

Buttons: **Create factory** or **Save changes**, and **Deactivate factory**. Deactivating asks "Deactivate factory?" first. A deactivated factory is no longer offered on new orders; existing orders are kept.

When you edit an existing factory, the top of the screen shows the partner type and code, an Active or Inactive chip, **Capacity (pcs/month)** and **Country**, plus **Tasks** and **Activity & notes** for the factory.

**Factory profile.** Tap **Contacts, capabilities & compliance** (or the title-bar icon "Contacts, capabilities & approvals"). The profile has four tabs:

| Tab | What you record | Add button |
|---|---|---|
| **Contacts** | Name, **Role** (for example Merchandiser or QA Head), email, phone and a Primary switch. | Add contact (then **Save contact**) |
| **Capabilities** | The product categories the factory can make, for example *Knit tops*. Merchandisers use this to shortlist factories. | Add capability: type the **Product category** and tap **Add** |
| **Certifications** | **Certificate name** (BSCI, WRAP, OEKO-TEX, GOTS…), **Issued date** (optional) and **Expiry date** (optional; must be after the issued date). Each certificate shows **Valid** or **Expired**, or "No expiry date". | Add certification (then **Save certification**) |
| **Buyer approvals** | For each buyer: **Buyer**, **Status** (Pending, Approved, Rejected or Expired; a new entry defaults to Approved), **Approved date** (defaults to today) and **Valid until**. Tap a row ("Tap to update") to change it in the **Update buyer approval** sheet. Setting **Rejected** asks "Mark as rejected?" with **Mark rejected**, because it blocks new orders for that buyer at this factory. | Set approval (sheet **Set buyer approval**, then **Save**) |

> **Business rule: factory approval gate.** You can only place an order for a buyer at a factory whose buyer approval is **Approved**. Otherwise the order is refused with: *"Factory X is not approved for buyer Y; override requires ORDER_FACTORY_OVERRIDE permission and a reason"*. Only Super Admin, Owner and GM can override, and they must give a reason.

**Who:**

- **View:** all roles.
- **Change:** Super Admin, Owner, GM and Senior Merchandiser.
- **Set buyer approvals:** roles with the factory-approval permission (Super Admin, Owner, GM).

**Try it.** Sign in as `sr.merch@rmgflow.test`, then:

1. Filter **Garment Factory**. You see six factories (Gazipur, Narayanganj, Savar, Chattogram Denim, Ashulia, Karnaphuli).
2. Long-press **Ashulia Fashion Knitwear Ltd (KNT-ASH)** > **Buyer approvals**. You see:
   - Kestrel **Approved**
   - Pacific Coast **Pending**
   - Nordvik **Rejected**
3. Open **Savar Sweaters Ltd (SWT-SVR)** > **Certifications**. *WRAP Platinum* shows **Expired**.
4. Open **Gazipur Knit Composite Ltd (KNT-GZP)** > **Certifications**. *BSCI Audit (Grade B)* expires on 27 Oct 2026.
5. Open **Chattogram Denim Mills Ltd (DNM-CTG)** > **Buyer approvals**. Pacific Coast is **Expired**.

### 5.3 Inquiries

**Purpose:** log every request a buyer sends (a price request, a new program) and follow it until it is won, lost or put on hold. Inquiries feed the **Inquiry Pipeline** report and its win rate.

**Open it:** Home > **Inquiries**.

**List screen**

- Search **inquiry no. or buyer**.
- Filter chips by status (the filter runs on the server).
- Each row shows the inquiry number, buyer, target quantity, target price and a status chip.
- **Tap the status chip** to move the inquiry to a new status.
- **Long-press** a row for **Open inquiry**, **Factory candidates** and **Mark …** for each status.
- **New inquiry** (+). The new inquiry opens straight away.

**Inquiry form**

| Field | Meaning |
|---|---|
| **Inquiry number** (required) | Pre-filled with `INQ-<year>-`. Add the running number after the prefix, for example `INQ-2026-014`. Must be unique. |
| **Buyer** (required) | Pick from active buyers. |
| **Target quantity** | Pieces the buyer wants. |
| **Target price** | The buyer's target price per piece. |
| **Currency** | Defaults to USD. |
| **Delivery requirement** | Free text, for example "Ex-factory by mid-March, sea freight". |

Tap **Create inquiry** to save a new one.

On an existing inquiry (tap a row), the same form opens for editing. Change the fields and tap **Save changes**. The screen also shows:

- A header with **Target pcs** and **Target price**.
- A **Status** card with a **Mark …** button for each other status.
- The **Lost reason**, if the inquiry was lost.
- **Factory candidates** (also the title-bar icon), **Tasks** and **Activity & notes**.

**Changing status.** Tapping the status chip opens a sheet "Move INQ-… to…" that lists every other status with a short hint (for example "A quotation has been sent to the buyer"). The app then asks "Change status to …?" and you tap **Change status**. Choosing **Lost** instead opens **Mark inquiry as lost**, where **Reason for loss** is required; tap **Mark lost**.

**Statuses**

| Status | Meaning | Can move to |
|---|---|---|
| **Open** | Still being worked on. | Quoted, Lost, Hold |
| **Quoted** | A quotation has been sent to the buyer. | Won, Lost, Hold |
| **Hold** | Paused by the buyer. | Open, Quoted, Lost |
| **Won** | The buyer confirmed. Ready for an order. | final |
| **Lost** | The buyer went elsewhere. **A reason is required.** | final |

The app lists every status as an option. If you pick a move that isn't allowed (for example Open to Won), the server refuses with "Cannot transition inquiry from OPEN to WON". Go via **Quoted** first.

**Factory candidates.** This is the shortlist of factories you asked to quote.

- The screen is titled "INQ-… · Factories". Each row shows the factory and a status chip: **Candidate** ("On the shortlist"), **Selected** or **Rejected**. Selecting or rejecting asks first ("Select …?" / "Reject …?").
- **Shortlist factory** opens **Shortlist a factory**: pick the **Factory** and tap **Add to shortlist**. Only active factories are offered. The same factory can't be added twice ("This factory is already on the shortlist.").
- **Swipe right** to **Select** a factory. **Swipe left** to **Reject** it. You can also tap the status chip and choose **Select factory**, **Reject** or **Back to shortlist**.

**Who:**

- **View:** Super Admin, Owner, GM, Senior Merchandiser and Junior Merchandiser.
- **Change:** the same roles.
- Management Viewer sees inquiries only through the Inquiry Pipeline report.

**Try it.** Sign in as `jr.merch@rmgflow.test`, then:

1. Tap the **Lost** chip. Open **INQ-DEMO-105** (Thames & Rowe). Its lost reason reads "Price — buyer target FOB $6.10 vs our best $6.85".
2. Open **INQ-DEMO-101** (Nordvik, Open, 30,000 pcs at 2.40) > **Factory candidates**. Two factories are shortlisted. Swipe right on **Gazipur Knit** to select it.
3. Open **INQ-DEMO-108** (Kestrel, Open) and tap **Mark quoted**.
4. Then try **Mark won**. It works, because the inquiry is now Quoted.

### 5.4 Styles

**Purpose:** a style is one garment design for one buyer. Its technical details (fabric, composition, GSM, colours, sizes, measurements) are kept as **spec revisions**. A revision is never edited. Each change becomes a new revision, so you always know what was agreed when.

**Open it:** Home > **Styles**.

**List screen**

- Search **style number or description**.
- Each row shows the style number, the buyer's style number, gender and product category.
- A style with no spec yet shows a **No spec yet** chip.
- **Add style** (+). The new style opens so you can add its first spec.

**New Style form**

| Field | Meaning |
|---|---|
| **Style number** (required) | Your internal number, for example `ST-2026-001`. |
| **Buyer** (required) | |
| **Buyer's style number** | The buyer's own reference. Optional. |
| **Product category** | For example Knit top, Denim bottom or Outerwear. Optional. |
| **Gender** | Men, Women, Unisex, Boys, Girls, Kids or Infant. Optional. |
| **Description** | Optional. |

Tap **Create style**. The style's own fields can't be edited afterwards; spec changes go in revisions.

**Style detail**

- **Header:** current spec (for example **R2**), number of revisions and gender.
- **Overview:** buyer, buyer's style no. (tap to copy), product category, gender and description.
- **New costing:** builds a cost sheet for this style without choosing the style again. The title-bar calculator icon does the same.
- **Tasks** and **Activity & notes**.
- **Spec revisions,** newest first. The latest one is marked **Current**. Tap a revision to expand it: Fabric, Composition, GSM, Colour, Size range and Measurements.
- **Add spec** or **New revision** (+). The form is pre-filled from the latest revision, so you only change what is different. You must fill at least one field. Then tap **Save revision**.

  | Field | Example |
  |---|---|
  | **Fabric** | Single jersey |
  | **Composition** | 95% cotton, 5% elastane |
  | **GSM** | 180 (g/m²) |
  | **Colour(s)** | Navy, Heather grey |
  | **Size range** | S–XXL |
  | **Measurements** | Chest 52 cm, body length 70 cm… |

- **Compare revisions** (title-bar icon, shown when there are two or more revisions). The screen "<style no.> · Compare" has two revision pickers. Fields that differ are highlighted **Changed**.

**Who:**

- **View:** all roles.
- **Change:** Super Admin, Owner, GM, Senior Merchandiser and Junior Merchandiser.

**Try it.** Sign in as `sr.merch@rmgflow.test`:

1. Open **NVK-SS26-TS101** (Nordvik men's T-shirt, buyer no. NV-24871).
2. Tap the compare icon and compare its revisions.
3. Tap **New revision**, change the GSM and save. The header now shows the new revision number.

### 5.5 Costing

**Purpose:** build the cost sheet for a style, line by line, and get it approved. The **server** calculates the total cost and margin. The app never does this maths, so everyone sees the same number.

**Open it:** Home > **Costing** (the screen is called "Costings"), or **Style > New costing**.

**List screen**

- Search by style. Filter by **Draft**, **Approved** or **Superseded**.
- Each row shows the version (**v1**, **v2**…), the style, the total cost × pieces, the **Margin %** and the status.

**Costing form (New Costing / Edit Costing Draft / Revise Costing)**

| Section | Field | Meaning |
|---|---|---|
| What is being costed | **Style** (required) | |
| | **Inquiry** | Optional. Links the buyer inquiry this costing answers. |
| Commercials | **Currency** | Defaults to USD. |
| | **Exchange rate** (required) | Rate to the base currency. |
| | **Quantity** (required) | Pieces. |
| | **Target price** | The buyer's target per piece. Optional. Used for the margin. |
| Cost items | **Component** | Fabric, Knitting, Dyeing, Finishing, Trims, CM, Washing, Printing, Embroidery, Testing, Inspection, Packaging, Freight, Commission, Bank Charge, Wastage, Overhead, Other. |
| | **Description** | Optional. |
| | **Unit cost** | Can be zero. |
| | **Consumption** | Quantity used per garment. |
| | **Wastage %** | |

- **Add item** or **Add another cost item** adds a line. The new line defaults to the next component not yet on the sheet (fabric, then knitting, then dyeing…).
- The bin icon removes a line. It asks first if the line has data.
- The note "Totals and margin are calculated by the server when you save" is a reminder that the app does not calculate them.
- The save button is **Create costing** (new), **Save changes** (editing a draft) or **Create new version** (revising).

**Costing detail**

- **Header:** version, status, **Total cost**, **Margin %** and pieces.
- **Summary:** style, inquiry, quantity, exchange rate, target price, total cost and margin.
- **Cost items:** each line shows unit × consumption + wastage %.
- **Buttons, depending on status:**
  - **Draft:** **Submit for approval** (asks "Submit for approval?"; tap **Submit**. You cannot edit while it is under review) and **Edit draft**.
  - **Approved or Superseded:** **Create new version**. This copies the sheet into a new **Draft** version. Once you save it, the new version opens.
  - Always: **Approval history**, which lists every approval round for this costing.

**Statuses**

| Status | Meaning |
|---|---|
| **Draft** | Being worked on, or waiting for approval. A submitted costing still shows Draft; check **Approval history** to see if it is under review. |
| **Approved** | Signed off. **Locked forever.** Quotations can only be made from approved costings. |
| **Superseded** | Replaced by a newer version before it was approved. |

**Business rules you will meet**

- **Costing versions can't be changed once approved.** To change the numbers, use **Create new version**. The approved version stays as it was, for the record.
- Only a **Draft** can be edited or submitted. Otherwise the server says "Only a DRAFT costing can be edited; create a new version instead".
- A costing becomes **Approved** automatically when an approver approves its approval round (see [Approvals](#57-approvals)). If it is **Returned** or **Rejected**, it stays Draft. Fix it and submit again, which starts a new round.
- **10% margin floor:** costings with a margin under 10% are flagged **Below floor** in the Costing Margin report.
- **Hidden figures:** roles without margin permission (Junior Merchandiser, Management Viewer) see unit costs, totals and margin as **hidden**, with the note "Cost and margin figures are hidden for your role."

**Who:**

- **View:** every role except Sampling, Production, Quality, Commercial and Factory Coordinator.
- **Create and submit:** Super Admin, Owner, GM, Senior Merchandiser and Junior Merchandiser.
- **Approve:** Super Admin, Owner, GM and Senior Merchandiser.
- **See cost figures:** Super Admin, Owner, GM, Senior Merchandiser and Accounts.

**Try it.** Sign in as `sr.merch@rmgflow.test`:

1. Search `TS101`. You see **v1 Superseded** (14.1%) and **v2 Approved** (21.4%) for the Nordvik T-shirt.
2. Open v2 and look at the cost items.
3. Open the **PCB-SS26-PJ900** costings. v1 was approved at **-2.8%**, below the floor. v2 is a draft at -12.5%.
4. Open **BWC-AW26-DJ120 v2 (Draft)** > **Approval history**. Round 1 is **Submitted** and waiting.
5. Now sign in as `jr.merch@rmgflow.test` and open the same costing. The figures say **hidden**.

### 5.6 Quotations

**Purpose:** turn an **approved costing** into a price offer to the buyer, then record the buyer's answer. A price change creates a **new version** of the quotation and keeps the old one.

**Open it:** Home > **Quotations**.

**List screen**

- Search **quotation no., buyer or style**. Filter by status.
- Each row shows the version, the quotation number, buyer · style, and unit price × pieces = total.
- **Tap the status chip** to change status. Rejected and Expired ask you to confirm. Superseded quotations can't change.
- **Long-press** a row for **Open quotation** and **Mark …**.

**Quotation form (New Quotation / Revise Quotation)**

| Section | Field | Meaning |
|---|---|---|
| Source | **Approved costing** (required) | Only approved costings are listed. Picking one fills style, buyer, quantity and currency, and the unit price if a target price exists. |
| | **Quotation no.** | Optional, for example `QT-2026-001`. Must be unique. If left empty, the system makes one. |
| | **Buyer**, **Style** | Filled from the costing. You can change them. |
| Price | **Quantity**, **Unit price** (required), **Currency**, **Incoterm** (defaults to FOB) | |
| Terms | **Lead time** (days), **Valid until** | |

Tap **Create quotation** (or **Create new version** when revising).

**Quotation detail**

- **Header:** version, status, **Total value**, **Unit price** and pieces.
- **Status:** a button for each allowed move.
- **Offer:** quotation no., buyer, style, costing, quantity, unit price and total value.
- **Terms:** Incoterm, lead time and valid until.
- Buttons: **Create new version** (also the title-bar icon) and **Approval history**.

**Statuses and allowed moves**

| From | Can move to |
|---|---|
| **Draft** or **Negotiating** | Sent, Negotiating, Approved*, Rejected, Expired |
| **Sent** (price frozen, waiting for the buyer) | Negotiating, Approved*, Rejected, Expired |
| **Approved**, **Rejected** or **Expired** | Expired only |
| **Superseded** | none (a newer version replaced it) |

\* **Approved** is only offered to approver roles: Super Admin, Owner, GM and Senior Merchandiser. A Junior Merchandiser who tries gets "Missing permission QUOTATION_APPROVE".

**Rules**

- A quotation **must** come from an approved costing. Otherwise: "A quotation can only be created from an APPROVED costing".
- **Create new version** makes version N+1 with the same quotation number. The old version becomes **Superseded**, unless it was Approved, in which case it stays Approved.
- An approved quotation can't be edited.

**Who:**

- **View:** every role except Sampling, Production, Quality, Commercial and Factory Coordinator.
- **Change:** Super Admin, Owner, GM, Senior Merchandiser and Junior Merchandiser.
- **Approve:** Super Admin, Owner, GM and Senior Merchandiser.

**Try it.** Sign in as `sr.merch@rmgflow.test`:

1. Open **QTN-DEMO-002**. There are two rows: v1 Superseded at USD 6.95, and v2 **Negotiating** at USD 6.80.
2. Open **QTN-DEMO-008** (Kestrel fleece, **Sent**). Tap **Mark negotiating**.
3. Open **QTN-DEMO-007** (Draft). Tap **Create new version**, lower the unit price and save.
4. Tap **New quotation**, pick the approved costing **KST-AW26-HD330 v1** and watch the form fill itself.

### 5.7 Approvals

**Purpose:** one inbox for everything waiting for a sign-off: costings, quotations and sample revisions. Every decision is permanent and kept in the approval history. A record can go through several **rounds** (submit, decide, resubmit…).

**Open it:** Home > **Approvals** (the red badge shows the count), the **Pending approvals** tile, or **My Day > Pending approvals**.

**Inbox ("Pending Approvals (n)")**

- Filter chips by type: **All types**, Costing, Quotation, Sample Revision, Lab Dip, Trim, PP Sample, Inspection, Shipment, Document.
- Each row shows the record (for example "Quotation QTN-DEMO-002"), type · round, submitted date and status.
- **Swipe right** to approve. It asks "Approve …? Approvals are final and cannot be changed afterwards."
- **Swipe left** to reject. It asks for a **Rejection reason**, which is required.
- **Long-press** a row for **Approve**, **Return for changes** (asks "Return … for changes?" with an optional **What needs changing** note), **Reject**, **Review costing** (costings only) and **Open decision screen**.
- **Tap** a row to open the full decision screen.
- When the inbox is empty it says "All caught up".

**Decision screen**

- Titled "<Type> Approval", for example "Costing Approval".
- **Header:** the record, **Round**, **Type** and submitted date.
- **Comments** from the submitter, if any.
- **Review costing details** ("Open the record before deciding"): opens the costing before you decide (costings only).
- **Your decision:** **Comments (optional)** and **Rejection reason** ("Only needed if you reject — you will be asked if blank"). Then tap **Approve**, **Return** or **Reject**. Each asks you to confirm; a successful decision shows "Decision recorded".

**What each decision does**

| Decision | Effect |
|---|---|
| **Approve** | The record is approved. A costing becomes Approved, a quotation becomes Approved, and a sample revision is approved (refresh the sample to update its status). |
| **Return** | Sent back for changes. The submitter fixes it and resubmits. |
| **Reject** | Refused, with a reason. The submitter must start a **new round**. |

**Approval history** (from a costing, quotation or sample) lists every round. Each round shows "R1", "R2"…, the record and round number, its status chip, the rejection reason, comments, and the submitted and decided dates. If the record was never submitted, it says "No approval rounds yet".

**Approval round statuses**

| Status | Meaning |
|---|---|
| **Submitted** / **Pending** | Waiting for a decision. |
| **Resubmitted** | Sent again after changes. Waiting for a decision. |
| **Approved** | Approved. Final. |
| **Returned** | Sent back for changes. |
| **Rejected** | Refused, with a reason. |
| **Withdrawn** | Pulled back by the submitter. |

**Who can decide:**

| Type | Roles that can decide |
|---|---|
| Costing | Super Admin, Owner, GM, Senior Merchandiser |
| Quotation | Super Admin, Owner, GM, Senior Merchandiser |
| Sample revision | Super Admin, Owner, GM, Senior Merchandiser, Sampling Coordinator |
| Lab Dip, Trim, PP Sample, Inspection, Shipment, Document | Super Admin only (not yet opened to other roles) |

> Every role can currently **see** the inbox. A role that can't decide an item gets "Missing permission … to decide this approval" when it tries.

**Try it.** Sign in as `gm@rmgflow.test`:

1. Open **Approvals**. There are six waiting items:
   - Costing **BWC-AW26-DJ120 v2** and Costing **MLM-SS27-BL077 v1**
   - Quotation **QTN-DEMO-002 v2**
   - Three sample revisions (for SMP-26-0003, SMP-26-0008 and SMP-26-0010)
2. Long-press the MLM costing > **Review costing**, then go back and swipe right to approve. In **Costing**, it now shows **Approved**.
3. Swipe left on the BWC costing and enter a reason. Its history now shows a **Rejected** round.

### 5.8 Sampling

**Purpose:** request samples from factories (development, proto, fit, size set, PP, TOP, shipment samples) and track the buyer's approval of each **revision**. Revisions are never edited. A rejected or returned sample gets a new revision and a fresh approval round.

**Open it:** Home > **Sampling** (the screen is called "Samples").

**List screen**

- Search **sample no., style or buyer**. Filter by status.
- Each row shows the sample number, style · buyer, requested date and due date.
- **Request sample** (+). The new sample opens.

**Request Sample form**

| Field | Meaning |
|---|---|
| **Buyer** (required) | Pick it first. It narrows the style list. |
| **Style** (required) | |
| **Sample type** (required) | Development Sample, Proto Sample, Fit Sample, Size Set, PP Sample, TOP Sample, Shipment Sample, plus any buyer-specific types. |
| **Factory** | Who will make the sample. |
| **Request date** (required) | |
| **Required by** | When the buyer needs it. |

Tap **Request sample** at the bottom of the form to save it.

**Sample detail**

- **Header:** sample type, sample number, style · buyer, number of revisions, requested date and required-by date.
- **Details** card.
- **Revisions,** newest first. The newest is marked **Latest**.
- **New revision** (+) or **Submit first revision** opens **Submit new revision** with an optional **Comments** box. Tap **Submit revision**. This records that a sample was sent to the buyer today and starts a fresh approval round.
- **Latest revision approval history**.
- **Refresh status from latest approval** (also the title-bar icon). Use this after an approver decides, to update the sample's status. If the latest round isn't decided yet, you see "Latest approval round is not yet decided".

**Statuses** (worked out from the latest revision):

| Status | Meaning |
|---|---|
| **Requested** | Asked for, nothing sent yet. |
| **Submitted** | A revision was sent and is waiting for a decision. |
| **Approved** | The buyer approved the latest revision. |
| **Returned** | Sent back for changes. Submit a new revision. |
| **Rejected** | Rejected. Submit a new revision. |

**Who:**

- **View:** all roles.
- **Request and submit:** Super Admin, Owner, GM, Senior Merchandiser, Junior Merchandiser and Sampling Coordinator.
- **Approve revisions:** Super Admin, Owner, GM, Senior Merchandiser and Sampling Coordinator.

**Try it.** Sign in as `sampling@rmgflow.test`:

1. Filter **Returned** and open **SMP-26-0004** (Size Set for the Brightwater shirt). Tap **New revision**, type "Corrected collar spec" and submit.
2. Go to **Approvals**. The new round is in the inbox. Approve it.
3. Back on the sample, tap **Refresh status from latest approval**. It shows **Approved**.
4. Also open **SMP-26-0008** (blouse fit sample). It has two revisions: rejected, then resubmitted.

### 5.9 Orders and amendments

**Purpose:** the buyer's purchase order, broken into lines (style, factory, colour, size, quantity, price). The **order detail is the hub** for everything that happens next.

**Open it:** Home > **Orders**, or from a notification, task or My Day row about an order.

**List screen**

- Search **order no., PO or buyer**. Filter by status.
- Each row shows the order number, buyer · PO, ex-factory date and status.
- Open orders also show a coloured countdown to ex-factory such as "in 12 d", "today" or "3 d late": green if more than 14 days away, orange within 14 days, red when late.
- **New order** (+).

**New Order form**

| Section | Field | Meaning |
|---|---|---|
| Order details | **Buyer PO number** (required) | As printed on the buyer's PO. |
| | **Buyer** (required) | |
| | **Quotation** | The accepted quotation, if any. Pick the buyer first. |
| | **Order date** | |
| | **Ex-factory date** | **Needed to generate the T&A calendar.** |
| | **Delivery date** | Can't be before ex-factory. |
| | **Currency**, **Incoterm** (optional), **Destination** (2-letter country, for example US) | |
| Order lines (one or more) | **Style** (required), **Factory** (required), **Color**, **Size**, **Quantity** (required), **Unit price** (required) | Add more with **Add line**. Remove with the bin icon. |
| | **Estimated order value** | Shown live as you type. |
| Override | **Override factory approval check** + **Override reason** | Only for users allowed to place orders at a factory not yet approved by this buyer. |

Removing a line asks "Remove item n?" first.

Tap **Create order**. The **Create this order?** box shows the PO, number of lines, pieces and value, with the warning *"Once confirmed, changes need an amendment."* Tap **Create order** again to confirm. The system gives it an order number.

**Order hub (order detail)**

- **Header:** "PO …", the order number, the buyer, the status, **Pieces**, **Order value** and **To ex-factory** (for example "12 d" or "3 d late"; it says "Ex-factory not set" when there is no date).
- **Follow-up tiles:**

| Tile | Opens |
|---|---|
| **T&A** ("Milestones", or "Needs ex-factory") | T&A calendar. If it says "Needs ex-factory", tapping shows "Set an ex-factory date (via amendment) to generate the T&A calendar". |
| **Production** ("Cut · sew · pack") | Production progress |
| **Quality** ("Inspections") | Inspections |
| **Shipment** ("ETD · ETA · B/L") | Shipments |
| **Documents** ("Commercial") | Order documents |
| **Amendments** ("Changes") | Amendments |
| **Financials** ("AR · AP") | Order financials |
| **Claims** ("Buyer · factory") | Claims for this order |
| **Tasks** ("To-dos") | Tasks for this order |
| **Activity** ("Calls · notes") | Activity log |

- **Order details:** order no., buyer PO, buyer, quotation, order date, ex-factory (with "in 10 d" or "3 d late"), delivery, Incoterm, destination and total value.
- **Items:** style, factory, colour, size, pieces and price per piece.
- **Cancel order** (red, not shown for Cancelled or Closed orders). It asks "Cancel order …? This cannot be undone. Open T&A tasks, production and shipments for this order will stop." and needs a **Cancellation reason**.

**Order statuses**

| Status | Meaning |
|---|---|
| **Confirmed** | Created and accepted. |
| **In Progress** | In production. |
| **Partially Shipped** | Some quantity shipped. Set automatically by a shipment. |
| **Shipped** | All quantity shipped. Set automatically. |
| **Closed** | Finished. |
| **Cancelled** | Cancelled, with a reason. |

**Amendments.** After an order is confirmed, its key fields change only through an **amendment** that someone approves. There are no silent edits.

- The **Amendments** screen lists each amendment as **#no · field**, then **old value → new value**, the reason and a status (**Requested**, **Approved** or **Rejected**).
- **Request change** opens **Request amendment**, which asks for:
  - **What needs to change?**: Ex-factory date, Delivery date, Quantity, Unit price, Color / size breakdown, Incoterm, Destination, Factory or Other. **Other** adds a **Field name** box.
  - **New value** (for example `2026-11-30` or `12,000 pcs`)
  - **Reason** (required: why is the buyer or factory asking for this?)
  - Tap **Submit request**. You see "Amendment requested — waiting for approval".
- Pending amendments have **Approve** and **Reject** buttons, or swipe. Each asks first ("Approve amendment #n?" shows the old and new values). Approving applies the new value to the order.

> **Known issue (current build):** the server can only apply changes to the **ex-factory date** and **delivery date**, and it expects their technical names. Choosing "Ex-factory date" or "Delivery date" from the list is refused with "Unsupported amendment field".
>
> **Workaround:** choose **Other**, type `exFactoryDate` or `deliveryDate` as the field name, and enter the new value as a date like `2026-11-30`. Changes to quantity, price, factory and the other fields can't be applied yet.

**Rules**

- **Factory approval gate:** see [5.2](#52-factories-and-vendors).
- You can't cancel an order that has already shipped or closed.
- A cancellation needs a reason.

**Who:**

- **View:** all roles.
- **Create:** Super Admin, Owner, GM and Senior Merchandiser.
- **Cancel:** Super Admin, Owner and GM.
- **Request amendment:** Super Admin, Owner, GM, Senior Merchandiser and Junior Merchandiser.
- **Approve amendment:** Super Admin, Owner and GM.
- **Factory-approval override:** Super Admin, Owner and GM.

**Try it.** Sign in as `gm@rmgflow.test`:

1. Open **Orders** and filter **In Progress**. Open **RMG-26-0002 (PO-BWC-77810)**, the Brightwater shirt order at Narayanganj Woven.
2. Look at every tile in the hub.
3. Open **RMG-26-0009 (PO-MLM-4502)** > **Amendments**:
   - #1: ex-factory moved 21 Nov to 28 Nov, **Approved**.
   - #2: delivery date change, **Requested**. Approve it, then check that the order's delivery date changed.
4. Open **RMG-26-0008 (PO-BWC-77954)**. It is **Cancelled**.
5. Open **RMG-26-0006 (PO-PCB-11872)**. It was placed at Ashulia while the buyer approval was still Pending, using the override. The reason is in the buyer's activity note.

### 5.10 T&A calendar and templates

**Purpose:** the **Time & Action** calendar is the order's critical path: every key date from fabric booking to ex-factory, worked back from the ex-factory date. Late milestones are flagged so you can act early.

**Open it:**

- **Order hub > T&A**, or **Home > T&A > pick an order**.
- Overdue milestones also appear in **My Day**.
- Templates are under **More > T&A templates**, or the template icon on the calendar.

**T&A Calendar**

- **Header:** "x of y done", plus **Done**, **Late** and **Due in 7 days** counts. It says "Everything on track" or "n milestones running late".
- **Timeline:** each milestone shows its sequence number, name, status, "Due …" (and "planned …" if it was rescheduled), "Done …", any **delay reason**, and badges such as **"5 d late"** or "in 3 days".
- **Done today:** one tap marks the milestone done today. An **Undo** bar appears briefly. The date is only saved when that bar closes, because an actual date can't be changed afterwards.
- **Other date:** a calendar asks *When was "<milestone>" done?*. Pick the date the milestone was actually done.
- If the date is after the due date, a **Delay reason required** box asks for the **Reason for delay**, which is required. Tap **Save**.
- **Long-press** a milestone for **Done today** and **Done on another date…**.
- **Generate from template** (title-bar icon, or **Generate calendar** on the empty screen "No T&A milestones yet") asks "Generate T&A calendar?" and creates the milestones from the T&A template, counting back from the ex-factory date. Tap **Generate**.
- You can only generate once per order. When milestones already exist, the icon asks "Regenerate T&A calendar?", but the server refuses with "T&A milestones already exist for this order".
- The second title-bar icon (**T&A templates**) opens the template list.

**Milestone statuses** (worked out by the server):

| Status | Meaning |
|---|---|
| **Pending** | More than 3 days away. |
| **Upcoming** | Due within the next 3 days. |
| **Due Today** | Due today. |
| **Overdue** | 1 to 3 days past due. |
| **Critical Delay** | More than 3 days past due. |
| **Blocked** | Due, but the milestone it depends on isn't done yet. |
| **Done** | The actual date is recorded. |

Late completions push their knock-on delay to the milestones that follow.

**T&A templates**

- The list shows each template's name, "All buyers" or "For <buyer>", and a **Default** chip.
- **New template** opens **New T&A template**: **Template name** (for example "Knit basic 90-day"), **Buyer (optional)** (leave empty to use it for any buyer) and a **Default template** switch (used when an order has no buyer-specific template). Tap **Create template**.
- Open a template to see its milestones in order. Each shows "n days before ex-factory", "On ex-factory day" or "n days after ex-factory", and "after …" when it depends on another milestone. An empty template says "No milestones".
- **Add milestone** asks for **Milestone** (from the milestone library), **Sequence** (1, 2, 3…; pre-filled with the next number) and **Days before ex-factory** (for example 60 for lab dip approval, 7 for final inspection; 0 means ex-factory day). Tap **Add milestone**.

**Standard milestone library** (with typical days before ex-factory): Order Confirmation 90, Fabric Booking 85, Lab Dip Approval 70, Strike-off Approval 65, Fabric In-House 60, Trim Approval 55, PP Meeting 40, PP Sample Approval 35, Cutting 30, Sewing 20, Finishing 10, Final Inspection 5, Packing 3, Ex-Factory 0.

**Who:**

- **View:** all roles.
- **Mark done:** every role except Accounts and Management Viewer.
- **Generate the calendar and manage templates:** Super Admin, Owner, GM and Senior Merchandiser.

**Try it.** Sign in as `production@rmgflow.test`:

1. **Home > T&A**, search `77810` and pick **RMG-26-0002**. *Final Inspection* and *Packing* are late. Their revised dates show the knock-on delay.
2. Open **RMG-26-0006** (PCB). *Fabric Booking* is a **Critical Delay**.
3. Tap **Other date** on it, pick yesterday and type a delay reason.
4. Sign in as `sr.merch@rmgflow.test` and open **More > T&A templates**. You see:
   - "Standard 90-day critical path" (**Default**)
   - "Kestrel Outdoor T&A (no strike-off)" for Kestrel

### 5.11 Production

**Purpose:** daily output from the factory floor (cutting, sewing, finishing, packing, rejects and alterations) and progress against the order quantity. The server adds up all the totals.

**Open it:** **Order hub > Production**, or **Home > Production > pick an order**.

**Production Progress**

- **Header:** **Packed %**, "x of y pcs packed", order quantity, rejected pieces and number of daily updates.
- **Stages vs order quantity:** bars for Cutting, Sewing, Finishing and Packing.
- **Quality loss:** rejected and altered pieces.
- **Daily updates:** each day's cut, sew, finish and pack figures, plus reject and alter.

**Daily update** (+ **Daily update** opens "Daily Production Update")

- **Update date**.
- **Today's output** ("Pieces completed at each stage today (not cumulative)"): Cutting, Sewing, Finishing and Packing. These are **pieces finished today**, not running totals.
- **Quality loss:** Rejection and Alteration.
- Tap **Save update**.

**Who:**

- **View:** every role except Sampling Coordinator.
- **Enter updates:** Super Admin, Owner, GM, Senior Merchandiser, Production Follow-up and Factory Coordinator.

**Try it.** Sign in as `factory.coord@rmgflow.test`:

1. **Home > Production** > **RMG-26-0001 (PO-NVK-260145)**. There are about 22 daily updates, with Fridays skipped.
2. Add today's update: Cutting 400, Sewing 380, Finishing 350, Packing 300, Rejection 5.
3. Watch the bars move.

### 5.12 Quality: inspections, defects and CAPA

**Purpose:** record inline, midline and final inspections, log the defects found, and close the loop with **CAPA** (Corrective And Preventive Action). A **passed final inspection** is what allows the goods to ship.

**Open it:** **Order hub > Quality**, or **Home > Quality > pick an order**. From there, tap an inspection to see its **Defects**, and tap a defect to see its **CAPA**.

**Inspections**

- **Header:** number of inspections, **Passed**, **Failed** and pieces checked. It says either "Final inspection passed — shipment unlocked" or "A passed final inspection unlocks shipment".
- Each row shows the type, date, result chip, pieces inspected and AQL.
- **Record inspection** (+). After you save, the defects screen for the new inspection opens.

**Record Inspection form**

| Field | Meaning |
|---|---|
| **Inspection type** | Inline, Midline or Final. |
| **Inspection date** | |
| **Inspected quantity** (required) | Pieces checked. |
| **AQL level** | For example 2.5. Optional. |
| **Result** | Pass, Fail or Reinspect. |

Tap **Save inspection**. If you save a **Final** inspection that is not Pass, the app asks "Save a fail final inspection?" (or "reinspect") and warns: *"A final inspection that is not a pass blocks shipment of this order until it is re-inspected or a permitted user overrides the quality gate."* Tap **Save inspection** to confirm.

**Defects** (per inspection)

- **Summary:** total defective pieces, number of defect types, pieces inspected, and counts by **Minor**, **Major** and **Critical**.
- The screen is titled "<type> Defects", for example "Final Defects".
- **Log defect** asks for **Defect type** (from master data; the severity is pre-filled from the type), **Quantity found** and **Severity** (Minor, Major or Critical). Tap **Log defect**.
- Tap a defect to open its CAPA.

**CAPA records** (per defect; screen "CAPA Records")

- **New CAPA** opens **New CAPA record**: **Problem description** (required, for example "Broken stitch at side seam"), **Corrective action** (optional: the fix for the current goods) and **Preventive action** (optional: how to stop it happening again). Tap **Create CAPA**.
- Each record shows when it was opened, the corrective action, preventive action and factory response.
- **Record factory response** (or **Response**) opens **Factory response**; type it and tap **Save response**. This moves the CAPA to **In Progress**.
- **Close CAPA** (or **Close**) asks "Close this CAPA?" and confirms the actions are done. **A closed CAPA can't be reopened.**
- Long-press a CAPA for both actions.
- Statuses: **Open** (just created), **In Progress** (factory has responded) and **Closed**.

**Who:**

- **View:** every role except Sampling Coordinator.
- **Record, log and CAPA:** Super Admin, Owner, GM and Quality Inspector.

**Try it.** Sign in as `quality@rmgflow.test`:

1. **Home > Quality** > **RMG-26-0002 (PO-BWC-77810)**. There are three inspections. The **Final** on 3 Oct **failed**, so shipment is blocked.
2. Open the inspections to find the defects: Open seam 14 (CAPA **Closed**), Shade variation 22 (CAPA **In Progress**), Skip stitch, Stain and Out of tolerance.
3. Open **RMG-26-0007** > Inline **Reinspect** > *Missing button* (Critical) > CAPA **Open**.
4. Tap **Record factory response**, then **Close CAPA**.
5. Back on RMG-26-0002, **Record inspection**: Final, 800 pcs, **Pass**. The header now says "shipment unlocked".

### 5.13 Shipments

**Purpose:** book and track each shipment (full or partial) against an order, with cartons, weights, ports, vessel and B/L details.

**Open it:** **Order hub > Shipment**, or **Home > Shipment > pick an order**.

**Shipments list**

- **Header:** total pieces shipped, number of shipments, **In transit**, **Delivered** and **Delayed** counts.
- Each row shows the shipment number, pieces ("(partial)" if partial), cartons, ETD, ETA and port of discharge.
- **Tap the status chip** to change status. **Delayed** asks you to confirm.
- **New shipment** (+).

**New Shipment form**

| Section | Field |
|---|---|
| Quantity | **Quantity shipped** (required), **Cartons**, **Gross wt** (kg), **Net wt** (kg), **Volume** (CBM) |
| Dates | **Shipment date**, **ETD (departure)**, **ETA (arrival)** (can't be before ETD) |
| Logistics | **Port of loading** (defaults to Chattogram), **Port of discharge**, **Shipping line**, **Container no.**, **B/L or AWB no.** |
| Override | **Override quality gate** + **Override reason**: ship without a passed final inspection. Needs override permission. |

Tap **Create shipment**. The app asks "Create shipment?" with the pieces that will be booked against the order. Tap **Create shipment** again to confirm.

**Shipment detail**

- **Header:** "Shipment" or "Partial shipment", the route (loading port → discharge port), pieces, cartons and ETA countdown.
- **Change status:** a **Mark …** button for each other status. Each asks "Mark as …?" ("SHP-… will move from Booked to In Transit").
- **Cargo:** quantity, cartons, **Gross weight**, **Net weight** (kg) and **Volume** (CBM).
- **Schedule & logistics:** shipment date, ETD, ETA, port of loading, port of discharge, shipping line, **Container** and **B/L / AWB** (both can be copied).
- **Shipment documents:** commercial invoice, packing list, B/L and so on.

**Statuses:** **Booked**, **In Transit**, **Delivered** and **Delayed**. Any status can be set from any other.

**Shipping rules you will meet**

1. **Quality gate:** you can't ship unless the order has a **passed Final inspection**. The message is *"Order has no passing FINAL inspection; override requires SHIPMENT_QUALITY_OVERRIDE permission and a reason"*. Overrides are recorded in the audit log.
2. **Never over-ship:** the total shipped can never exceed the order quantity. There is no override for this. The message is "Shipment quantity (…) exceeds the remaining order quantity (…)".
3. **Partial shipments need authorisation:** shipping less than the remaining quantity needs the partial-shipment permission (Super Admin, Owner, GM). Other users can only ship the full remaining quantity.
4. You can't ship a Cancelled or Closed order.
5. A shipment updates the order to **Partially Shipped** or **Shipped** automatically.

**Who:**

- **View:** every role except Sampling Coordinator.
- **Create and update:** Super Admin, Owner, GM and Commercial Executive.
- **Partial shipments and quality override:** Super Admin, Owner and GM.

**Try it.** Sign in as `commercial@rmgflow.test`:

1. **Home > Shipment** > **RMG-26-0002**. Tap **New shipment** and try to book 8,000 pcs. The quality gate blocks it.
2. Open **RMG-26-0004 (Kestrel denim)**. **SHP-26-0002** is a partial of 6,000 pcs, **In Transit** to Hamburg. Its documents include a **Packing List version 2**.
3. Open **RMG-26-0010**. **SHP-26-0004** is still **Booked** although its ETD has passed (Reports flag it "At risk"). Mark it **In Transit**.
4. Open **RMG-26-0012**. **SHP-26-0006** is **Delayed**.

### 5.14 Documents

**Purpose:** the commercial and compliance paperwork, such as invoices, packing lists, B/L, certificates of origin and inspection certificates. Each document has a version, an approval status and an optional expiry date, and you can open the attached file.

**Open it:**

- **Order hub > Documents**, or **Home > Documents > pick an order**, for order documents.
- **Shipment detail > Shipment documents** for shipment documents.

**Document list ("Order Documents" / "Shipment Documents")**

- **Header:** number of documents, **Approved**, **Pending** and **Expired** counts.
- Each row shows the type, version (for example "Packing List · v2"), uploaded date, "Expires …" and a status chip. An orange **"expires in n days"** pill appears within 30 days of expiry.
- **Tap a row** to download and open its file in your phone's viewer (PDF reader and so on). If no app can open it, the share sheet opens instead.
- **Swipe right** on a pending document, or use **Approve**, to approve it. It asks first: "Approve <type> v<n>? Approved documents are treated as final for this order/shipment."
- **Long-press** a row for **Open file** and **Approve**.
- **Add document** asks for:
  - **Document type** (required)
  - **File**: a file already attached to this order or shipment
  - **Expiry date**, for certificates, LCs and other documents that expire
  - Then tap **Add document**.

**Statuses:** **Draft**, **Submitted**, **Approved** and **Expired**. A document past its expiry date shows **Expired**.

> **Note:** the app can't upload new files from the phone yet. "Add document" links a file that is already attached to the record. If none is attached, you see "No files attached to this … yet".

**Who:**

- **View:** every role except Sampling Coordinator.
- **Add and approve:** Super Admin, Owner, GM and Commercial Executive.

**Try it.** Sign in as `commercial@rmgflow.test`:

1. **Home > Documents** > **RMG-26-0001**. *Inspection Certificate* v1 is **Draft**. Swipe right to approve it.
2. Open **RMG-26-0003** > *Certificate of Origin* and tap it to open the PDF.
3. From **RMG-26-0010 > Shipment > SHP-26-0004 > Shipment documents**, approve the draft invoice and packing list.

### 5.15 Financials, receivables and payables

**Purpose:** money on each order (margin estimate against realised margin), what the **buyer owes us** (receivables) and what **we owe factories** (payables), and the payments made against them. Every payment is part of the audit trail and can't be edited.

**Open it:**

- **Order hub > Financials** for one order.
- **Home > Financial**, or **More > Receivables** or **More > Payables**, for all orders.

**Order Financials**

- **Header:** **Margin** labelled "estimate" (from the quoted price) or "realized" (once the realised price is set), plus **Open receivables** and **Open payables**. If nothing is set yet, it shows "Not set: enter quoted price and actual cost to see the margin".
- **Unit economics:** quoted unit price, actual cost per unit, realized unit price and **Margin (estimate)** or **Margin (realized)**. Tap the edit icon (**Edit financials**) to change the three prices, then **Save**. Fill **Realized unit price** once the order has shipped.
- **Receivables** (money the buyer owes us): **Add** opens **New receivable**: **Buyer**, **Amount**, **Currency** (defaults to USD) and **Due date** (required). Tap **Add receivable**.
- **Payables** (money we owe the factory): **Add** opens **New payable**: **Factory**, **Amount**, **Currency** and **Due date**. Tap **Add payable**.
- Each entry shows the amount, how much is settled (with a bar), the due date and status. **Swipe**, or tap **Receive** or **Pay**, to record a payment.

**Record payment**

| Field | Meaning |
|---|---|
| **Amount** (required) | The outstanding balance is shown underneath. If you enter more than the balance, the app warns you. |
| **Payment date** | |
| **Method** | Bank transfer (TT), LC, Cheque, Cash or Other. |
| **Reference no.** | Bank ref, LC no. or cheque no. |

Tap **Record payment**, then confirm "Record USD 1000.00?" with **Record payment**. If the amount is more than the balance, the box starts with "This is MORE than the outstanding …". Payments **can't be edited** afterwards.

**Receivables & Payables (all orders)**

- Two tabs: **Receivables** and **Payables**. **More > Payables** opens on the Payables tab.
- **Totals:** **To collect** or **To pay** per currency, and the **Overdue** count.
- Filter chips: **Open**, **Overdue** and **Settled**. Search **buyer or order** (Receivables) or **factory or order** (Payables).
- Each row shows the party and amount, the order, the due date, and how much is received or paid.
- **Swipe right** to **Receive** or **Pay**.
- **Long-press** for **Record payment received** / **Record payment made**, **Open order financials** and **Open order**.
- New receivables and payables are added from an order's **Financials** screen, not here.

**Receivable and payable statuses** (worked out by the server):

| Status | Meaning |
|---|---|
| **Pending** | Nothing paid yet, not yet due. |
| **Partial** | Partly paid. |
| **Received** / **Paid** | Fully settled. |
| **Overdue** | Past the due date and not fully settled. |

**Who:**

- **View:** Super Admin, Owner, GM, Senior Merchandiser, Accounts and Management Viewer.
- **Change:** Super Admin, Owner, GM and Accounts.

**Try it.** Sign in as `accounts@rmgflow.test`:

1. **Home > Financial**, tap **Overdue**. You see:
   - **RMG-26-0003** Maison Lumière: EUR 61,200, of which 36,720 received.
   - **RMG-26-0012** Pacific Coast balance: USD 19,200.
2. Swipe right on the Pacific Coast row and record USD 19,200 by TT with a reference. It moves to **Settled**.
3. Open the **Payables** tab. **Savar Sweaters** (RMG-26-0003) has USD 14,400, of which 8,000 is paid. Record the rest.
4. Open **RMG-26-0004 > Financials**. Quoted 10.60, cost 8.98, realised 10.45. The margin is "realized".

### 5.16 Claims

**Purpose:** buyer complaints (short shipment, quality, delay) and internal claims against factories, each tracked to a resolution.

**Open it:**

- **Order hub > Claims** to raise and resolve claims for one order.
- **Home > Claims**, or **More > Claims register**, for "All Claims".

**All Claims**

- **Totals:** **Open claims** and **Amount at stake** (open claims, in the order currency).
- Filter by status. Search order, type or description.
- **Long-press** for **Open this order's claims** and **Open order**.

**Claims for one order**

- **New claim** asks for:
  - **By buyer** or **By internal**
  - **Claim type**: Short Shipment, Quality, Delay or Other
  - **Shipment** (optional)
  - **Description** (required, for example "120 pcs short in carton 14")
  - **Claimed amount** (optional)
  - Tap **Record claim**. You see "Claim recorded".
- Each claim shows "<type> · by buyer/internal", the description, the claimed amount and any resolution.
- **Tap the status chip** to open **Update claim**: pick the new status, add notes and tap **Save**.
  - **Under review** takes optional **Notes**.
  - **Resolved** or **Rejected** need **Resolution notes**, for example "Credit note of USD 450 agreed with buyer". The app asks "Close this claim as resolved?" (or rejected), because these are final: *"A resolved claim can no longer be updated."*

**Statuses:** **Open**, **Under Review**, **Resolved** and **Rejected**.

**Who:**

- **View:** Super Admin, Owner, GM, Senior Merchandiser, Junior Merchandiser, Commercial, Accounts and Management Viewer.
- **Change:** Super Admin, Owner, GM, Senior Merchandiser, Junior Merchandiser and Commercial.

**Try it.** Sign in as `commercial@rmgflow.test`:

1. **Home > Claims**. You see the five demo claims, plus a few test claims on `ORD-…` orders.
2. Open **RMG-26-0004**'s claim: Short Shipment, **Open**, 3,200, "120 pcs short against packing list on carton 2". Mark it **Under review**.
3. Then mark it **Resolved** with a note.
4. **RMG-26-0003**'s "Carton side marks" claim is **Rejected**, with the reason shown.

### 5.17 Activity log (calls, emails, meetings, notes)

**Purpose:** a shared diary for any record, so the whole team can see what was discussed.

**Open it:** **Activity & notes** on a buyer, factory, inquiry or style, or the **Activity** tile on an order.

- The screen is titled "Activity Log". Entries are grouped by day ("Today", then dates). Each entry shows the type icon, notes, type and time.
- **Log activity** asks for:
  - **Type**: Call, Email, Meeting or Note
  - **When**: date and time, default now
  - **Notes** (required: what was discussed or agreed?)
  - Tap **Save**. You see, for example, "Call logged".

**Who:**

- **View:** all roles.
- **Log:** every role except Management Viewer.

**Try it.** Sign in as any merchandiser:

1. Open **Buyers > Kestrel Outdoor GmbH > Activity & notes** to read Jonas's partial-shipment call.
2. Log a new **Call**.

### 5.18 Tasks

**Purpose:** to-dos with a due date and priority, either for you or linked to a record.

**Open it:**

- **Home > Tasks** shows **My Tasks**: tasks assigned to you.
- **Tasks** on any buyer, factory, inquiry, style or order shows the tasks for that record.

**List**

- **Summary pills:** "n open", "n overdue" and "n due today".
- Search. **Hide done and cancelled** switch.
- Overdue tasks come first, then tasks by due date. Each shows an **Overdue** chip when late.
- **Swipe right**, or tap the circle, for **Done**.
- **Tap the status chip** for Open, In Progress, Done or Cancelled. Cancelling asks first.
- **Long-press** for **Mark done**, **Start (in progress)**, **Open order** and **Cancel task**.
- In My Tasks, **tapping** a task about an order opens that order.

**New task**

| Field | Meaning |
|---|---|
| **Task is about** | Only in My Tasks: Order, Buyer, Factory, Style or Inquiry, then pick the record. |
| **Title** (required) | For example "Chase lab-dip approval". |
| **Description** | Optional. |
| **Priority** | Low, Medium, High or Urgent. |
| **Due date** | |
| **Assign to me** | On by default. Turn it off to leave the task unassigned. |

Tap **Create task**. Cancelling a task asks "Cancel this task?" and closes it without being done (**Cancel task**). Marking one done shows "Nice — task done".

**Statuses:** **Open**, **In Progress**, **Done** and **Cancelled**.

**Who:**

- **View:** all roles.
- **Create and update:** every role except Management Viewer.

**Try it.** Sign in as `accounts@rmgflow.test`:

1. **Tasks** shows "Follow up L/C balance with Maison Lumiere" (overdue, High) and "Collect balance payment from Pacific Coast".
2. Swipe the first one to **Done**.

### 5.19 Notifications

**Purpose:** in-app alerts addressed to you.

- **Created automatically today:** overdue T&A milestones, sent to the person responsible.
- **Also in the demo data:** sample alerts for failed inspections, amendment decisions, overdue receivables and expiring certificates, so you can see how they look.

**Open it:** the **bell** on Home, or the **Notifications** tile.

- Filter **Unread (n)** or **All**.
- Unread items are highlighted. Each shows the title, the record it is about and the time (for example "07 Oct, 07:00").
- **Tap** a notification to mark it read. For order notifications, this also opens the order.
- **Swipe right** for **Mark read**.
- **Long-press** for **Open order** and **Mark as read**.

Overdue-milestone alerts are created every morning at 07:00 server time. A milestone that stays overdue is reported again each day.

**Try it.** Sign in as `production@rmgflow.test`:

1. Open **Notifications** to see the Packing-overdue alerts for RMG-26-0002 and RMG-26-0004.
2. Tap one. It opens the order.

### 5.20 My Day

**Purpose:** one screen with everything that needs you today.

**Open it:** **My Day** on Home, or the **Items need attention** tile.

- **Header:** "n things need you" or "All clear today", plus **Late milestones**, **Approvals** and **Late tasks**.
- **Overdue T&A milestones:** milestones **you are responsible for** that are past due. Each shows the order, the due date, the status and "n d late". Tap one to open the order's T&A calendar.
- **Pending approvals:** everything waiting in the approvals inbox. Tap to decide.
- **My overdue tasks:** tap to open the order or task. Tap **All tasks** for the full list.
- **Quick links:** one card, "Receivables, payables, claims & more", opens **More**. The grid icon in the title bar does the same.
- Each section shows a green "all clear" line when empty: "No late milestones. Great job!", "Nothing waiting for approval." and "No overdue tasks."
- **Pull down** to refresh.

**Try it.** Sign in as `sampling@rmgflow.test`. My Day lists late milestones such as *Trim Approval* and *PP Sample Approval* on RMG-26-0007 and *Strike-off Approval* on RMG-26-0006, plus the overdue task "Chase proto sample for NVK pique polo".

### 5.21 More, Reference data and Profile

**More** (grid icon on Home):

- **Finance**
  - **Receivables**: what buyers owe us, across all orders.
  - **Payables**: what we owe factories.
  - **Claims register**.
- **Setup**
  - **T&A templates**.
  - **Reference data**: seasons, currencies, countries, document and defect types.
- **Account**
  - **Profile & settings**: your roles, the server and sign out.

**Reference data (read-only).** These lists show exactly what each picker offers. Each list has a search box.

| List | What you see |
|---|---|
| Seasons | Name, year and date range, for example Spring/Summer 2026 (1 Feb to 31 Jul 2026). |
| Currencies | Code and name. |
| Countries | ISO code and name. |
| Incoterms | Code and name (FOB, FCA, CIF…). |
| Payment terms | Name and description. |
| Document types | Name, category and "Mandatory by default". |
| Defect types | Name, category and severity. |
| T&A milestone types | Name, sequence and typical days before ex-factory. |

Editing master data is an administrator task. It can't be done in the app yet.

The Reference Data screen shows one card per list; tap a card to open that list. If a list is empty it says "No … are set up yet. Ask an administrator to add them."

**Profile & settings** (screen "Profile & Settings"): "Signed in as" your email, "User #…", the number of **Roles** and a chip for each role ("What you can see and do is decided by these roles"), then the **App** section with **Server** (copyable), **Theme** ("Follows your device (light / dark)") and **Downloads** ("Reports are saved to Download/RMGFlow"), plus **Sign out**.

---

## 6. Reports

### 6.1 Opening a report

1. Tap **Reports** on Home (header button, banner or tile). The **Reports & Analytics** hub shows how many reports and categories you can use.
2. Reports are grouped by category: Buyers, Merchandising, Orders, T&A, Production, Quality, Shipment, Documents, Finance and Claims. Use **Search reports** to find one by name, description or category. If nothing matches you see "No reports match "…"". If your role has no reports, the hub says "No reports are available for your role."
3. Tap a report. It **runs straight away** with no filters and shows:
   - **Filters** (a collapsible panel; the title shows "Filters (n active)").
   - **Summary cards** with the key totals.
   - **Results:** a table with "n rows · swipe sideways to see all columns". Status columns show coloured chips. Money uses thousands separators, percentages show %, and dates show as dd MMM yyyy.
   - "Generated dd MMM yyyy, HH:mm", the time the server produced the data.

### 6.2 Filters

| Filter type | How to use |
|---|---|
| **Date** (for example "Order date from" / "to") | Tap to pick a date. Tap the × to clear it. "From" must not be after "to". |
| **Buyer** / **Factory** | A dropdown of your buyers or factories. **All** means no filter. |
| **Status-type** (status, result, severity, type…) | A dropdown of the allowed values, shown in plain words (for example `IN_PROGRESS` shows as "In progress", `EXPIRING_SOON` as "Expiring soon"). **Any** means no filter. |

If the buyer or factory list can't load, the field shows "Could not load choices" with a **Retry** button.

Tap **Apply** to run the report with your filters. Tap **Clear** to reset all filters and run the report again. Use the **Refresh** icon in the title bar or pull down to run it again. If nothing matches, you see "No data for the selected filters. Try widening the date range or clearing a filter."

A filter marked with **\*** is required. None of the 15 current reports has a required filter, but if one did, the report would wait with "Ready when you are — Fill in the required filters (*) and tap Apply to run this report." and show **Required** under each empty required filter.

### 6.3 All 15 reports

**Financial** reports (marked 💰 below) also need financial-report permission.

| # | Report (code) | Category | What it answers | Filters | Columns | Summary cards |
|---|---|---|---|---|---|---|
| 1 | **Buyer Order Summary** (`buyer-summary`) | Buyers | Which buyers bring the most business, and how on time we deliver to them. | Order date from/to, Buyer, Order status | Buyer code, Buyer, Country, Currency, Orders, Active orders, Total qty (pcs), Total value, Last order, On-time delivery % | Buyers, Orders, Active orders, Total quantity, Total order value per currency, Average on-time delivery % |
| 2 | **Inquiry Pipeline** (`inquiry-pipeline`) | Merchandising | What is in the sales pipeline and our win rate. | Received from/to, Buyer, Inquiry status | Inquiry no, Buyer, Season, Merchandiser, Status, Target qty, Target price, Currency, Est. value, Delivery req., Received, Age (days) | Total inquiries, count per status, Win rate % (won ÷ decided), Open pipeline value |
| 3 | **Costing Margin** 💰 (`costing-margin`) | Merchandising | Cost and margin of every cost sheet, and which are under the 10% floor. | Created from/to, Buyer, Costing status (Draft/Approved/Superseded) | Style, Buyer, Version, Status, Currency, Qty, Cost / unit, Target price, Margin %, Below floor, Created, Approved | Costings, Approved, Draft, Average margin %, Below 10% margin floor |
| 4 | **Sample Approval Status** (`sample-approval`) | Merchandising | Where every sample stands and what is overdue. | Requested from/to, Buyer, Factory, Sample status | Sample no, Style, Buyer, Factory, Type, Requested, Required by, Status, Revisions, Last submitted, Overdue, Age (days) | Samples, count per status, Overdue, Approval rate %, Average revisions per sample, Sample approvals awaiting decision |
| 5 | **Order Book & Status** (`order-status`) | Orders | All orders, their value and days to delivery. | Order date from/to, Buyer, Factory, Order status | Order no, Buyer PO, Buyer, Factories, Status, Order date, Ex-factory, Delivery, Qty (pcs), Value, Currency, Days to delivery | Orders, count per status, Late (delivery date passed, not shipped), Total quantity, Total order value per currency |
| 6 | **Delayed Orders (T&A)** (`order-delay`) | T&A | Which milestones are late, by how much, and who is responsible. | Due from/to, Buyer, Factory, Delay status (Overdue/Critical Delay) | Order no, Buyer, Milestone, Responsible factory, Responsible person, Planned, Revised, Delay (days), Status, Delay reason | Delayed milestones, Critical delays (> 3 days), Orders affected, Average delay (days), Longest delay (days) |
| 7 | **Production Progress** (`production-progress`) | Production | Cumulative cut, sew, finish and pack per order, and % packed. | Order date from/to, Buyer, Factory, Order status | Order no, Buyer, Factories, Status, Ex-factory, Order qty, Cut, Sewn, Finished, Packed, Rejected, Progress %, Last update | Orders, Total order quantity, Total packed, Overall progress %, Rejection rate % (of cut), Orders not started |
| 8 | **Factory Performance** (`factory-performance`) | Production | Which factories hit their T&A dates and pass inspections. | Order date from/to, Buyer, Factory | Code, Factory, Orders, Milestones, Completed, On time, Overdue, On-time %, Inspections, Fail rate % | Factories, Overall on-time %, Overdue milestones, Average fail rate % |
| 9 | **Inspection Results** (`quality-inspections`) | Quality | Every inspection and the pass rate. | Inspected from/to, Buyer, Factory, Result (Pass/Fail/Reinspect), Inspection type (Inline/Midline/Final) | Date, Order no, Buyer, Factories, Type, Inspected qty, AQL, Result, Defects, Defect rate %, Inspector | Inspections, Passed, Failed, Re-inspect, Pass rate %, Total inspected (pcs), Total defects (pcs) |
| 10 | **Defect Analysis** (`defect-analysis`) | Quality | Which defects happen most, and how serious they are. | Inspected from/to, Buyer, Factory, Severity (Minor/Major/Critical) | Category, Defect, Severity, Occurrences, Defect qty, Share %, Inspections, Orders | Total defects (pcs), Critical, Major, Minor, Top defect category, Open CAPA records, Average CAPA closure (days) |
| 11 | **Shipment Status** (`shipment-status`) | Shipment | Every shipment, and which are at risk (delayed, or ETD passed while still Booked). | ETD from/to, Buyer, Factory, Shipment status | Shipment no, Order no, Buyer, Status, ETD, ETA, Shipped on, Qty shipped, Cartons, Port of loading, Port of discharge, Partial, At risk | Shipments, count per status, At risk, Partial shipments, Total quantity shipped, Total cartons |
| 12 | **Document & Certificate Expiry** (`document-expiry`) | Documents | Documents and factory certificates that have expired or expire within 30 days. | Expires from/to, Expiry state (Expired/Expiring soon/Valid) | Document, Category, Linked to, Reference, Version, Doc status, Expiry date, Days to expiry, State | Documents tracked, Expired, Expiring within 30 days, Valid |
| 13 | **Receivables & Payables Aging** 💰 (`receivables-payables`) | Finance | Who owes what, and how late it is. | Due from/to, Buyer, Factory, Type (Receivable/Payable) | Type, Order no, Buyer / factory, Currency, Amount, Received / paid, Outstanding, Due date, Days overdue, Aging (current/30/60/90+ days) | Receivable outstanding per currency, Payable outstanding per currency, Overdue receivables, Overdue payables, Items 90+ days overdue |
| 14 | **Order Profitability** 💰 (`order-profitability`) | Finance | The margin on each order, using the realised price when known and the quoted price otherwise. | Order date from/to, Buyer, Factory, Order status | Order no, Buyer, Status, Currency, Qty (pcs), Quoted / unit, Cost / unit, Realized / unit, Basis, Margin %, Margin amount | Orders, Average margin %, Below 10% margin floor, Loss-making orders, Total margin per currency |
| 15 | **Claims Summary** (`claims-summary`) | Claims | Buyer and internal claims by type and status. | Raised from/to, Buyer, Claim status, Claim type (Short shipment/Quality/Delay/Other) | Raised, Order no, Buyer, Shipment, Raised by, Type, Status, Claimed amount, Currency, Resolved, Days open, Description | Claims, count per status, Total claimed per currency, Average resolution (days) |

### 6.4 Who sees which reports

You only see the reports your role can run. Each report also shows only the rows your role is allowed to see.

| Role | Reports available | Rows included |
|---|---|---|
| Super Admin, Owner / MD, General Manager | All 15 | Whole organisation |
| Senior Merchandiser | All 15 | Assigned buyers (all 6 in the demo) |
| Accounts & Finance | 14 (all except Inquiry Pipeline) | Whole organisation |
| Management Viewer | 12 (all except the 3 💰 financial reports; the Owner can grant these) | Whole organisation |
| Junior Merchandiser | 12 (all except the 3 💰 financial reports) | Assigned buyers (NVK, BWC, PCB) |
| Commercial Executive | 11: Buyer Summary, Sample Approval, Order Book, Delayed Orders, Production Progress, Factory Performance, Inspection Results, Defect Analysis, Shipment Status, Document Expiry, Claims Summary | Assigned buyers |
| Production Follow-up, Quality Inspector, Factory Coordinator | 10: the Commercial list without Claims Summary | Assigned factories (Factory Coordinator: KNT-GZP only) |
| Sampling Coordinator | 5: Buyer Summary, Sample Approval, Order Book, Delayed Orders, Factory Performance | Assigned buyers and factories |

If you choose a buyer or factory outside your assignments in a filter, the server refuses with "Not permitted to report on this buyer/factory".

### 6.5 Downloading CSV and PDF

At the bottom of every report are two buttons: **Download CSV** and **Download PDF**. They become active once results are on screen.

- The download uses **exactly the filters of the results you are looking at**, so the file matches the screen.
- **CSV** opens cleanly in Excel or Google Sheets. It contains a header row and the data rows, then a blank line, the **Generated** time and the summary. The file is UTF-8 encoded, so Bangla and accented names display correctly.
- **PDF** is landscape A4. It contains the title, the generated time, the applied filters ("Filters: none" if none), a **Summary** table, then the data table with striped rows.
- **File name:** `<report-code>-<yyyyMMdd>.csv` or `.pdf`, for example `order-status-20261007.pdf`.

**Where files go on the phone:**

- On Android 10 and newer, the file is saved to **Download/RMGFlow/** in your phone's shared storage. No permission is needed. Find it with the **Files** app > **Downloads** > **RMGFlow**.
- On Android 9 and older, the app may ask for storage permission the first time. Allow it.
- If the public copy can't be saved, the message says "Downloaded … — use Share to save or send it". The file is still available through **Share**.
- If the download itself fails (for example no network), a bar says "Download failed: …" with the reason. Try again.

After a download, a bar shows **"Saved to Download/RMGFlow/…"** with two buttons:

- **OPEN** opens the file in a PDF viewer or spreadsheet app. If none is installed, you see "No app installed can open PDF/CSV files. Try Share instead."
- **SHARE** opens Android's share sheet, so you can send the file by WhatsApp, Gmail, Outlook, Teams, Google Drive and so on.

### 6.6 Try the reports with demo data

| Sign in as | Open | What you will see |
|---|---|---|
| `owner@rmgflow.test` | Order Book & Status, filter Order status = In progress | Four in-progress orders (RMG-26-0001, -0002, -0007, -0011) with days to delivery. Download PDF and share it. |
| `owner@rmgflow.test` | Order Profitability | RMG-26-0002 (Brightwater shirts, quoted 6.80 against cost 6.21) and RMG-26-0012 (PCB sleepwear, realised 4.80 against cost 4.61) are flagged below the 10% floor. The **Basis** column shows which orders use the realised price and which the quoted price. |
| `accounts@rmgflow.test` | Receivables & Payables Aging, Type = Receivable | The overdue Maison Lumière and Pacific Coast balances with their aging bucket. Download CSV and open it in Sheets. |
| `quality@rmgflow.test` | Inspection Results, Result = Fail | The failed midline and final inspections on RMG-26-0002, -0004 and -0011. |
| `quality@rmgflow.test` | Defect Analysis | Shade variation and skip stitch at the top. Use the Severity filter for Critical. |
| `commercial@rmgflow.test` | Shipment Status | SHP-26-0004 and SHP-26-0006 flagged **At risk**. Two partial shipments. |
| `viewer@rmgflow.test` | Document & Certificate Expiry, Expiry state = Expiring soon | Gazipur Knit's BSCI certificate and Ashulia's SMETA expiring this month. |
| `sr.merch@rmgflow.test` | Inquiry Pipeline | Win rate and open pipeline value across 8 demo inquiries. |
| `production@rmgflow.test` | Delayed Orders (T&A), Delay status = Critical delay | Fabric Booking on RMG-26-0006, Trim Approval on RMG-26-0007, Ex-Factory on RMG-26-0004 and more. |
| `factory.coord@rmgflow.test` | Production Progress | Only Gazipur Knit orders (RMG-26-0001 and RMG-26-0007), because of the factory scope. |

> The demo database also holds some automated-test records. They have codes such as `VB####`, `VF####`, `ST-V####`, `PO-V####`, `E2E…` and `ORD-…`/`SHP-…` numbers with long random suffixes, and they also appear in reports. Ignore them, or filter by one of the six demo buyers.

---

## 7. End-to-end walkthrough: from inquiry to payment

This follows one real demo order from start to finish: **Maison Lumière's women's sweater**. Each step names the screen and the demo record. Sign in as `owner@rmgflow.test` so you can see every step. Where a step needs a particular role to make a change, that role is named.

| Step | What happens in the business | Where in the app | Demo record |
|---|---|---|---|
| 1. Buyer | Maison Lumière SARL (France, EUR, FOB) is a buyer. | Buyers > **Maison Lumiere SARL (MLM-FR)** | Contacts, activity |
| 2. Inquiry | The buyer asks for 6,000 sweaters at EUR 10.20. | Inquiries > **INQ-DEMO-103** (status **Won**) | Factory candidates: **Savar Sweaters (SWT-SVR) Selected** |
| 3. Factory check | Savar is approved for this buyer. | Factories > SWT-SVR > Buyer approvals: MLM **Approved** | Note: its WRAP certificate is **Expired**, so watch it |
| 4. Style | The design is created and specified. | Styles > **MLM-AW26-SW050** (Sweaters, Women, ML-SW-050) | Spec revisions |
| 5. Sample | Development sample requested and sent. | Sampling > **SMP-26-0005** (Requested) | Try **Submit first revision** |
| 6. Costing | Cost sheet built and approved at a 38.6% margin. | Costing > **MLM-AW26-SW050 v1 Approved** | Approval history: approved round |
| 7. Quotation | The price is offered and approved. | Quotations > **QTN-DEMO-003** (EUR 10.20, Approved) | |
| 8. Order | The buyer's PO arrives. | Orders > **RMG-26-0003 / PO-MLM-4410** (6,000 pcs, EUR 61,200) | Status **Shipped** |
| 9. T&A | All 14 milestones are tracked to completion. | Order hub > T&A | 14 of 14 done |
| 10. Production | About 30 daily updates up to 100% packed. | Order hub > Production | |
| 11. Final inspection | Final inspection passed on 11 Sep, which unlocks shipment. | Order hub > Quality | One minor *Stain* defect |
| 12. Shipment | All 6,000 pcs shipped Chattogram to Le Havre and delivered. | Order hub > Shipment > **SHP-26-0001 Delivered** | Documents: Commercial Invoice, Packing List, B/L (all approved) |
| 13. Documents | Certificate of Origin on file. | Order hub > Documents | Certificate of Origin (approved, expires 2027) |
| 14. Receivable | EUR 61,200 due from the buyer. EUR 36,720 received, the rest **overdue**. | Order hub > Financials > Receivables | Swipe to **Receive** the balance (as `accounts@`) |
| 15. Payable | USD 14,400 due to Savar. USD 8,000 paid. | Order hub > Financials > Payables | Swipe to **Pay** (as `accounts@`) |
| 16. Margin | Quoted 10.20, cost 8.71, realised 10.20. | Order hub > Financials header: **Margin · realized** | |
| 17. Claim | The buyer complained about carton marks. The claim was rejected with a reason. | Order hub > Claims | "Carton side marks not in buyer format" **Rejected** |
| 18. Reports | Check the order in Order Book, Shipment Status, Receivables Aging and Order Profitability. | Reports | Download the PDFs |

**Build a new one yourself.** Each step below names the role to sign in with.

1. **`sr.merch@`:** create buyer *Demo Buyer (DMB)*, country DE, EUR, FOB.
2. **`sr.merch@`:** create inquiry *INQ-2026-900* for DMB, 5,000 pcs at 6.50.
3. **`sr.merch@`:** shortlist **Gazipur Knit**, then select it.
4. **`gm@`:** Factories > Gazipur Knit > Buyer approvals > **Set approval**: DMB **Approved**. Without this, step 9 is refused.
5. **`sr.merch@`:** create style *DMB-SS27-001*, add a spec, and tap **New costing**:
   - Fabric 2.10 × 1 + 3%
   - CM 1.20 × 1
   - Trims 0.40 × 1
   - Target price 6.50
6. **`sr.merch@`:** **Submit for approval**.
7. **`gm@`:** approve it in **Approvals**.
8. **`sr.merch@`:** **New quotation** from the approved costing, then **Mark sent**. Then the inquiry: **Mark quoted**, then **Mark won**.
9. **`sr.merch@`:** **New order**:
   - PO *PO-DMB-1*, buyer DMB, link the quotation
   - Ex-factory in 90 days, delivery in 120 days
   - One line: style DMB-SS27-001, factory Gazipur Knit, 5,000 pcs at 6.50
10. **`sr.merch@`:** on the order, tap **T&A > Generate calendar**.
11. **`production@`:** add a few **Daily updates**. Mark some milestones **Done today**.
12. **`quality@`:** record a **Final** inspection with result **Pass**.
13. **`commercial@`:** **New shipment** for all 5,000 pcs. The order becomes **Shipped**.
14. **`accounts@`:** on the order's **Financials**:
    - **Edit financials**: quoted 6.50, cost 5.40, realised 6.50
    - Add a receivable (DMB, EUR 32,500, due in 30 days) and record a payment
    - Add a payable (Gazipur Knit) and pay it
15. **`owner@`:** run **Order Profitability** and download the PDF.

---

## 8. Quick guides by role

Each guide is a one-page daily routine. For the full details of any screen, see section 5.

### 8.1 Owner / MD and General Manager (`owner@`, `gm@`)

**Every morning**

1. **My Day:** check the number of things that need you.
2. **Approvals:**
   - Clear the inbox: swipe right to approve, or swipe left to reject with a reason.
   - Use **Review costing** before approving a cost sheet.
   - Watch any costing **below the 10% margin floor**.
3. **Notifications:** failed final inspections (shipment blocked), cancelled orders, amendments waiting.

**During the day**

- **Orders > order > Amendments:** approve or reject change requests.
- **Order > Cancel order** when needed. A reason is required.
- **Factories > Buyer approvals:** keep each buyer's factory approvals current.
- **Overrides (use sparingly; each one is recorded):**
  - The factory-approval override on a new order.
  - The quality-gate override and partial shipments on a shipment.

**Weekly**

- **Reports:** Order Book & Status, Order Profitability, Receivables & Payables Aging, Factory Performance, Buyer Order Summary.
- Download PDFs and share them with management.

### 8.2 Senior Merchandiser (`sr.merch@`)

**Morning**

- **My Day** and **My Tasks**: today's chases.
- **Approvals:** approve costings, quotations and samples from your team.

**Pipeline**

- **Inquiries:**
  - Log new requests.
  - Shortlist and select factories.
  - Move the status: Open, Quoted, Won or Lost (with a reason).
- **Styles:** add specs. Every change becomes a new revision; use **Compare** to show the buyer what changed.
- **Costing:**
  - Build sheets and submit them.
  - To change an approved sheet, use **Create new version**.
- **Quotations:**
  - Create them from approved costings.
  - **Mark sent**, then record the buyer's answer.
  - Revise if the buyer negotiates.

**Orders**

- **New order:** link the quotation, set the ex-factory date and add lines. Then **Generate** the T&A calendar.
- Request **Amendments** for date changes.
- Maintain **T&A templates** (More).

**Reports:** Inquiry Pipeline, Costing Margin, Delayed Orders (T&A), Sample Approval Status.

### 8.3 Junior Merchandiser (`jr.merch@`)

- **My Day / My Tasks:** overdue chases first. Swipe tasks to Done.
- **Inquiries:** log and update. **Factory candidates:** shortlist factories.
- **Styles and Samples:** create styles, add spec revisions, request samples and submit revisions.
- **Costing:** build and submit draft sheets.
  - You can't see unit costs or margin; they show as "hidden".
  - When you revise a sheet, re-enter the unit costs.
- **Quotations:**
  - Create and send them, and record Negotiating, Rejected or Expired.
  - Marking **Approved** is reserved for approvers.
- **Orders:** follow up T&A (mark milestones done, giving a delay reason when late) and request amendments.
- **Claims:** raise buyer claims from the order.
- **Reports:** your buyers' Order Book, Delayed Orders and Sample Approval.

### 8.4 Sampling Coordinator (`sampling@`)

- **My Day:** late sampling milestones (Lab Dip, Strike-off, Trim, PP Sample Approval) and overdue tasks.
- **Sampling:**
  - **Request sample**: pick the buyer, then the style, type, factory and required-by date.
  - When a sample goes to the buyer, tap **New revision** with a comment.
- **Approvals:**
  - Decide sample revisions: approve, **Return** for changes, or reject with a reason.
  - Then, on the sample, tap **Refresh status from latest approval**.
- **T&A:** mark sample-related milestones done.
- **Reports:** Sample Approval Status (overdue samples and approval rate) and Delayed Orders.

### 8.5 Production Follow-up (`production@`)

- **My Day / Notifications:** overdue Packing, Cutting and Sewing milestones.
- **Home > Production > pick order > Daily update:** enter **today's** cut, sew, finish and pack figures plus rejects and alterations. These are not running totals. Skip Fridays.
- **Home > T&A > pick order:** tap **Done today** or **Other date**. Give the delay reason when late.
- **Tasks:** for example "Confirm trims in-house date for PO-NVK-260211".
- **Reports:** Production Progress, Delayed Orders (T&A), Factory Performance.

### 8.6 Quality Inspector (`quality@`)

- **My Day:** Final Inspection milestones due.
- **Home > Quality > pick order > Record inspection:**
  - Choose the type and quantity, an AQL of 2.5, and the result.
  - Then log each defect (type, quantity, severity).
- **Defect > CAPA:** open a CAPA for major and critical defects, record the factory's response, and **Close** it when verified.
- Remember: **a failed Final blocks shipment** until a passing Final is recorded.
- **Reports:** Inspection Results (pass rate) and Defect Analysis (top defects).

### 8.7 Commercial Executive (`commercial@`)

- **Notifications / My Day:** shipments that missed their ETD and ex-factory milestones.
- **Home > Shipment > pick order > New shipment:**
  - Book the full remaining quantity. Partial shipments need GM approval.
  - Enter cartons, weights, ETD and ETA, ports, the shipping line, container and B/L.
- **Shipment detail:** move it through Booked, In Transit and Delivered, or mark it **Delayed**.
- **Documents:**
  - On the order and on each shipment, approve draft invoices and packing lists. Swipe right.
  - Tap a document to open the PDF.
- **Claims:** raise, review and resolve buyer claims.
- **Reports:** Shipment Status (at risk), Document & Certificate Expiry, Claims Summary.

### 8.8 Accounts & Finance (`accounts@`)

- **Home > Financial:**
  - Tap **Overdue** first.
  - Swipe right to **Receive** or **Pay**. Enter the amount, date, method (TT, LC, cheque, cash) and reference.
  - Payments are final.
- **Order > Financials:**
  - Keep the quoted price, actual cost and realised price up to date.
  - Add a receivable when you invoice the buyer.
  - Add a payable when a factory bill is due.
- **Tasks:** for example "Follow up L/C balance with Maison Lumiere".
- **Reports:** Receivables & Payables Aging (weekly), Order Profitability, Costing Margin. Download the CSV for Excel.

### 8.9 Factory Coordinator (`factory.coord@`)

- You work for **Gazipur Knit (KNT-GZP)**.
- **Production > pick order** (RMG-26-0001, RMG-26-0007): enter a daily update every working day.
- **T&A:** mark your factory's milestones done.
- **Tasks:**
  - "Book BSCI renewal audit for Gazipur Knit"
  - "Share inline inspection photos with factory"
- **Notifications:** certificate expiry warnings.
- **Reports:** Production Progress and Delayed Orders. They show only your factory.

### 8.10 Management Viewer (`viewer@`)

- **Read-only.** You can browse buyers, factories, styles, samples, costings (cost figures hidden), quotations, orders and every order module, financials, claims, tasks and activity. Any change is refused.
- **Reports:** 12 non-financial reports for the whole organisation. Download and share PDFs. Ask the Owner for financial-report access if you need it.

### 8.11 Super Admin (`demo.admin@`)

- Everything in the app, including deciding every approval type.
- User, role and master-data administration is not in the mobile app yet. It is done on the server.

---

## 9. Troubleshooting and FAQ

### 9.1 Problems and fixes

| Problem | What it means | What to do |
|---|---|---|
| **"Could not reach the server. Check your connection."** | The phone can't reach the server address built into the app. | 1. Check Wi-Fi or mobile data. 2. For the office demo, join the **same Wi-Fi** as the server PC. 3. Check **More > Profile & settings > Server** and open that address in the phone's browser; you should see a response, not a timeout. 4. Make sure the server is running. 5. If the PC's IP address changed, the administrator must rebuild the APK (`./scripts/demo.sh build`) and you must reinstall it. |
| **Sign-in says "Invalid credentials"** | Wrong email or password. | Check the email for typos. The demo password is `Demo@1234` (capital D). |
| **"Your session has expired. Please sign in again."** | Your 30-day sign-in ran out, or an administrator ended it. | Sign in again. Nothing saved is lost. |
| **"You don't have permission to do that."** or "Missing permission …" | Your role can't do this action. | See your roles under **More > Profile**. Ask a user with the right role (see [3.4](#34-roles-and-demo-accounts)) or your administrator. |
| A Home tile is missing | Your role can't open that module. | This is expected. See [section 8](#8-quick-guides-by-role). |
| **"This record changed elsewhere. Refresh and try again."** | Someone else saved the same record first. | Go back, reopen the record and make your change again. |
| **"Please check the highlighted fields."** / red text under a field | A required field is empty or a value is invalid. | Fix the field shown in red. |
| Amounts and margin show **"hidden"** | Your role has no margin permission. | This is expected for Junior Merchandiser and Management Viewer. |
| **"Factory X is not approved for buyer Y …"** | The factory approval gate. | Ask the GM to set the factory's **Buyer approval** to Approved, or to create the order with an override and a reason. |
| **"Order has no passing FINAL inspection …"** | The quality gate. | Record a passing Final inspection, or ask the GM to ship with an override. |
| **"Partial shipment requires … permission"** | You entered less than the remaining quantity. | Ship the full remaining quantity, or ask the GM. |
| **"Shipment quantity exceeds the remaining order quantity"** | You tried to ship more than was ordered. | Reduce the quantity. There is no override. |
| **"Only a DRAFT costing can be edited …"** | The costing is approved or superseded. | Use **Create new version**. |
| **"A quotation can only be created from an APPROVED costing"** | The costing isn't approved yet. | Submit the costing and get it approved first. |
| **"Cannot transition inquiry from … to …"** | That status move isn't allowed. | Follow the order Open, Quoted, then Won or Lost. See [5.3](#53-inquiries). |
| **"T&A needs an ex-factory date …"** or "Needs ex-factory" | The order has no ex-factory date. | Request an amendment for `exFactoryDate` (see [5.9](#59-orders-and-amendments)), then generate. |
| **"T&A milestones already exist for this order"** | The calendar was already generated. | Use the existing calendar. |
| **"Unsupported amendment field: …"** | A known issue with the amendment field list. | Choose **Other** and type `exFactoryDate` or `deliveryDate`, with the value as `yyyy-MM-dd`. |
| **"Latest approval round is not yet decided"** | You tapped Refresh on a sample still waiting for approval. | Wait for the approver's decision. |
| **Downloaded report not visible** | The file is in the shared Downloads folder. | Open **Files** > **Downloads** > **RMGFlow**. Some file apps sort by date, so look at "Recent". If the message said "use Share to save or send it", tap **SHARE** and save it to Drive or send it to yourself. |
| **"No app installed can open PDF/CSV files"** | The phone has no viewer for that file type. | Install a PDF viewer (for example Google Drive or Adobe Acrobat) or a spreadsheet app (Google Sheets, Excel), or use **Share**. |
| A document won't open | The download link expired or the file is missing. | Tap the document again. A fresh link is made each time and lasts 5 minutes. |
| Lists look out of date | Cached screen. | **Pull down** to refresh. |
| **"Something went wrong on our end."** | A server error. | Try again. If it repeats, note the time and screen and tell your administrator. |

### 9.2 FAQ

**Can I use the app offline?**
No. Every screen reads live data from the server.

**Can I change my password in the app?**
Not yet. Ask your administrator.

**Why does a costing still say Draft after I submitted it?**
It stays Draft while under review. Open **Approval history** to see the round. It becomes **Approved** once an approver approves it.

**Why is my submitted quotation not in the approvals inbox?**
In the app, quotations are approved by an approver marking them **Approved**. Rounds created by the demo data also appear in the inbox.

**Can I edit an approved costing or quotation?**
No. Create a new version. The approved one stays as a permanent record.

**Can I undo a milestone marked done?**
Only while the **Undo** bar is showing, right after you tap Done. Once saved, an actual date can't be changed.

**Can I edit a payment?**
No. Payments are part of the financial audit trail. Ask Accounts to record a correcting entry if needed.

**Why do I get the same overdue alert every day?**
The daily scan reports each milestone that is still overdue. Mark the milestone done, with a delay reason if it was late, to stop the alerts.

**Why do some orders and shipments have long numbers like `ORD-5b0a…`?**
Orders and shipments created in the app currently get a system-generated number. The readable `RMG-26-0001` and `SHP-26-0001` style numbers come from the demo data.

### 9.3 Getting help

Note the screen, the time and the exact message shown in the red bar, then send them to your RMGFlow administrator.

### 9.4 Known limitations

These are the honest gaps in the current build:

- **Data scope in module screens:** "own buyers / own factory" limits apply to **reports** only. Module lists show the organisation's records to every role that can open the module.
- **Approvals inbox:** every role sees every pending approval, even items it can't decide.
- **Amendments:** only ex-factory date and delivery date changes can be applied, and they must be entered through **Other** with the technical field name (see [5.9](#59-orders-and-amendments)).
- **Order status:** "In Progress" and "Closed" aren't set by any action in the app. Shipped and Partially Shipped are set automatically by shipments.
- **No automatic T&A:** after you create an order, someone with template rights must tap **Generate calendar**.
- **Styles:** you can't edit a style's own fields or set its season. Specs are handled through revisions.
- **Samples:** you can't edit a sample after requesting it.
- **Files:** you can't upload files from the phone. Style and factory documents (tech packs, test reports) aren't listed in the app; they appear in the Document Expiry report.
- **Lab dip, trim, PP sample, inspection, shipment and document approvals** can only be decided by the Super Admin.
- **Not in the app yet:**
  - user management, password change, session list
  - notification preferences and push notifications
  - organisation-wide lists of shipments, inspections and documents (you open them per order)
  - global search
  - audit-log browsing
  - editing master data
- **Shared reference data:** currencies, countries, incoterms, payment terms, document, defect and milestone types, and seasons are shared by all organisations on the same server.
- **Junior Merchandiser costing:** when revising a costing, the hidden unit costs must be typed again.

---

## 10. Glossary

| Term | Meaning |
|---|---|
| **AQL** | Acceptable Quality Level. The sampling standard for inspections; 2.5 is common for major defects. |
| **AR / Receivable** | Money the buyer owes the buying house. |
| **AP / Payable** | Money the buying house owes a factory or vendor. |
| **AWB** | Air Waybill, the transport document for air freight. |
| **B/L (Bill of Lading)** | The shipping line's receipt and title document for sea freight. |
| **BSCI / amfori BSCI** | A social-compliance audit for factories. |
| **Buyer PO** | The buyer's purchase order number. |
| **Buying house** | An agent that sources garments from factories on behalf of overseas brands and retailers. |
| **CAPA** | Corrective And Preventive Action. The fix for a defect now (corrective) and how to stop it recurring (preventive). |
| **CBM** | Cubic metres, the shipment volume. |
| **CEPZ / KEPZ** | Chattogram and Karnaphuli Export Processing Zones. |
| **CM** | Cut & Make (sometimes CMT, Cut-Make-Trim). The factory's making charge per garment. |
| **Consumption** | How much material one garment uses, for example fabric kg per piece. |
| **Costing / cost sheet** | The itemised cost of making a style, used to set a price. |
| **Critical delay** | A T&A milestone more than 3 days past due. |
| **DC** | Distribution centre, the buyer's warehouse. |
| **ETD / ETA** | Estimated Time of Departure and Arrival. |
| **Ex-factory date** | The date goods must leave the factory. The whole T&A is planned back from it. |
| **FOB / FCA / CIF / Incoterms** | International trade terms that define who pays freight and insurance and where risk passes. FOB: Free On Board (the buyer pays from the port of loading). FCA: Free Carrier. CIF: Cost, Insurance & Freight (the seller pays to the destination port). |
| **Final inspection** | The pre-shipment inspection on packed goods. A pass is required to ship. |
| **Fit sample** | A sample that checks fit on a model or form. |
| **GOTS / OEKO-TEX** | Organic textile and harmful-substance certifications. |
| **GSM** | Grams per square metre, the fabric weight. |
| **Inline / Midline inspection** | Quality checks during production (early and mid-way). |
| **Inquiry** | A buyer's request for a price or a program. |
| **Lab dip** | A small dyed swatch submitted for colour approval. |
| **LC (Letter of Credit)** | A bank guarantee of payment against compliant shipping documents. |
| **Margin %** | (Price - cost) ÷ price × 100. RMGFlow flags margins under 10%. |
| **Packing list** | A carton-by-carton list of what is shipped. |
| **Partial shipment** | Shipping less than the remaining order quantity. Needs authorisation. |
| **PP meeting** | Pre-production meeting with the factory before bulk cutting. |
| **PP sample** | Pre-production sample made with bulk materials. The buyer must approve it before production. |
| **Proto sample** | The first sample of a new design. |
| **Quotation** | The price offer to the buyer, made from an approved costing. |
| **RMG** | Ready-Made Garments, Bangladesh's main export industry. |
| **Round (approval)** | One submit-and-decide cycle. A rejected item starts a new round when resubmitted. |
| **RSC** | RMG Sustainability Council, which handles structural, fire and electrical safety. |
| **Season** | A selling season, for example SS26 (Spring/Summer 2026) or AW26 (Autumn/Winter 2026). |
| **Sedex / SMETA** | An ethical trade audit format. |
| **Size set** | Samples in every size, used to check grading. |
| **Strike-off** | A print or embroidery trial on fabric, for approval. |
| **Style** | One garment design for one buyer, with its spec revisions. |
| **Superseded** | Replaced by a newer version. Kept for the record. |
| **T&A (Time & Action)** | The calendar of critical milestones from order to ex-factory. |
| **Tech pack** | The buyer's technical package: sketches, measurements and materials. |
| **TOP sample** | Top Of Production sample, taken from the first bulk output. |
| **Trims** | Buttons, zips, labels, thread, tags and other accessories. |
| **TT** | Telegraphic Transfer, a bank wire payment. |
| **WRAP** | Worldwide Responsible Accredited Production, a compliance certification. |
| **Wastage %** | Extra material allowed for cutting loss and defects. |

---

## 11. Recommendations for the next version

These suggestions would make the app easier to use and close the gaps above. They are listed roughly in order of value.

1. **Fix amendment fields.** Map "Ex-factory date" and "Delivery date" in the picker to the server's field names, and hide fields the server can't apply yet. Today users must use the **Other** workaround.
2. **Auto-generate T&A when an order is created**, using the buyer's or the default template. Also show "Generate" only to roles that can use it.
3. **Readable numbers for app-created records:** `RMG-YY-NNNN` for orders and `SHP-YY-NNNN` for shipments, like the demo data.
4. **Enforce "own buyers / own factory" in module screens**, not only in reports. Also filter the approvals inbox to items the user can decide.
5. **Upload from the phone:** camera and gallery upload for inspection photos, B/L scans and tech packs, plus style and factory document lists in the app.
6. **Submit a quotation for approval** from the app, so quotation approval works the same way as costing approval.
7. **Organisation-wide lists** for shipments, inspections and documents, with an "at risk" filter, so Commercial and Quality don't have to pick orders one by one.
8. **Push notifications** with daily de-duplication of overdue alerts, and a notification preferences screen.
9. **Profile:** change password, see active sessions and sign out other devices.
10. **Global search** across orders, POs, styles, buyers and shipments from the Home header.
11. **Saved report filters and scheduled email of reports** (for example the weekly AR aging PDF to Accounts and the Owner), plus simple charts on report summaries.
12. **Bangla language option** for factory-floor users (production and factory coordinators).
13. **Offline entry for daily production updates,** synced when the network returns.
14. **Grant Management Viewer the financial reports** if the Owner agrees. This is a one-line permission change.
