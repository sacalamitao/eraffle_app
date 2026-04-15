# 📘 eRaffle Official Developer Documentation

**Architecture:** Supabase Auth & Rails Profile Integration  
**Author:** Jhun Codevelopr  
**Date:** April 2026

---

## 1) Core Philosophy: "No-User-Model" Rails

Unlike traditional Rails apps, this architecture does **not** use a local `User` model.

### Why this approach?

- **Identity vs. Data:**
  - **Identity** (email/password/login) is handled by **Supabase Auth**.
  - **Data** (tickets, names, roles) lives in Rails business logic.
- **Reduced security risk:** Rails never handles raw passwords; it only trusts verified UUIDs.
- **Efficiency:** Avoids Devise/Bcrypt overhead and keeps the API lean.

---

## 2) Rails Schema Configuration

The `profiles` table is the heart of application data. It uses a UUID primary key so IDs match Supabase exactly.

```ruby
create_table "profiles", id: :uuid, default: nil, force: :cascade do |t|
  t.text "email"
  t.text "role", default: "participant"
  t.integer "tickets_count", default: 0
  t.string "first_name"
  t.string "last_name"
  t.jsonb "metadata", default: {}
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["email"], name: "index_profiles_on_email", unique: true
  t.check_constraint "role = ANY (ARRAY['admin'::text, 'facilitator'::text, 'participant'::text])", name: "role_check"
end
```

---

## 3) Automated Sync via SQL Trigger

To bridge Supabase signup with Rails profile creation, use a PostgreSQL trigger.

This runs **inside the database**, so profile creation is reliable even if Rails is down.

### Logic flow

1. User signs up via frontend/Supabase.
2. `auth.users` receives a new row.
3. Trigger fires `handle_new_user()`.
4. Data is mapped into `public.profiles`.

### SQL

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name, role, tickets_count, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    'participant',
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

## 4) Auth Handshake (JWT + JWKS)

Rails does not call Supabase on every request. It verifies JWTs locally using asymmetric cryptography.

### Verification steps

1. **Fetch keys:** Rails fetches Supabase JWKS from:
   - `https://<id>.supabase.co/auth/v1/.well-known/jwks.json`
2. **Decode token:** Validate JWT signature locally using `jwt` gem + `ES256`.
3. **Identify user:** Read `sub` claim (Supabase UUID).
4. **Authorize:** Set current profile from UUID.

```ruby
@current_profile = Profile.find(payload['sub'])
```

---

## 5) Security Constraints

- **SECURITY DEFINER:**
  - Trigger function runs with definer privileges.
  - Allows initial `profiles` insert even before user-specific RLS permissions apply.
- **Role check constraint:**
  - Enforces valid roles only: `admin`, `facilitator`, `participant`.
- **JWT audience check:**
  - Rails must strictly verify `aud == authenticated`.

---

## 6) Metadata Mapping & Frontend Implementation

During signup, the frontend must pass names in `options.data`.  
This is the source used by the DB trigger for `first_name` and `last_name`.

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

## 7) Testing & Debugging (Postman Guide)

### A) Test user creation (signup)

- **Method:** `POST`
- **URL:** `https://your-project-id.supabase.co/auth/v1/signup`
- **Headers:** `apikey: YOUR_ANON_KEY`
- **Body:** `raw` → `JSON`

```json
{
  "email": "test@example.com",
  "password": "password123",
  "data": { "first_name": "Jhun", "last_name": "Dev" }
}
```

### B) User login (sign in)

Use this to get a fresh JWT (`access_token`).

- **Method:** `POST`
- **URL:** `https://<your-project-id>.supabase.co/auth/v1/token?grant_type=password`
- **Headers:**
  - `apikey: YOUR_SUPABASE_ANON_KEY`
  - `Content-Type: application/json`
- **Body (JSON):**

```json
{
  "email": "jhun.test@example.com",
  "password": "password123"
}
```

- **Expected response:** Copy the `access_token` from the JSON response.

### C) Test Rails handshake (`/me`) in Postman

- **Method:** `GET`
- **URL:** `http://localhost:3000/me`
- **Authorization tab:**
  - Type: `Bearer Token`
  - Token: paste `access_token` from signup/login
- **Headers tab:** Postman auto-generates `Authorization: Bearer <your_token>`
- **Send:** Click **Send**

### D) Rails auth test via header

- **Method:** `GET`
- **URL:** `http://localhost:3000/me`
- **Header:** `Authorization: Bearer <token>`

---

## Notes

This setup keeps Rails **stateless**:

- No server-side session storage needed.
- If JWT is valid and UUID exists in `profiles`, the user is authenticated.

