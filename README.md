# Nambon Tiger TV site setup

The site stays hosted on GitHub Pages. Supabase's free tier provides the database and owner authentication.

## Backend setup

1. Create a Supabase project on the free tier.
2. In Supabase SQL Editor, run the entire `supabase-schema.sql` file.
3. In Authentication > Users, create the owner's login. Disable public sign-ups in Authentication settings. Do not use a service-role key in the website.
4. Copy the owner's auth user UUID, then run `insert into public.admin_users (user_id) values ('OWNER_AUTH_USER_UUID');` in SQL Editor, replacing the example with that UUID.
5. In the `index.html` browser console on the site, set the project URL and publishable anon key once on the owner's browser:

```js
localStorage.setItem('nttv_supabase_config', JSON.stringify({url:'https://YOUR_PROJECT_REF.supabase.co',key:'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY'}));
location.reload();
```

Use the Project URL and publishable (or legacy anon) key from Supabase Project Settings > API. These public client credentials are intended to be exposed in browser apps; access is restricted by the row-level security policies in `supabase-schema.sql`. Never place a service-role key in GitHub Pages or share it publicly. Because the configuration lives in the owner's browser storage, repeat this setup in each browser that needs to administer the site; visitors need their own config to use the online forms and live counter. For a one-time public site-wide setup, add the project URL and public anon key to the page's `CONFIG` constant in `index.html` before publishing.

## Features

- Contact messages are inserted into the private `contact_messages` table. Only an authenticated owner account can read them.
- The public follower count comes from `site_stats` and defaults to the last provided count, 102. Owner can update it from the admin panel.
- Ad requests enter as `pending`; only the owner can read/manage requests or change their status. The public page only displays approved ads.
- Payment instructions are intentionally sent directly by the owner only after review. The site does not accept or claim to verify bank transfers. Confirm payment before publishing an approved ad.

## Publishing

Commit `index.html`, `supabase-schema.sql`, and this README to the `main` branch of `NAMBONTIGER/nambon-tiger-tv`. GitHub Pages serves the repository root.
