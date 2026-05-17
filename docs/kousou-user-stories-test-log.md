# Kousou User Stories And Test Log

## Stories

1. First launch compliance
   - As a first-time user, I see a modal that requires agreement to both privacy policy and service agreement before entering the app.
   - I can open both agreement pages from the modal.

2. Home and manual accounting
   - As a logged-in user, I can see today's total spending and income.
   - I can create an expense record and return to Home with today's total refreshed.
   - The record is stored locally and submitted to the service when the app token exists.

3. Smart text accounting
   - As a user, I can type a short text with an amount, tap Parse Text, see the parsed amount on the keyboard, and save the record.
   - Home refreshes after saving.

4. Receipt image recognition
   - As a logged-in user, I can tap Recognize Image, pick a photo, and return to the app.
   - The app calls the server receipt recognition endpoint and either shows recognized items or a clear recognized/fallback text without crashing.

5. Statistics
   - As a user, I can open Statistics and see monthly totals, balance, record count, and category ranking.
   - I can tap AI Statistics Advice and receive advice from the server.

6. Wishlist
   - As a user, I can create a goal, generate a savings plan, and request AI analysis.

7. Settings and hidden debug settings
   - As a user, I can open privacy policy and service agreement from Settings.
   - As a tester, I can tap the version number six times to reveal the hidden server host setting.

## Issues Found And Fixed

1. Home action buttons overlapped the Home Scroll hit area.
   - Symptom: center taps on Recognize Image or Parse Text could be consumed by the Scroll.
   - Fix: constrained the Home page builder into a weighted Column and made the Home Scroll fill its parent.
   - Files: `entry/src/main/ets/pages/Index.ets`, `entry/src/main/ets/pages/components/Home.ets`.

2. Parsed amount did not appear on the keyboard.
   - Symptom: Parse Text navigated to the accounting page, but the keyboard still displayed `0`.
   - Fix: synced `parsedAmount` into `totalValue` on keyboard appearance and on link changes; save now uses the visible keyboard value.
   - File: `entry/src/main/ets/pages/components/MyKeyboard.ets`.

3. Statistics AI endpoint returned 405.
   - Symptom: app POST to `/v1/kousou/statistics/analyze` returned `RespCode:405`.
   - Root cause: server `analyze_statistics()` reused the GET-only `statistics(request)` view with a POST request.
   - Fix: extracted shared statistics payload calculation and reused it from both views.
   - Files: `/Users/caoxiaopeng/DevEcoStudioProjects/bitstripe/kousou/views.py`, `/Users/caoxiaopeng/DevEcoStudioProjects/bitstripe/kousou/tests.py`.

## Verification Evidence

1. Build
   - Command: `/Users/caoxiaopeng/service/command-line-tools/bin/hvigorw --mode module -p module=entry assembleHap --no-daemon`
   - Result: `BUILD SUCCESSFUL`.

2. Device connection
   - Device: `192.168.1.116:41885`
   - HDC shell, app launch, `uitest dumpLayout`, and `uitest screenCap` all succeeded.

3. Layout overlap retest
   - Recognize Image button bounds: `[277,597][530,699]`.
   - Parse Text button bounds: `[554,597][807,699]`.
   - Home Scroll bounds: `[0,735][1084,2124]`.
   - Result: button center taps no longer overlap Scroll.

4. Receipt OCR retest
   - Center tap on Recognize Image opened the system photo picker.
   - Selecting a photo and tapping Complete returned to Home.
   - App log: receipt recognition POST returned `RespCode:200`.
   - UI showed recognized fallback text for a non-receipt screenshot.

5. Smart text accounting retest
   - Input: `coffee20`.
   - After Parse Text, keyboard displayed `20`.
   - After Complete, server record POST returned `RespCode:200`.
   - Home displayed `今日支出 ¥122`, up from `¥102`.

6. Statistics AI retest
   - Before fix: app POST returned `RespCode:405`.
   - After server deploy: app POST returned `RespCode:200`.
   - UI displayed 4 AI advice items.

7. Server tests and deploy
   - Local command: `BITSTRIPE_USE_SQLITE=1 .venv/bin/python manage.py test kousou`.
   - Result: `Ran 6 tests ... OK`.
   - Remote deployed commit: `035d21f Fix kousou statistics analysis endpoint`.
   - Remote `manage.py check`: no issues.
   - `bitstripe.service`: active after restart.
