# CareLoop Clinics — No-Show Guard

**Public GitHub repository:** `(https://github.com/mdritesh07-sudo/CAPSTONE-PROJECT)`

> Replace the placeholder above with your public GitHub URL before submission. Never publish an API key, password, or other secret.

## Project overview

CareLoop Clinics operates eight outpatient clinics across six Indian cities. This end-to-end project cleans appointment data, verifies business patterns with SQL, predicts no-show risk with machine learning, and extracts structured reasons from patient follow-up notes with Gemini.

**Business question:** Which appointments are most likely to be missed, why do patients miss them, and what should CareLoop do first?

The risk score is intended to be generated on the evening before an appointment, after reminders have been sent or skipped, so the front desk can contact high-risk patients in time.

## Four-part project summary

- **Part 1 — Data foundations:** Cleaned the 1,020-row raw export to **990 records**; the final dataset contains **218 no-shows (22.0%)** and 16 columns.
- **Part 2 — SQL analysis:** Verified **990 appointments and 218 no-shows**; the **31+ day** booking-lead group had a **60.5%** no-show rate, while Gomti Nagar Care Point recorded **33.3%** from 90 appointments.
- **Part 3 — Machine learning:** Selected **Logistic Regression** using training cross-validation (ROC-AUC **0.7988**) and chose a **0.35** threshold; on the 198-row test set, ROC-AUC was **0.7528** and recall was **0.5682**.
- **Part 4 — GenAI follow-up analysis:** Processed the first **10** notes, with **9 valid analyses** and blank note N004 skipped; both **2/2** `forgot_or_no_reminder` cases had `reminder_sent = No`.

## Methods and results

### Part 1 — Python data foundations

The raw appointment export was inspected and cleaned in a reproducible sequence. Exact duplicates, inconsistent booking-channel labels, unreadable dates, missing statuses, invalid ages, missing values and outliers were handled according to the project brief. Clinic records were enriched with the Open-Meteo API, and the cleaned appointment and clinic tables were exported for downstream work.

Key results:

- Raw appointments: **1,020 rows**.
- Final cleaned appointments: **990 rows × 16 columns**.
- Duplicate rows removed: **20**.
- Final no-show count: **218 / 990 (22.0%)**.
- `appointment_id` is unique and the final 16-column export has no missing values.

### Part 2 — SQL business analysis

The cleaned data was loaded into relational `clinics` and `appointments` tables. SQL queries used joins, aggregation, `CASE WHEN`, a CTE, `LAG()` and `RANK()` to verify the Python results and identify patterns by clinic, booking lead time and month.

Selected findings:

- SQL totals: **990 appointments** and **218 no-shows**, matching Part 1.
- Bookings made **31+ days** ahead had a **60.5%** no-show rate (26 no-shows from 43 appointments).
- Gomti Nagar Care Point had a **33.3%** no-show rate, but only **90 appointments**; interpret this smaller sample cautiously.
- Overall no-show rate: approximately **22.02%**.

### Part 3 — Machine learning

The target was `no_show`. Features included age, distance, fee, lead time, prior no-shows, reminder status and one-hot-encoded booking channel and visit type. The split used `test_size=0.2` and `random_state=42`. The test set was reserved for final reporting, not model or threshold selection.

Logistic Regression was selected because it achieved the highest cross-validated training ROC-AUC among the compared candidates (**0.7988**). A threshold of **0.35** was selected using out-of-fold training probabilities to improve the precision/recall balance, with particular attention to recall.

Final test-set results at threshold 0.35:

| Metric | Result |
|---|---:|
| Test samples | 198 |
| Accuracy | 0.7677 |
| Precision | 0.4808 |
| Recall | 0.5682 |
| F1 score | 0.5208 |
| ROC-AUC | 0.7528 |

Confusion matrix (actual rows: attended / no-show; predicted columns: attended / no-show):

```text
[[127, 27],
 [ 19, 25]]
```

The model identifies a useful share of no-shows, but predictions should support—not replace—front-desk judgement. The threshold should be reviewed against the clinic's available call capacity.

