# City Furniture OMS QA Automation

End-to-end test automation for the IBM Sterling Order Management System (OMS).

This repository contains Robot Framework test suites, XML data templates, and reporting utilities. It uses real OMS API calls over mTLS, processes request/response XML pairs, and validates structured business outcomes.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Environment Configuration](#environment-configuration)
- [Running Tests](#running-tests)
  - [Single Test Case](#single-test-case)
  - [All Test Cases (Full Suite)](#all-test-cases-full-suite)
  - [Parallel Execution](#parallel-execution)
- [Reports](#reports)
  - [Built-in Robot Report](#built-in-robot-report)
  - [Custom HTML Report](#custom-html-report)
  - [Allure Report](#allure-report)
- [Test Data](#test-data)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Python | 3.9+ | [python.org](https://www.python.org/downloads/) |
| Robot Framework | 7.1.1 | `pip install robotframework==7.1.1` |
| pip dependencies | see below | `pip install -r requirements.txt` |
| Bob IDE | latest | internal distribution |
| Allure CLI *(optional)* | any | `scoop install allure` (Windows) |

### Install all Python dependencies

```bash
cd qa-automation

# If requirements.txt is UTF-16 encoded (common on Windows), convert it first:
iconv -f UTF-16 -t UTF-8 requirements.txt > requirements_utf8.txt
pip install -r requirements_utf8.txt

# If pip still fails, recreate it in the active environment:
# pip freeze > requirements.txt
pip install -r requirements.txt
```

> **Note:** The bundled requirements.txt may be UTF-16 encoded. Convert to UTF-8 if pip install throws encoding or parse errors.

### Client Certificate (required for DEV / QA environments)

The OMS endpoints use mutual TLS. Place your .p12 certificate at the path defined in  
[`Library/Scripts/env_variables.py`](Library/Scripts/env_variables.py) under CERTlOCATION.

```python
# Example DEV path
"CERTlOCATION": "/Users/sakshimaurya/Testing_v2.0/owner=jeevitha.p12",

# Example QA path
"CERTlOCATION": "C://CITY//AppManager_26.2//owner=jeevitha-qa.p12",
```

Update the path and CERTPASSWORD to match your local certificate before running any tests.

---

## Repository Structure

```
qa-automation/
├── Library/
│   ├── Robots/
│   │   ├── keywords.robot          ← Reusable Robot keywords (suite processing, XML send/compare, session)
│   │   ├── test.robot              ← Core test execution keywords
│   │   └── variables.robot         ← Global Robot variables
│   └── Scripts/
│       ├── env_variables.py        ← Environment configuration (DEV / QA / FyreSan URLs, certs)
│       ├── sessionUtils.py         ← mTLS session creation
│       ├── certificates.py         ← .p12 extraction utilities
│       ├── generateBearerToken.py  ← OAuth token retrieval
│       ├── XmlCompare.py           ← XML diff helpers
│       ├── XmlUtils.py             ← XML read/write utilities
│       ├── prepare_content.py      ← JSON/XML file helpers
│       ├── generateRandomNumberAndReplaceAllXMLS.py  ← ID randomization
│       └── read.py                 ← CSV append helper
│
├── Scripts/
│   ├── Test.robot                  ← Template copied into every generated TC folder
│   ├── Test1.robot                 ← Top-level suite runner (discovers Test_Cases/)
│   └── generate_custom_report.py   ← Parses output.xml → IBM Carbon HTML report
│
├── baseline_data/
│   ├── createOrder/
│   │   ├── input.xml
│   │   ├── get*_ValidateData.xml
│   │   └── expectedResult.xml
│   ├── getOrderReleaseList/
│   └── ... (one subfolder per API)
│
├── Test_Cases/
│   ├── Test1.robot                 ← Top-level suite file
│   ├── TC_<timestamp>_001/
│   │   ├── Test.robot              ← Executed test script
│   │   └── Data/
│   │       ├── Input/              ← Raw request XMLs
│   │       ├── Setup/              ← Setup request XMLs
│   │       ├── ExpectedResult/     ← Expected response XMLs
│   │       ├── ActualResult/       ← Actual response XMLs (generated)
│   │       ├── updated_input/      ← Randomized input XMLs (generated)
│   │       └── updated_setup/      ← Randomized setup XMLs (generated)
│   └── TC_<timestamp>_002/ ...
│
├── report_templates/
│   └── template.html               ← Custom HTML report (IBM Carbon Design)
│
├── Samples/
│   ├── CertificateValidate/
│   ├── DesignDemo/
│   ├── orderFulfillment/
│   └── utilTest/
│
├── requirements.txt
├── environment.properties
└── README.md
```

---

## Running Tests

### Prerequisite check

```bash
python3 --version   # Python 3.9+
robot --version     # Robot Framework 7.1.1
```

### Single Test Case

Navigate to the test case folder and run the local `Test.robot` file:

```bash
cd Test_Cases/TC_20260627_044012_001
robot Test.robot
```

Artifacts are generated in-place:
- `output.xml`
- `log.html`
- `report.html`

### All Test Cases (Full Suite)

From the repository root, run the top-level `Test1.robot` which loops through every subfolder under `Test_Cases/`:

```bash
cd qa-automation
robot Scripts/Test1.robot
```

### Parallel Execution

Use `pabot` (included in `requirements.txt`) to run test cases in parallel:

```bash
cd qa-automation
pabot --processes 5 Scripts/Test1.robot
```

---

## Reports

### Built-in Robot Report

After execution, open the standard Robot Framework report:

```bash
# From the TC folder
start log.html   # Windows
open log.html    # macOS
```

Or from the CLI:

```bash
robot --output output.xml --log log.html --report report.html Scripts/Test1.robot
```

### Custom HTML Report

Generate the IBM Carbon-styled HTML report after the suite finishes:

```bash
# Entire suite
python3 Scripts/generate_custom_report.py

# Single test case
python3 Scripts/generate_custom_report.py Test_Cases/TC_20260627_044012_001
```

Open `report.html` in the target folder to view results.

### Allure Report

```bash
allure serve <path-to-output-folder>
```

Example for a single test case:

```bash
allure serve Test_Cases/TC_20260627_044012_001
```

---

## Test Data

- **`baseline_data/`** — Raw XML templates organized by API (e.g., `createOrder`, `getOrderReleaseList`). Each folder contains:
  - `input.xml` — Base request payload
  - `get*_ValidateData.xml` — Validation data for the request
  - `expectedResult.xml` — Expected API response

- **`Test_Cases/<TC_ID>/Data/`** — Runtime working directory for a generated test case:
  - `Input/` and `Setup/` are populated from `baseline_data/` during test generation.
  - `updated_input/` and `updated_setup/` contain randomized IDs substituted at runtime.
  - `ActualResult/` captures live API responses.
  - `ExpectedResult/` contains the validation XMLs.

Use the online Test Case Generator (or Bob workflow) to convert design documents into `Test_Cases/` folders. This repo focuses on the backend execution engine.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `pip install` fails with encoding errors | `requirements.txt` is UTF-16 | Convert to UTF-8 with `iconv` or run `pip freeze > requirements.txt` |
| `SSLError` / `ConnectionError` | Certificate not found or wrong path | Update `CERTlOCATION` and `CERTPASSWORD` in `env_variables.py` |
| `Status Should Be 200 – got 401` | Wrong credentials | Check `USERNAME` / `PASSWORD` in `env_variables.py` |
| `File not found: updated_files.json` | `process_suite` was not called | Ensure each TC folder has both `Data/Input/` and `Data/Setup/` sub-directories |
| `KeyError` in `process_suite` | `baseline_data/` subfolder missing `input.xml` | Add the missing file to the correct `baseline_data/<API>/` folder |
| `output.xml not found` when running `generate_custom_report.py` | Tests were not executed yet | Run `robot Test.robot` before the report script |
| `template.html not found` | Script run from wrong directory | Run the script from the repo root or pass an absolute path |
| `Failed to condense context` in Bob | Read range too large | Bob auto-retries with 300-line chunks; no action needed |
| API names in generated files don't match `baseline_data/` folders | Mapping sheet spelling differs | Use the mapping sheet's exact API name spelling, or rename the `baseline_data/` subfolder to match |

---

## Key Files Reference

| File | Purpose |
|---|---|
| [`Library/Scripts/env_variables.py`](Library/Scripts/env_variables.py) | Environment config (DEV / QA / FyreSan URLs and certs) |
| [`Library/Robots/keywords.robot`](Library/Robots/keywords.robot) | All reusable robot keywords (session, XML compare, order lifecycle) |
| [`Library/Robots/variables.robot`](Library/Robots/variables.robot) | Global Robot variables |
| [`Scripts/Test.robot`](Scripts/Test.robot) | Test template copied into every generated TC folder |
| [`Scripts/Test1.robot`](Scripts/Test1.robot) | Top-level suite file that runs all test cases |
| [`Scripts/generate_custom_report.py`](Scripts/generate_custom_report.py) | Parses `output.xml` and renders IBM Carbon HTML report |
| [`report_templates/template.html`](report_templates/template.html) | IBM Carbon HTML template with `{{PLACEHOLDER}}` tokens |
