[2026-04-06 16:05] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "stats layout change",
    "EXPECTATION": "Show all stat overview cards visible at once in a single place, no drag/scroll, while keeping the new style design.",
    "NEW INSTRUCTION": "WHEN implementing stats overview THEN show all stat cards without scrolling"
}

[2026-04-06 16:17] - Updated by Junie
{
    "TYPE": "positive",
    "CATEGORY": "design consistency",
    "EXPECTATION": "User likes the new modern style and wants it applied across all admin pages.",
    "NEW INSTRUCTION": "WHEN updating any admin page THEN apply the new modern homepage/admin style"
}

[2026-04-06 17:08] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "invalid icon constant",
    "EXPECTATION": "Use only valid Flutter Material Icons; avoid non-existent names like price_settings_new_rounded.",
    "NEW INSTRUCTION": "WHEN selecting a Material icon THEN verify the constant exists in current Flutter SDK"
}

[2026-04-07 10:27] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "security - admin registration",
    "EXPECTATION": "Remove the admin registration API/endpoint to avoid security risks.",
    "NEW INSTRUCTION": "WHEN designing admin user creation THEN do not expose admin registration endpoint; use manual database seeding"
}

[2026-04-07 10:28] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "security - admin registration",
    "EXPECTATION": "Remove the admin registration API/endpoint to prevent public admin creation.",
    "NEW INSTRUCTION": "WHEN designing admin user creation THEN do not expose admin registration endpoint; use manual database seeding"
}

[2026-04-07 10:29] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "security - admin registration",
    "EXPECTATION": "Remove the admin registration API/endpoint to avoid security risks.",
    "NEW INSTRUCTION": "WHEN handling admin account creation THEN do not expose registration endpoint; seed admin manually"
}

[2026-04-07 10:30] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "security - admin registration",
    "EXPECTATION": "Remove the public admin registration API/endpoint and avoid allowing admin self-registration.",
    "NEW INSTRUCTION": "WHEN handling admin account creation THEN do not expose registration endpoint; seed admin manually"
}

[2026-04-07 10:31] - Updated by Junie
{
    "TYPE": "preference",
    "CATEGORY": "admin setup policy",
    "EXPECTATION": "The setup admin endpoint should allow creating only one admin and block further creations, so it can remain enabled.",
    "NEW INSTRUCTION": "WHEN implementing /api/setup/admin THEN allow single admin creation and block thereafter"
}

[2026-04-07 11:35] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "card navigation",
    "EXPECTATION": "Clicking a card item should navigate to the same unique details page used from the Buy/Sell flow’s buyer list icon.",
    "NEW INSTRUCTION": "WHEN tapping a card item THEN navigate to the existing buyer details page"
}

[2026-04-07 11:40] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "customer card navigation",
    "EXPECTATION": "Tapping a customer card should open the existing customer details page; no separate details icon is needed.",
    "NEW INSTRUCTION": "WHEN showing customer list cards THEN make entire card tappable and remove details icon"
}

[2026-04-07 11:58] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "navigation on tap",
    "EXPECTATION": "Clicking an item should navigate to the appropriate details page instead of only updating frontend state.",
    "NEW INSTRUCTION": "WHEN tapping any item card THEN navigate to existing details route for that item"
}

[2026-04-07 12:02] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "customer header and icons",
    "EXPECTATION": "Restore the green top background on the customer page and remove the duplicate icon so only one remains.",
    "NEW INSTRUCTION": "WHEN modifying customer page UI THEN retain green top background and remove duplicate icons"
}

[2026-04-07 12:02] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "customer page UI",
    "EXPECTATION": "Keep the green top background on the customer page and remove the duplicate icon so only one remains.",
    "NEW INSTRUCTION": "WHEN modifying customer page UI THEN retain green top background and remove duplicate icons"
}

[2026-04-07 17:15] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "prices page data",
    "EXPECTATION": "The Prices page should show the hardcoded demo market prices instead of appearing empty.",
    "NEW INSTRUCTION": "WHEN price page loads without backend data THEN display predefined hardcoded mock prices"
}

[2026-04-07 17:20] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "undefined types in code",
    "EXPECTATION": "Avoid introducing non-existent classes; use or define models before referencing them (e.g., reuse existing PaddyRicePriceModel and define a district wrapper or adapt UI to existing structures).",
    "NEW INSTRUCTION": "WHEN introducing a new Dart type THEN define it or reuse an existing model"
}

[2026-04-07 17:21] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "undefined types compile errors",
    "EXPECTATION": "Avoid introducing undefined types; reuse existing PaddyRicePriceModel and define any new wrappers before referencing them.",
    "NEW INSTRUCTION": "WHEN adding district price lists THEN use Map<String,List<PaddyRicePriceModel>> or define model"
}

[2026-04-07 19:10] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "missing dependency",
    "EXPECTATION": "The video banner should compile by properly adding and configuring the video_player package.",
    "NEW INSTRUCTION": "WHEN using video_player THEN add it to pubspec and run flutter pub get"
}

[2026-04-08 12:02] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "header layout and buttons",
    "EXPECTATION": "Use a compact top section like other pages: show only a back button, the customer name, and two action buttons; remove the three big buttons that take space, keep the red button but place it neatly; ensure mobile responsiveness.",
    "NEW INSTRUCTION": "WHEN designing page header on mobile THEN use compact header with back button, name, two actions"
}

