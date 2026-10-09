# Activity 09 Evidence Status

`analysis_output.txt` records a clean static-analysis run.

T1 is recorded in `T1_before.png`: before the Activity 09 upgrade, the installed Part I app showed three preserved fictional roster rows: River (ID 2, age 35), Acorn (ID 3, age 0), and Oak (ID 4, age 130). The same installed package was then updated in place to Activity 09, which opened its version-2 folder screen without clearing the Part I database.

T2 is recorded in `T2_cards.png`: Folder PracticeOne contained two database-generated card IDs, 1 and 2. Card ID 2 has a null image reference and visibly uses the suit-symbol fallback.

T3, T4, T5, and T6 remain unverified in the repository. The emulator disconnected during the remaining walkthrough, so no screenshot is presented as proof for an unrun observation.
