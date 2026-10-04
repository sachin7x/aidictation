# India billing

The native app already contains Stripe and AppSumo paths. The platform now adds a provider-neutral billing event boundary plus a Razorpay webhook adapter for an India launch.

The webhook stores verified events server-side. It does not trust client-reported payment state. A production rollout still requires configuring Razorpay products/plans, webhook secret, tax/accounting, refund/cancellation mappings, and the exact entitlement keys used by the native clients.
