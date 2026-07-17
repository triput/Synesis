# ByteMail Architecture: Under the Hood

Welcome to the ByteMail project! This document is designed for tech enthusiasts, product thinkers, and engineers who want to understand how ByteMail works under the hood without needing to read or write a single line of Dart code. 

ByteMail is a modern, cross-platform email client built on Flutter. But beneath its UI lies a highly engineered system designed around **local-first** principles, zero-lag performance, and reliable background synchronization.

---

## 1. The Local-First Philosophy

Most modern email apps are "thin clients"—they constantly talk to the cloud. If you lose your internet connection, or if the server is slow, the app stalls, shows loading spinners, or fails to open emails.

ByteMail flips this model on its head using a **Local-First Architecture**. 
* **The Database is the Source of Truth:** Everything you see in the app—your inbox, folders, messages, and settings—is read directly from a local SQLite database residing on your device. 
* **Zero UI Lag:** Because reading from local storage takes a fraction of a millisecond, the UI can maintain a fluid 60 frames per second (FPS). 
* **Offline Resilience:** If you compose a message while on a subway with no signal, ByteMail saves it to a local Outbox. The app handles the complex task of queueing and sending it as soon as the network returns.

---

## 2. The Core Stack

ByteMail is built using a carefully curated stack of technologies:

* **Flutter / Dart:** The entire UI and business logic is written in Dart and rendered by Flutter. This allows ByteMail to compile down to native machine code for both Windows (Desktop) and Android (Mobile), using one single codebase.
* **SQLite + Drift:** At the heart of the local-first approach is SQLite. We use a library called **Drift** to safely manage our database tables. It allows us to perform fast, complex queries (like full-text searches across thousands of emails) almost instantly.
* **Dart Isolates:** Dart is normally single-threaded. To prevent the UI from freezing when processing heavy tasks (like parsing massive email attachments or negotiating encrypted network connections), ByteMail offloads heavy work to "Isolates" (background workers).

---

## 3. How Data Flows (The BLoC Pattern)

To keep the UI snappy and predictable, ByteMail strictly adheres to the **BLoC (Business Logic Component)** pattern, specifically using **Cubits**. 

Here is how information travels from an email server to your screen:

1. **The Sync Engine (Background):** A separate background engine negotiates with Microsoft Exchange, Google, or your custom mail server. When it finds a new email, it downloads it and writes it directly to the local SQLite database.
2. **The Database Streams:** The local database acts as a live broadcaster. Whenever a new row (email) is inserted, it emits an update signal.
3. **The Cubit (State Manager):** The UI has "Cubits" (like the `MailboxCubit`) that listen to these database streams. When the Cubit hears about the new email, it processes it and emits a new "State".
4. **The UI (Reactive):** The visual components (Widgets) are entirely "dumb." They only know how to draw what the Cubit tells them. When the Cubit emits a new State, the screen repaints to show the new email.

This one-way data flow guarantees that the UI will never fall out of sync with the data.

---

## 4. Multi-Protocol Engine

Email is a notoriously messy standard. ByteMail manages this complexity through a **Provider Registry**. Depending on the type of account you add, the app seamlessly swaps out the "engine" under the hood:

* **Microsoft Graph API:** For Outlook and Exchange accounts, ByteMail uses modern HTTPS-based Graph APIs. This allows for clean OAuth authentication, fast incremental syncing, and modern token management.
* **IMAP / SMTP:** For Google and independent providers, ByteMail falls back to the classic IMAP (for receiving) and SMTP (for sending) protocols. 

Regardless of which protocol fetched the email, it is normalized and saved in the exact same format inside the local database. The UI never has to care whether an email came from a 1990s IMAP server or a modern Microsoft Graph endpoint.

---

## 5. Focus and Search

* **Fast Local Search:** Thanks to SQLite's Full-Text Search (FTS5) extension, typing into the search bar instantly queries the local cache. 
* **Focus Scorer:** ByteMail implements an intelligent `FocusScorer` that evaluates incoming mail. Based on rules (and future smart heuristics), it determines if an email should hit your "Focused" inbox or be routed to "Other".

---

## 6. Engineered for Quality

ByteMail isn't just coded; it is architected via a strict **Phase-Gate Delivery** model internally referred to as the "Leadership Trifecta."

* **Zero Placeholders:** You won't find half-finished features. Code is expected to be strictly typed and fully functional.
* **Defensive Coding:** Network requests fail, servers return bad data, and files get corrupted. The codebase relies heavily on catching exact errors, implementing safe fallbacks, and preventing isolated crashes from bringing down the entire app.
* **Gold Master Standards:** Every core component features a strict file header denoting its purpose, layer, and version. Documentation is not an afterthought; it is treated as a required deliverable. 

This rigorous approach ensures that as ByteMail scales from handling 100 emails to 100,000 emails, it remains as fast and stable as day one.