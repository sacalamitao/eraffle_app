# 📘 eRaffle Technical Documentation - RaffItAll

**Architecture:** Supabase Auth + Rails API + Relational ERD (Web-and-Spoke)  
**Author:** Jhun Codevelopr  
**Updated:** April 2026

---

## 1) Core Philosophy

The platform follows a **No-Local-User-Model** approach in Rails for authentication, while using a **Relational Web-and-Spoke** domain model for raffle operations.

- **Supabase Auth** handles identity (signup, login, JWT issuance).
- **Rails + Postgres** handle business data and raffle logic.
- **Raffle is the center (the “sun”)** of the data model.

This avoids overloading a single `User` concept with too much logic and keeps the system modular and scalable.

---

## 2) Authentication and Identity Design

### Why no local `User` model?

- **Identity vs. Business Data Separation**
  - Identity: Supabase Auth
  - Business entities: Profiles, Raffles, Participants, Entries, Prizes, Winners
- **Security**
  - Rails does not process raw passwords.
  - Rails verifies JWT signatures locally.
- **Operational reliability**
  - DB trigger creates profiles even if Rails is temporarily unavailable.

### Current identity table: `profiles`

`profiles` acts as a **Universal Actor** record (host, facilitator, player, etc.).

---

## 3) Existing Rails Schema Snippet (`profiles`)

```ruby
create_table "profiles", id: :uuid, default: nil, force: :cascade do |t|
  t.text "email"
  t.integer "tickets_count", default: 0
  t.string "first_name"
  t.string "last_name"
  t.jsonb "metadata", default: {}
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["email"], name: "index_profiles_on_email", unique: true
end
```

---

## 4) Automated Profile Sync (Supabase → Public Schema)

### Flow

1. User signs up via Supabase.
2. `auth.users` receives a new record.
3. Postgres trigger calls `handle_new_user()`.
4. Insert is performed into `public.profiles`.

### SQL Trigger

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name, tickets_count, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    0,
    now(),
    now()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

---

## 5) Auth Handshake (JWT + JWKS)

Rails verifies tokens without calling Supabase on every request.

1. Fetch Supabase JWKS.
2. Verify JWT signature locally (`ES256`).
3. Read `sub` claim.
4. Resolve profile:

```ruby
@current_profile = Profile.find(payload['sub'])
```

---

## 6) Recommended ERD Model (Senior Dev + BA Recommendation)

### Recommendation Summary

Use a **Relational Web-and-Spoke model** with **Raffles as the central node**.

By splitting **Participants** (the person’s participation in a raffle) from **Entries** (the raffle tickets/chances), the model supports all three pillars:

- **Private:** 1 Participant = 1 Entry (Check-in)
- **Influencer:** 1 Participant = 1 Entry (Verified Social)
- **Brand:** 1 Participant = Many Entries (Sachet Scans)

---

## 7) ERD Component Breakdown

### 7.1 Profiles (Existing)

- **Role:** The Identity
- **Key Change:** Treat as a **Universal Actor**
- **Important Note:** Profile no longer owns raffle behavior directly; it is referenced by raffle-domain tables.

### 7.2 Raffles (The Container)

- **Role:** The Room / Event
- **Relationship:** Belongs to a `Profile` (Facilitator)
- **Key Logic:** Holds raffle `category` (`private`, `public`, `brand`)
  - Frontend uses category to decide CTA behavior:
    - Show **Join** for one-entry flows
    - Show **Scan Sachet** for accumulative-entry flows

### 7.3 Participants (The Connection)

- **Role:** The Guest List
- **Relationship:** Join table between `profiles` and `raffles`
- **Key Logic:** Tracks `checked_in` state
  - Example: 500 registered, 200 checked-in → draw only includes 200 eligible participants.

### 7.4 Entries (The Chance)

- **Role:** The Physical Tickets
- **Relationship:** Belongs to a `Participant`
- **Key Logic:** Enables weighted chance for loyalty/brand mechanics
  - In accumulative raffles, each successful sachet scan creates a new `entry` row.
  - If draw selects by `entry_id`, 10 entries = ~10x chance.

### 7.5 Prizes (The Goal)

- **Role:** The Inventory
- **Key Logic:** Include `draw_style` per prize
  - Example:
    - Minor prizes → **Burst** (multi-winner draw)
    - Grand prize → **Elimination**

### 7.6 Winners (The Broadcast)

- **Role:** The Result Ledger
- **Relationship:** Links `participant` to `prize`
- **Key Logic:** This is the event table for live display and post-draw audit
  - When a winner row is inserted, UI listeners (e.g., Supabase realtime) can trigger confetti/name reveal.

---

## 8) Why This Flow Is Recommended

### Scalability

Adding a new pillar (example: **Charity Auction**) does not require a schema rewrite. Add new raffle categories/behaviors while preserving the same core entities.

### Audit Trail

`winners` provides a permanent record of:

- who won,
- what prize was won,
- claim lifecycle (e.g., pending, claimed, shipped).

This is critical for compliance and logistics in brand campaigns.

### Performance + Security

With Supabase/Postgres, enforce Row Level Security (RLS):

- participant can view only their own entries,
- facilitator can view entries for raffles they own/manage.

---

## 9) Frontend Signup Metadata Requirement

During signup, send first/last name in `options.data` so DB trigger can map values into `profiles`.

```javascript
const { data, error } = await supabase.auth.signUp({
  email: 'example@email.com',
  password: 'password123',
  options: {
    data: {
      first_name: 'Jhun',
      last_name: 'Codevelopr'
    }
  }
})
```

---

## 10) Testing Quick Guide (Postman)

### A. Sign up

- `POST https://<project-id>.supabase.co/auth/v1/signup`
- Headers: `apikey: YOUR_ANON_KEY`

### B. Login and obtain access token

- `POST https://<project-id>.supabase.co/auth/v1/token?grant_type=password`
- Headers:
  - `apikey: YOUR_ANON_KEY`
  - `Content-Type: application/json`

### C. Verify Rails protected endpoint

- `GET http://localhost:3000/me`
- Header: `Authorization: Bearer <access_token>`

---

## 11) Final Notes

This design keeps Rails stateless, domain-driven, and raffle-centric:

- Auth remains externalized and secure.
- Raffle logic remains relational and extensible.
- Real-time winner broadcasting and strong auditability are first-class by design.
