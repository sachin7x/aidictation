# Website

The web/ application is the launch website and authenticated control plane.

It currently provides:
- marketing surfaces: home, features, pricing, download, developers, security, privacy, terms;
- passwordless Supabase authentication;
- protected workspace;
- dictionary and snippet views;
- transform UI;
- meeting/Notetaker product surface;
- authenticated sync API;
- India billing webhook boundary.

Branding remains centralized in web/src/config/brand.ts, so the product name, logo, colors, downloads and pricing can be changed without rewriting page components.