### Part 4 — GenAI follow-up analysis

The Gemini API converted the first 10 call-centre notes into structured fields: `root_cause`, `confidence`, `summary` and `recommended_action`. JSON output was validated with Pydantic, deliberately invalid responses were tested, and a CRAFT prompt was compared with a simple V1 prompt on N007 and N009.

Selected results from the completed work:

- Notes processed: **10**; non-blank analyses: **9**; blank note N004 was skipped without an API call.
- Root-cause counts shown: `forgot_or_no_reminder` **2**, `distance_or_transport` **2**, `other` **2**, `work_or_schedule` **2**, `cost_or_fee` **1**, `illness_or_emergency` **1**.
- Reminder cross-tab: **5 of 10** notes were linked to appointments with `reminder_sent = No`; both `forgot_or_no_reminder` notes (**2 of 2**) were in the `No` reminder group.
- In the two-note V1/V2 comparison (N007 and N009), root-cause agreement was **100%** and average confidence was **0.965**. V2 produced more detailed summaries and recommended actions. This two-note comparison does not establish overall prompt superiority.

## Business recommendation

CareLoop should pilot an evening-before call list using Logistic Regression risk probabilities and the selected **0.35** threshold, then adjust the threshold to match the number of calls staff can realistically make. The model achieved **0.7528 test ROC-AUC** and **0.5682 recall** on **198** held-out appointments, so it can help prioritize outreach but will still miss some no-shows and flag some patients who attend. The SQL analysis suggests prioritizing bookings made **31+ days** ahead, where the observed no-show rate was **60.5%**, while treating the **33.3%** Gomti Nagar rate cautiously because it is based on only **90** appointments. The cleaned dataset contains **990** bookings and **218 no-shows (22.0%)**, providing the baseline for monitoring. The GenAI review found **2 of 2** `forgot_or_no_reminder` notes in the no-reminder group; therefore, the clinic should audit reminder delivery and contact details while offering practical alternatives for transport, cost and scheduling barriers identified in the notes. Track contact attempts, successful rescheduling and subsequent no-show rates before expanding the pilot.

## Limitations

1. The GenAI review uses only the first **10** follow-up notes. These examples cannot establish the true clinic-wide distribution of reasons for missed appointments.
2. Cleaning medians, quartiles and outlier fences were calculated on all 990 rows before the train/test split. Test rows therefore had a small indirect influence on cleaning; in production these statistics should be fitted on training data only.
3. A random split can place bookings from the same patient in both training and test sets, and it does not reproduce a real past-to-future deployment. Patient-grouped, time-based validation would provide a stronger estimate of future performance.

## Repository contents

The submitted public repository should contain:

```text
.
├── 01_ingest_clean.ipynb
├── rejected_rows.json
├── appointments_clean.csv
├── clinics_enriched.csv
├── load_data.sql
├── 02_queries.sql
├── 03_model.ipynb
├── test_risk_scores.csv
├── 04_genai.ipynb
├── notes_analysed.csv
├── README.md
└── data/
    ├── appointments.csv
    ├── clinics.csv
    └── followup_notes.csv
```

## Reproducibility and security

- Keep the three original files unchanged in `data/`.
- Run the notebooks in order: `01_ingest_clean.ipynb`, `02_queries.sql` in the SQL environment, `03_model.ipynb`, then `04_genai.ipynb`.
- Install the Python libraries used in the notebooks in the active Colab runtime.
- Enter the Gemini API key at runtime only. Never hard-code it in a notebook or commit it to GitHub.
- Before submission, search the entire repository and notebook contents for the API key, remove any key-bearing cell output, and rotate/revoke any key that may have been exposed.
- Confirm that the GitHub repository is **public** and every required submission file is present.

## Tools and libraries

Python, Google Colab, pandas, NumPy, scikit-learn, Matplotlib/Seaborn, Pydantic, Google GenAI SDK, MySQL 8 / SQLite-compatible SQL, and the Open-Meteo API.
