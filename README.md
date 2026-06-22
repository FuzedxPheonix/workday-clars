# Workday Studio Starter Kits

A growing collection of Workday Studio `.clar` files built from scratch as learning resources and community contributions. This repo is updated on an ongoing basis as new integrations are built. These are **not production-ready solutions** — they are starter kits to help you understand patterns and accelerate your own builds.

---

## Files

| File | Description | Last Updated |
|------|-------------|--------------|
| `INT_Aladtech.clar` | REST API integration between Workday and Aladtec for time-off data | 2026 |
| `INT_Aladtec_TimeOff_Import_Example.clar` | Aladtec time off import into Workday with overnight shift handling and worker hashmap | 2026 |
| `INT_Aladtec_Import_Accrual_Banks_Example.clar` | Pulls Workday time off balances and syncs them to Aladtec accrual banks | 2026 |
| `INT_ADP_Oauth_Example.clar` | ADP Workforce Now OAuth 2.0 integration with worker data retrieval | 2026 |
| `INT_ADP_Upload_Worker_Image_Example.clar` | ADP worker photo upload via multipart/form-data with Groovy binary handling | 2026 |
| `INT_EIB_File_Router.clar` | EIB output file renaming by schedule type (monthly/weekly) without cloning | 2026 |
| `INT_NewHire_VendorSync.clar` | New hire worker data + photo sync to vendor via SFTP — AI-assisted build | 2026 |
|`INT_UKG_Import_Abscense_Accrual_Deductions.clar` | UKG File Format to Add/Deduct Accruals Example| 2026 |
|`INT_File_Watcher_Example.clar` | Light Weight Starterkit for a integration Watcher| 2026 |
|`INT_Fixed_Width_File_Inbound_Example.clar` | An Example of Fixed Width File to Process One Time Payment| 2026 |
|`INT_Zendesk_API_Ticket.clar` | A Starterkit for Zendesk API to Create a Ticket for laptop request| 2026 |
|`INT_Onboarding_Task_AI_RPT.clar` | A Starterkit Example on Using Claude AI to Generate Onboarding RPT| 2026 |
| `INT_PII_Claude_Get_Workers.clar` | AI-powered worker PII anonymization and Claude analysis with HashMap masking and leave status extraction | 2026 |
| `INT_SupOrg_Data_AI_Review.clar` | AI-powered Claude analysis to Confirm if Data is Ready for AI Consumption| 2026 |
| `INT_AI_Audit_Integrations.clar` | AI-powered Claude analysis to Review Integration API calls Audit| 2026 |
|`INT_AI_Yes_No_Compliance_Check.clar` | AI-powered preferred name compliance validator using Claude — loops per worker, sends policy and executive list to Claude, returns YES/NO decision per worker in an aggregated HTML report | 2026 |

---

## Aladtec Time-Off Integration (Starter Kit)

### Overview
This starter kit demonstrates how to connect Workday Studio to the Aladtec REST API to retrieve member and time-off data.

### What's Included
- OAuth 2.0 token flow (client credentials grant)
- REST API calls with Bearer token authentication
- Member data retrieval with HashMap storage
- Time-off data retrieval with date range parameters (`start_time` / `end_time` launch parameters)
- Splitter pattern for iterating through records
- Basic error handling and cloud logging

### What's NOT Included (still needed for production)
- Aggregator/join step after splitters
- Final routing connections between all steps
- XSLT transforms for Workday inbound processing
- Full error notifications and alerting
- Data validation and reconciliation logic

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Authentication | `grant_type` | OAuth grant type (e.g. `client_credentials`) |
| Authentication | `client_id` | Aladtec API client ID |
| Authentication | `client_secret` | Aladtec API client secret |
| Authentication | `end_point` | Aladtec base API URL |

### Launch Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `start_time` | datetime | Start of the time-off date range |
| `end_time` | datetime | End of the time-off date range |

### Flow Overview
```
Start → InitialSetup → OAuth Token Request → Get Members → Split Members → Build HashMap
     → Get Time-Off Records → Split Time-Off Records → [your logic here]
```

---

## Aladtec Time-Off Import Integration

### Overview
This integration pulls approved time off records from the Aladtec REST API and submits them into Workday using the `Enter_Time_Off` operation under the `Absence_Management` web service (v46.0). It is designed to be generic and configurable for any organization using Aladtec as their scheduling system and Workday as their HCM.

### What's Included
- OAuth 2.0 token flow (client credentials grant)
- Member data retrieval with HashMap storage keyed by `member_id`
- Configurable custom attribute lookup to resolve Workday Employee ID
- Time off retrieval with date range launch parameters
- Overnight shift detection and date handling via `extends_before` / `extends_after` flags
- Integration map for Aladtec to Workday time off type mapping
- XSLT transform (`WWSEnterTimeOff.xsl`) for Workday SOAP payload construction
- Individual `Enter_Time_Off` submission per record via `Absence_Management` v46.0
- Cloud logging on hashmap creation, worker submission, and integration completion
- Error handling on OAuth, Members API, and Time Off API steps

### What's NOT Included (still needed for production)
- Per-record granular logging with `time_off_id` for full traceability
- Enhanced error routing to isolate and retry individual failed records
- Complex or conditional time off type mapping beyond 1:1 integration map
- Overnight merge logic — overnight shifts are submitted as split daily entries per `daily_split_date`. If a single merged Workday entry is required, an aggregator step would need to be added before the XSLT step
- Active member filtering — hashmap currently loads all members regardless of `is_active` status
- `pto_hours` submission — field is extracted but not currently passed to Workday. If your absence type requires hours-based entry, the XSLT `Requested` field would need to be populated

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Authentication | `grant_type` | OAuth grant type (e.g. `client_credentials`) |
| Authentication | `client_id` | Aladtec API client ID |
| Authentication | `client_secret` | Aladtec API client secret (stored as password) |
| Authentication | `end_point` | Aladtec base API URL |
| Configuration | `custom_attribute` | Aladtec custom attribute ID storing the Workday Employee ID |

### Integration Map
| Map Name | External (Aladtec) | Internal (Workday) |
|----------|-------------------|-------------------|
| `Time_Off_Types` | `Sick Leave` | `SICK` |
| `Time_Off_Types` | `Vacation` | `VAC` |

> Configure this map to match your organization's Aladtec time off types to Workday Time Off Type Reference IDs.

### Launch Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `start_time` | datetime | Start of the time off pull window |
| `end_time` | datetime | End of the time off pull window |

### Overnight Shift Handling
Aladtec splits overnight records by `daily_split_date` and provides `extends_before` and `extends_after` flags. This integration handles overnight shifts as follows:

- `extends_before = true` → `Start_Time` is set to `00:00:00` (shift started on a prior day)
- `extends_after = true` → `End_Time` is capped at `23:59:59` (shift continues into the next day)
- Both false → actual start/stop times are used as-is

> **Note:** This integration submits one Workday time off entry per `daily_split_date` record. Aladtec handles the date splitting — no additional merge logic is applied. If your organization requires overnight shifts to be submitted as a single merged entry in Workday, additional aggregation logic would be needed before the XSLT step.

### XSLT
**File:** `WWSEnterTimeOff.xsl`
Transforms the Aladtec time off record into a Workday `Enter_Time_Off_Request` SOAP payload. Accepts the following parameters from props:

- `member_id` (resolved from hashmap to Workday Employee ID)
- `daily_split_date`
- `time_off_type` (mapped via integration map)
- `start_datetime`
- `stop_datetime`
- `extends_before`
- `extends_after`

### Flow Overview
```
Start → Init (attributes + params) → OAuth Token Request → Extract Bearer Token
     → Get Members → JSON to XML → Split Members → Build Worker HashMap
     → Get Time-Off Records → JSON to XML → Split by daily_split_date
     → Split by time_record → Resolve Worker ID → XSLT Transform
     → Enter_Time_Off (Workday SOAP) → Log Submission
     → Integration Complete
```

---

## Aladtec Accrual Bank Balance Sync

### Overview
This integration pulls time off plan balances from Workday for each active member and syncs them to Aladtec's accrual bank balances via a PUT to the Aladtec REST API. It is designed to keep Aladtec's accrual banks current with what Workday holds as the system of record for time off balances.

### What's Included
- OAuth 2.0 token flow (client credentials grant)
- Member data retrieval with HashMap storage keyed by `member_id`
- Configurable custom attribute lookup to resolve Workday Employee ID
- `Get_Time_Off_Plan_Balances` SOAP call per worker via `Absence_Management` v46.0
- Balance HashMap storage keyed by `member_id` for aggregation
- Aggregator pattern to collect all balances into a single JSON payload
- XML to JSON conversion for Aladtec PUT request body
- PUT to Aladtec `/accrual-banks/balances` endpoint
- Response logging per member with hours and accrual bank ID
- Cloud log audit trail stored at integration completion
- Error handling on OAuth, Members API, and Workday WWS steps

### What's NOT Included (still needed for production)
- Active member filtering — hashmap currently loads all members regardless of `is_active` status
- Multi-position balance handling — if a worker has multiple positions each with their own balance, the integration takes the first balance returned. Summing or selecting by position would need additional logic
- Multiple time off plan support — currently configured for one plan per run via the `time_off_plan` attribute. Multiple plans would require looping or separate integration runs
- Full error notifications and alerting per record
- Retry logic on failed PUT to Aladtec

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Authentication | `grant_type` | OAuth grant type (e.g. `client_credentials`) |
| Authentication | `client_id` | Aladtec API client ID |
| Authentication | `client_secret` | Aladtec API client secret (stored as password) |
| Authentication | `end_point` | Aladtec base API URL |
| Configuration | `custom_attribute` | Aladtec custom attribute ID storing the Workday Employee ID |
| Configuration | `time_off_plan` | Workday Time Off Plan ID to pull balances from |
| Configuration | `aladtech_accrual_bank` | Aladtec accrual bank ID to sync balances to |

### Aladtec PUT Payload
Each member entry in the payload sent to Aladtec:
```json
[
  {
    "member_id": 18,
    "accrual_bank_id": 1,
    "hours": 40.5
  },
  {
    "member_id": 24,
    "accrual_bank_id": 1,
    "hours": 32.0
  }
]
```

### Flow Overview
```
Start → Init (attributes + params) → OAuth Token Request → Extract Bearer Token
     → Get Members → JSON to XML (stored) → Split Members → Build Worker HashMap
     → Split Members again → Resolve Worker ID → Get_Time_Off_Plan_Balances (Workday SOAP)
     → Store Balance in HashMap per member
     → Split Members (third pass) → Resolve Balance from HashMap
     → Write entry XML → Aggregator → XML to JSON
     → PUT to Aladtec /accrual-banks/balances
     → Log response per member → Store audit log
     → Integration Complete
```

### Known Bugs Fixed
- `accrual_balances_api` http-out was referencing `members_endpoint` instead of `accrual_banks_endpoint` — corrected
- `aladtech_members_balance_hashmap.get()` was called with two arguments — corrected to single argument

---

## ADP Workforce Now OAuth Integration

### Overview
This starter kit demonstrates how to connect Workday Studio to the ADP Workforce Now REST API using OAuth 2.0 client credentials flow to retrieve all worker data.

### What's Included
- OAuth 2.0 token flow (client credentials grant)
- REST API calls with Bearer token authentication
- SSL/mTLS certificate configuration for ADP's mutual TLS requirement
- Worker data retrieval using ADP's `/hr/v2/workers` endpoint
- JSON to XML conversion of ADP responses
- Splitter pattern for iterating through each worker record
- Per-worker field extraction (associateOID, workerID, name, status, job title)
- Required `asOfDate` launch parameter with date formatting
- Error handling and cloud logging on both the token and worker API calls

### What's NOT Included (still needed for production)
- Aggregator/join step after the splitter
- XSLT transforms for writing data back into Workday
- Pagination handling for large worker populations (`$top` / `$skip`)
- Token expiry handling and refresh logic
- Full error notifications and alerting
- Data validation and reconciliation logic

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Oauth | `client_id` | ADP API Central client ID |
| Oauth | `client_secret` | ADP API Central client secret (stored as password) |
| Oauth | `endpoint` | ADP base API URL (e.g. `https://api.adp.com`) |

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `asOfDate` | date | Yes | The effective date for retrieving worker data (MM/dd/yyyy) |

### SSL Certificate
ADP requires mutual TLS (mTLS) authentication. The certificate is stored directly inside the Studio assembly project. Before running this integration you must:
1. Generate a certificate through ADP API Central
2. Convert to `.pfx` format using OpenSSL
3. Replace the placeholder cert file inside the Studio assembly project with your own `.pfx` file
4. Update the `keystore-file` path in the `cc:https-properties` element to point to your file
5. Set the correct `keystore-password` in the same element

> **Note:** The cert file must be placed inside the assembly project folder and referenced by relative path. When the cert expires you will need to replace the file in the project and redeploy the `.clar`.

### Flow Overview
```
Start → Init (attributes + date format) → OAuth Token Request → Extract Bearer Token
     → Get All Workers (asOfDate) → JSON to XML → Split per Worker
     → Extract Worker Fields → [your logic here] → Integration Complete
```

### ADP API Reference
- Token endpoint: `POST /auth/oauth/v2/token`
- Workers endpoint: `GET /hr/v2/workers?asOfDate={date}`
- Full API docs: [ADP Developer Resources](https://developers.adp.com)

---

## ADP Worker Photo Upload Integration

### Overview
This starter kit uploads a worker's profile photo from Workday to ADP Workforce Now using the ADP photo upload event API. It retrieves the worker photo from Workday as base64, decodes it to raw binary, constructs a multipart/form-data request body in Groovy, and POSTs it to ADP.

### ⚠️ The Hard Part — Groovy Binary Multipart Construction
This is the most technically complex pattern in this repo and the one most developers will struggle with. Read this section carefully before building anything similar.

**The problem:** Studio's `cc:write` text field treats all content as a string. You cannot put binary image data into a write step — it will corrupt the image. ADP's photo upload API requires `multipart/form-data` with the actual binary image as one of the parts.

**The solution:** Build the entire multipart body as a byte stream in a Groovy eval using `ByteArrayOutputStream`. This gives you full control over every byte — the JSON metadata part, the image binary part, and the MIME boundaries.

**The key Groovy pattern:**
```groovy
// Step 1 — Handle Workday variable safely
// cc:base64-decode outputs an InputStream or MessageContent object, not a raw byte[]
// Always check and convert safely
def photoBytes = vars['photo_binary'] instanceof byte[] ?
                 vars['photo_binary'] :
                 vars['photo_binary'].getInputStream().getBytes()

// Step 2 — Build multipart body as byte stream
def boundary = 'WDADPBoundary'
def baos = new java.io.ByteArrayOutputStream()

// JSON part — text, written as UTF-8 bytes
def jsonPart = "--${boundary}\r\n" +
               "Content-Disposition: form-data; name=\"json\"\r\n" +
               "Content-Type: application/json\r\n\r\n" +
               "{\"events\":[{\"data\":{\"eventContext\":{\"worker\":{\"associateOID\":\"${props['employee_id']}\"}}}}}]}" +
               "\r\n"
baos.write(jsonPart.getBytes('UTF-8'))

// Image part header — text, written as UTF-8 bytes
def imagePart = "--${boundary}\r\n" +
                "Content-Disposition: form-data; name=\"datafile\"; filename=\"worker_image.jpg\"\r\n" +
                "Content-Type: image/jpeg\r\n\r\n"
baos.write(imagePart.getBytes('UTF-8'))

// Image binary — written directly as raw bytes, no string conversion
baos.write(photoBytes)

// Closing boundary — text, written as UTF-8 bytes
baos.write("\r\n--${boundary}--\r\n".getBytes('UTF-8'))

// Store complete byte array
vars['multipart_body'] = baos.toByteArray()
```

**Why this matters:** The JSON part and boundary strings are text — safe to write as UTF-8. The image binary is raw bytes — must be written directly without any string conversion. Mixing them in a write step or concatenating as strings will corrupt the image. `ByteArrayOutputStream` is the only clean way to combine text and binary in Studio.

**After the eval — restore and set headers:**
```xml
<cc:copy id="RestoreMultipart" input="variable" input-variable="multipart_body"/>
<cc:set-headers id="SetHeaders" clear-all="true">
    <cc:remove-headers/>
    <cc:add-headers>
        <cc:add-header name="Authorization" value="Bearer @{props['access_token']}"/>
        <cc:add-header name="Content-Type" value="multipart/form-data; boundary=WDADPBoundary"/>
    </cc:add-headers>
</cc:set-headers>
```

### What's Included
- OAuth 2.0 token flow with mTLS SSL certificate (same pattern as INT_ADP_Oauth_Example)
- Worker photo retrieval from Workday via `Get_Worker_Photos` SOAP call
- `cc:base64-decode` component to convert Workday base64 photo to binary
- Groovy `ByteArrayOutputStream` multipart body construction
- `multipart/form-data` POST to ADP `/events/hr/v1/worker.photo.upload`
- Cloud log audit trail stored at integration completion
- Error handling on OAuth, photo retrieval, and ADP upload steps

### What's NOT Included (still needed for production)
- associateOID resolution — in some ADP configurations the associateOID matches the Workday Employee ID, in which case this integration works as is. However this is not universal — some orgs have different IDs in each system. Verify with your ADP administrator whether your org uses Workday Employee IDs as the ADP associateOID before deploying. If they differ you will need to add a prior GET /hr/v2/workers call to ADP to resolve the correct associateOID
- XPath namespace map on Get_Worker_Photos response — required for correct field extraction
- Handling for workers with no photo on file
- Retry logic on failed upload
- Full validation of ADP response codes

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Worker` | text | Yes | The ADP associateOID of the worker whose photo will be uploaded |

> **Important — associateOID vs Workday Employee ID:** In some ADP configurations the associateOID matches the Workday Employee ID — in which case the same ID works for both the Workday photo retrieval and the ADP payload and no additional mapping is needed. This is not universal however. Verify with your ADP administrator whether your org uses Workday Employee IDs as the ADP associateOID before deploying. If they differ you will need to resolve the correct ADP associateOID before passing it into this integration.

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Oauth | `client_id` | ADP API Central client ID |
| Oauth | `client_secret` | ADP API Central client secret (stored as password) |
| Oauth | `endpoint` | ADP base API URL (e.g. `https://api.adp.com`) |

### SSL Certificate
Same requirement as INT_ADP_Oauth_Example — `.pfx` cert stored inside the Studio assembly project and referenced by relative path in `cc:https-properties`.

### Flow Overview
```
Start → Init (attributes + employee ID) → OAuth Token Request → Extract Bearer Token
     → Get Worker Photo (Workday SOAP) → Extract base64 → cc:base64-decode → binary
     → Groovy ByteArrayOutputStream → multipart body
     → POST to ADP /events/hr/v1/worker.photo.upload
     → Log audit → Integration Complete
```

### ADP API Reference
- Photo upload endpoint: `POST /events/hr/v1/worker.photo.upload`
- Content-Type required: `multipart/form-data`
- Parts: `json` (worker associateOID) + `datafile` (raw binary image)
- Full API docs: [ADP Developer Resources](https://developers.adp.com)

---

## EIB File Router Integration

### The Problem
A common real world scenario — you have an outbound EIB scheduled to run on the 1st of every month producing a file named `int001_01012026_monthly.csv`. You now need to add a second weekly Friday schedule producing `int001_01012026_weekly.csv`. The obvious answer is to clone the EIB, but that creates two integrations to maintain, two places to make changes, and doubles your change risk.

The alternative of removing the timestamp from the filename was rejected by the downstream system. So what's the solution?

### The Approach
Rather than cloning the EIB, this Studio integration sits between the EIB and the downstream delivery. It:
1. Calls the existing EIB via `GetEventDocuments` to retrieve the output file
2. Checks whether the run is monthly or weekly via boolean launch parameters
3. Renames the file using a sequence generator to produce the correct naming convention
4. Stores the renamed file with a 180 day expiry

One EIB. One file. Two schedules. Two naming conventions. No cloning.

### What's Included
- `GetEventDocuments` pattern to retrieve the EIB output file
- File extension filtering so only the target file type is processed
- Boolean launch parameters (`Is_Monthly` / `Is_Weekly`) to control schedule type
- Sequence generator services (`SEQ_Monthly` / `SEQ_Weekly`) for dynamic file naming
- Route-based branching for monthly vs weekly logic
- Logging for both matched and unmatched files
- Error handling throughout

### What's NOT Included (still needed for production)
- Actual SFTP or downstream delivery step after the store
- Notification on failure
- Handling for edge cases where neither boolean is true

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Is_Monthly` | boolean | No | Set to `true` when triggered by the monthly schedule |
| `Is_Weekly` | boolean | No | Set to `true` when triggered by the weekly schedule |
| `File_Extension` | text | Yes | File extension to filter on (e.g. `.csv`) |

### Sequence Generators
| Name | Purpose |
|------|---------|
| `SEQ_Monthly` | Generates the monthly file name (e.g. `int001_01012026_monthly`) |
| `SEQ_Weekly` | Generates the weekly file name (e.g. `int001_01012026_weekly`) |

### File Naming Convention Example
| Schedule | Output File Name |
|----------|-----------------|
| Monthly (1st of month) | `int001_01012026_monthly.csv` |
| Weekly (every Friday) | `int001_01012026_weekly.csv` |

### Flow Overview
```
Start → Init (params + sequence values) → GetEventDocuments → Iterate Files
     → Filter by Extension → Store file_data globally
     → Route: Is_Monthly → Write + Store with SEQ_Monthly name
     → Route: Is_Weekly  → Write + Store with SEQ_Weekly name
     → Log completion
```

---

## New Hire Vendor Sync Integration

### Overview
This starter kit synchronizes new hire worker data and profile photo to a third party vendor via SFTP upon hire completion. It retrieves worker details and photo from Workday, formats the output as a CSV with base64 encoded image, delivers it to a vendor SFTP endpoint, and writes an internal audit log of every record transmitted.

### 🤖 A Note on How This Was Built
This integration was built as a fun experiment in AI-assisted Workday Studio development. The business case and requirements were written by a human. The XML was generated by Claude Opus 4.7. The result was approximately 70% correct on the first pass.

**What it got right:**
- Overall flow structure and step sequencing
- SOAP request construction for Get Workers and Get Worker Photos
- Aggregator pattern for combining two API responses
- XSLT for CSV generation
- Filename convention and base64 photo handling
- Graceful handling of missing photos

**What it got wrong or needed correction:**
- Assumed a Business Process trigger model when the spec did not require it
- Defaulted to per-step error logging instead of a centralized cloud log pattern
- Did not ask about team-specific conventions before generating
- Code formatting required a full reformat before it was readable and maintainable
- XSLT files were referenced in the assembly but never bound — they exist as placeholders only and will not execute without being created and linked manually in Studio
- Some eval formatting inconsistencies

**Still unresolved:**
- It is currently unclear whether this integration will run correctly in a live Workday tenant. The structure is sound but has not been fully validated end to end. Use with caution and test thoroughly in a sandbox first.
- The unbound XSLT files are a known gap that will affect any future AI-generated Studio builds — this is a limitation worth being aware of before using AI to scaffold Studio integrations.

**The honest takeaway:** AI is good at executing against a tight spec and bad at inferring local conventions. The tighter your business case, the better the output. This file is shared as-is including its imperfections — it is a real example of what AI-assisted Studio development looks like today, not a polished finished product.

### What's Included
- Worker data retrieval via `Get_Workers` SOAP call (name, email, home address)
- Worker photo retrieval via `Get_Worker_Photos` SOAP call
- Aggregator pattern combining both API responses into a single payload
- XSLT transform generating a CSV with base64 encoded photo column
- Dynamic filename generation: `employeeid_dd_mm_yyyy.csv`
- SFTP delivery placeholder for vendor endpoint
- Internal audit log row via separate SFTP delivery placeholder
- Per-step error handling with WARNING and CRITICAL severity levels
- Global error handler for unexpected failures
- Intermediate document storage with 3 day expiry for API responses

### What's NOT Included (still needed for production)
- Actual SFTP transport — placeholders are in place with clear comments showing the pattern to follow
- SFTP credentials — externalize via launch parameters or Workday-managed credentials
- Internal audit SFTP destination — TBD per integration spec
- Centralized cloud log pattern — current error handling uses per-step PutIntegrationMessage calls
- Retry logic on SFTP failure
- `TransformWorkerToCSV.xsl` — XSLT file referenced but not included, must be built separately
- `BuildAuditLogRow.xsl` — XSLT file referenced but not included, must be built separately

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Worker` | Worker Reference (WID) | Yes | The new hire worker reference passed in at trigger time |

### CSV Output Format
| Column | Source | Notes |
|--------|--------|-------|
| First Name | Get_Workers personal info | |
| Last Name | Get_Workers personal info | |
| Work Email | Get_Workers personal info | |
| Home Address | Get_Workers personal info | |
| Photo | Get_Worker_Photos | Base64 encoded, empty string if no photo on file |

### Flow Overview
```
Start (Worker WID) → Build Get Workers Request → Call Get Workers → Store Response
     → Build Get Photo Request → Call Get Worker Photos → Store Response
     → Aggregate Both Responses → Transform to CSV (XSLT)
     → Build Filename → Store CSV → SFTP to Vendor (PLACEHOLDER)
     → Build Audit Row (XSLT) → SFTP Audit Log (PLACEHOLDER)
     → Report Success
```

### Error Handling
| Scenario | Severity | Behavior |
|----------|----------|----------|
| Get Workers fails | WARNING | Logged, integration continues |
| Photo lookup fails or no photo | WARNING | Empty photo field, continues |
| SFTP delivery fails | CRITICAL | Rethrows error, stops integration |
| Unexpected failure | CRITICAL | Global handler catches and logs |

### XSLT Files Required
Two XSLT files are referenced in the assembly and must be created and placed in the Studio project:

**`TransformWorkerToCSV.xsl`** — Transforms the aggregated `<new_hire_payload>` containing both the Get Workers and Get Worker Photos responses into a single CSV row. Must handle base64 photo encoding and empty photo gracefully.

**`BuildAuditLogRow.xsl`** — Transforms the CSV payload into a minimal audit record containing employee ID, full name, and date sent for internal tracking purposes.

### Document Storage
| Document | Expiry | Purpose |
|----------|--------|---------|
| `Get_Workers_Response.xml` | 3 days | Intermediate API response storage |
| `Get_Worker_Photos_Response.xml` | 3 days | Intermediate API response storage |
| `{employeeid}_dd_mm_yyyy.csv` | 30 days | Final CSV output |
| `audit_{employeeid}_dd_mm_yyyy.csv` | 30 days | Audit log row |

---
## UKG Accrual and Deduction Import Integration

### Overview
This integration retrieves a UKG accrual export file and loads absence accrual and deduction entries into Workday using `Put_Absence_Input` under the `Absence_Management` web service (v46.1). The UKG file provides both hours accrued and hours taken per employee per period — each row generates two Workday calls, one for the accrual (positive hours) and one for the deduction (negative hours).

### What's Included
- Document Retrieval Service via `GetEventDocuments` and Document Iterator pattern
- CSV to XML conversion for UKG flat file processing
- Per-row field extraction via XPath on named header columns
- `Put_Absence_Input` SOAP call for accrued hours (positive)
- `Put_Absence_Input` SOAP call for taken hours (negative) — skipped if amount taken is zero
- WID capture on both WWS responses for audit trail
- Detailed cloud log per record with all field values
- Error handling on both accrual and deduction WWS steps
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- AccrualCode to Workday Absence Component ID mapping — currently passes AccrualCode directly, an integration map may be needed depending on how codes are defined in Workday
- PersonNumber to Employee ID validation — assumes PersonNumber matches Workday Employee ID directly
- Duplicate detection — no check for previously loaded batches
- Retry logic on failed WWS calls per record
- Full error notifications and alerting

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. CSV file includes a header row**
This integration uses `cc:csv-to-xml` which maps column names directly from the header row to XML element names. If the UKG file does not include a header row the XPath references will not resolve and the integration will fail silently. Verify the file format with your UKG administrator before deploying.

**2. UKG PersonNumber = Workday Employee ID**
The integration passes `PersonNumber` directly as the `Employee_ID` type in the `Worker_Reference`. This only works if your org uses the same identifier in both systems. If PersonNumber and Workday Employee ID differ a lookup or transformation step will be needed before the WWS call.

**3. Workday `Put_Absence_Input` accepts negative hours**
The taken deduction is submitted as a negative `Hours` value to reduce the accrual balance. Workday does accept negative values on `Put_Absence_Input` — this is the supported pattern for recording deductions via this web service. Validate this behavior in your sandbox tenant before running in production as accrual plan configuration can affect how negative inputs are processed.

### Integration System
| Component | Name | Description |
|-----------|------|-------------|
| Retrieval Service | `INT_UKG_Retrieval_Example` | Document retrieval service configured on the Business Process to pull the UKG accrual file |

### UKG File Layout
| # | Field | Type | Description |
|---|-------|------|-------------|
| 1 | PersonNumber | String(15) | Maps to Workday Employee ID |
| 2 | AccrualCode | String | Maps to Workday Absence Component ID |
| 3 | Date | Date (yyyy-MM-dd) | Period end date used as Reference Date |
| 4 | StartingBalance | Decimal | For reference only — not submitted to Workday |
| 5 | AmountAccrued | Decimal | Submitted as positive hours |
| 6 | AmountTaken | Decimal | Submitted as negative hours |
| 7 | EndingBalance | Decimal | For reference only — not submitted to Workday |

### Workday WWS Calls Per Row
Two `Put_Absence_Input` calls are made per record:

- **Accrued** — `Batch_ID: UKG_ACCRUED_{date}` — positive hours from `AmountAccrued` — fires when `AmountAccrued > 0`
- **Taken** — `Batch_ID: UKG_TAKEN_{date}` — negative hours from `AmountTaken` — fires when `AmountTaken > 0`

### Flow Overview
```
Start → Init
     → GetEventDocuments → Document Iterator → per file:
     → CSV to XML → Split by record row → per row:
     → Extract fields → Log record details
     → Put_Absence_Input (Accrued) → Log WID
     → Put_Absence_Input (Taken negative) → Log WID
     → Store audit log → Integration Complete
```

---

## File Watcher Integration

### Overview
This integration acts as a lightweight file watcher. It runs on a schedule, checks an SFTP location via a configured retrieval service, and conditionally launches a downstream integration only if files are present. If no files are found it logs a message and exits cleanly. This pattern is useful when you have an integration that should only run when new data arrives rather than on a fixed schedule regardless of file availability.

### What's Included
- Document Retrieval Service via `GetEventDocuments` and `da.size()` file count check
- Route strategy to branch on file found vs no file found
- `Launch_Integration_Event` SOAP call to trigger the downstream integration when files are present
- Configurable downstream integration system ID via attribute map — no hardcoding
- Clean no-op exit with INFO log when no files are found
- Global error handler for unexpected failures

### What's NOT Included (still needed for production)
- File name logging — current implementation counts files but does not log which files were found
- Multiple downstream integration support — currently launches one integration system per run
- Launch parameters — the downstream integration is launched with no parameters. If the target integration requires launch parameters additional `Integration_Launch_Parameter_Data` elements would need to be added to the request
- Delete after retrieval — files are not automatically deleted from the SFTP after detection. Configure this on the retrieval service BP step if needed
- Retry logic on failed launch

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Configuration | `IntegrationSystem` | The Integration System ID of the downstream integration to launch when files are found |

### Integration System Components
| Component | Name | Description |
|-----------|------|-------------|
| Retrieval Service | `FileWatcherRetrieval` | Document retrieval service configured on the Business Process pointing to the SFTP location to watch |

### How It Works
On each scheduled run the integration checks whether the retrieval service returned any files using `da.size()`. If one or more files are present it fires a `Launch_Integration_Event` request targeting the configured downstream integration. If no files are present it logs `No Files Found in sFTP` and completes without launching anything.

> **Note:** The downstream integration is launched with no launch parameters. This pattern assumes the target integration retrieves its own file via its own retrieval service. If the downstream integration requires parameters or needs the file passed directly, the `Launch_Integration_Event_Request` would need to include `Integration_Launch_Parameter_Data` or `Launch_Input_Document_Data` elements.

### Flow Overview
```
Start → Init (get IntegrationSystem attribute)
     → GetEventDocuments → Check da.size()
     → Route: Files Found → Write Launch_Integration_Event_Request
                         → Launch_Integration_Event (Integrations v46.1)
                         → Log "Integration Launched"
     → Route: No File    → Log "No Files Found in sFTP"
     → Integration Complete
```

---
## Inbound Fixed Width File — One Time Payment Integration

### Overview
This integration retrieves a fixed width flat file from an SFTP location, parses each record using a TextSchema definition, validates required fields, and submits individual one time payment requests into Workday via the `Request_One-Time_Payment` operation under the `Compensation` web service (v46.1). It is designed as a generic starter kit for any organization loading one time payments from a fixed width file into Workday.

### What's Included
- Document Retrieval Service via `GetEventDocuments` and Document Iterator pattern
- TextSchema parsing of fixed width flat file via `cc:textschema` component
- Per-record field extraction via XPath with `.trim()` to strip padding
- Employee ID validation — skips and logs error if blank
- XSLT transform (`OneTimePaymentWWS.xsl`) for Workday SOAP payload construction
- Date formatting from `YYYYMMDD` to `YYYY-MM-DD` via XSLT substring
- `Request_One-Time_Payment` SOAP call per record via `Compensation` v46.1
- WID and exception capture on WWS response
- Cloud log per record with event WID and employee reference
- Error log per failed record — integration continues on failure
- Audit log stored at integration completion
- Global error handler for unexpected failures

### What's NOT Included (still needed for production)
- Amount validation — zero or negative amounts are not currently skipped. Add a `cc:validate-exp` check on `props['amount']` before the XSLT step
- Exception classification routing — response exceptions are logged but not routed differently based on Warning vs Error classification
- PayCode to Workday One Time Payment Plan ID mapping — currently passes PayCode directly. An integration map may be needed if codes differ between systems
- Multi-file support — Document Iterator handles multiple files but behavior with multiple files in the same run should be validated
- Retry logic on failed WWS calls

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Fixed width file includes a newline character at the end of every row including the last row**
The TextSchema uses `ts:endTag="&#10;"` to detect record boundaries. If any row including the last is missing a trailing newline the record will land in the `Unparsed` element and not be processed.

**2. EmployeeID in the file matches Workday Employee ID**
The integration passes `EmployeeID` directly as `Employee_ID` type in the `Employee_Reference`. If your source system uses a different identifier a lookup or transformation step will be needed.

**3. PayCode maps directly to a Workday One Time Payment Plan ID**
No mapping is applied. The value in the file is submitted as-is to `One_Time_Payment_Plan_Reference`. Validate that your PayCode values match configured plan IDs in Workday before deploying.

**4. EffectiveDate is in YYYYMMDD format**
The XSLT handles the conversion to `YYYY-MM-DD` using substring. If your file uses a different date format the XSLT will need to be updated.

### Integration System Components
| Component | Name | Description |
|-----------|------|-------------|
| Retrieval Service | `RS_Fixed_Width_File` | Document retrieval service configured on the Business Process pointing to the SFTP location |

### Fixed Width File Layout
| # | Field | Length | Positions | Description |
|---|-------|--------|-----------|-------------|
| 1 | EmployeeID | 10 | 1-10 | Workday Employee ID |
| 2 | PayCode | 10 | 11-20 | One Time Payment Plan ID |
| 3 | EffectiveDate | 8 | 21-28 | Payment effective date YYYYMMDD |
| 4 | Amount | 10 | 29-38 | Payment amount decimal |
| 5 | CurrencyCode | 6 | 39-44 | ISO currency code e.g. USD |
| 6 | Comment | 30 | 45-74 | Payment description or note |

Total record length: 74 characters per row

### TextSchema
**File:** `textExample.xsd`
Parses the fixed width file using `ts:fixedLength` per field and `ts:endTag="&#10;"` as the record delimiter. Fields are read sequentially in the order defined. All fields are `xsd:string` with `minOccurs="0"` to prevent parse failure on blank fields. Padding is stripped via `.trim()` in the eval step after parsing.

> **Note:** The correct TextSchema attributes for fixed width parsing in Workday Studio are `ts:fixedLength` and `ts:align`. The `ts:endTag="&#10;"` XML entity must be used instead of the literal `\n` string for the record delimiter to be recognized correctly by the Cape Clear parser.

### XSLT
**File:** `OneTimePaymentWWS.xsl`
Transforms extracted field values into a `Request_One-Time_Payment_Request` SOAP payload. Handles date formatting from `YYYYMMDD` to `YYYY-MM-DD` using XSLT 1.0 `substring` and `concat`. Accepts the following parameters from props:

- `employee_id`
- `pay_code`
- `effective_date`
- `amount`
- `currency_code`
- `comment`

### Validation
| Field | Rule | Behavior on Failure |
|-------|------|-------------------|
| EmployeeID | Must not be blank | Skip record, log ERROR, continue |
| Amount | Not validated — add for production | N/A |

### Flow Overview
```
Start → Init
     → GetEventDocuments → Document Iterator → per file:
     → TextSchema parse (text to XML)
     → Split by ns0:File/ns0:Record → per record:
     → Extract fields → trim padding
     → Validate EmployeeID not blank
     → XSLT transform → Request_One-Time_Payment (Compensation v46.1)
     → Capture WID + exceptions → Log result
     → Store audit log → Integration Complete
```
---
## Zendesk New Hire Equipment Request Integration

### Overview
This starter kit demonstrates how to connect Workday Studio to the Zendesk REST API to automatically create an IT equipment request ticket when a new hire is processed in Workday. It pulls worker details from Workday via `Get_Workers` and submits a formatted ticket to Zendesk via a single authenticated POST — no OAuth token exchange required.

### What's Included
- Launch parameter to accept Worker WID from the Hire Business Process
- `Get_Workers` SOAP call via `Human_Resources` v46.0
- Worker field extraction via eval XPath — name, email, hire date, job title, location, manager
- Basic auth header construction from Integration System attributes
- JSON ticket body built directly in Studio write step — no XSLT required
- POST to Zendesk `/api/v2/tickets`
- JSON to XML conversion on Zendesk response
- Ticket ID, URL, and status capture via eval XPath
- Cloud log per step — Get Worker success, Zendesk ticket created, errors
- Error handling on both Get Workers and Zendesk API steps
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- Duplicate check — if the BP fires twice for the same hire two tickets will be created
- Work email fallback — if no work email is provisioned at hire time the requester email will be blank
- Zendesk user creation — if the requester email doesn't exist in Zendesk the ticket creation may fail depending on your Zendesk account settings
- Group or assignee routing — ticket is created unassigned
- Retry logic on Zendesk API failure

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Work email is provisioned at hire time**
The integration passes the worker's work email as the Zendesk requester. If email provisioning happens after the hire event fires the requester field will be blank and ticket creation may fail.

**2. EmployeeWID is passed by the Business Process**
Configure the Hire BP step to pass the Worker WID as the `EmployeeWID` launch parameter before deploying.

**3. Zendesk allows ticket creation with new requesters**
If your Zendesk account is configured to restrict ticket creation to existing users only the POST will fail for first-time requesters. Validate this in your Zendesk sandbox first.

### Integration System Attributes
| Attribute Map | Attribute | Description |
|---------------|-----------|-------------|
| Zendesk_API_Config | `zendesk.email` | Admin email used for Zendesk Basic auth |
| Zendesk_API_Config | `zendesk.api.token` | API token generated in Zendesk Admin Center (stored as password) |
| Zendesk_API_Config | `zendesk.subdomain` | Your Zendesk subdomain e.g. `mycompany` |

### Launch Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `EmployeeWID` | Text | Worker WID passed in from the Hire Business Process |

### Zendesk Auth
Zendesk uses Basic auth — no OAuth token exchange required. Generate your API token once in Zendesk Admin Center → Apps and Integrations → APIs → Zendesk API. Store it as a password attribute and the integration constructs the auth header directly on the POST request.

### Ticket Created
| Field | Value |
|-------|-------|
| Subject | New Hire Equipment Request — {worker full name} |
| Type | Task |
| Priority | Normal |
| Tags | new_hire, equipment_request |
| Body | Worker name, job title, hire date, office location, manager |

### Flow Overview
```
Start (EmployeeWID) → Init (attributes + params)
     → Get_Workers (Human_Resources v46.0) → Extract worker fields via XPath
     → Build auth header → Write JSON ticket body
     → POST to Zendesk /api/v2/tickets
     → JSON to XML → Extract ticket ID + URL + status
     → Cloud log → Store audit log → Integration Complete
```

---
## AI-Powered New Hire Onboarding Report

### Overview
This integration pulls new hire worker data from Workday via `Get_Workers` and sends it to the Claude AI API (Anthropic) to generate a plain English onboarding status report in HTML format. The report identifies missing fields, gaps, and key worker details for HR teams to action. The prompt is fully configurable via launch parameter — no code changes needed to change the report format or focus.

### What's Included
- Date range launch parameters to control the worker pull window
- Configurable AI prompt via launch parameter with a sensible default
- `Get_Workers` SOAP call via `Human_Resources` v46.1 with transaction log data
- Worker response stored as a variable and passed directly to Claude
- POST to Anthropic `/v1/messages` endpoint with model, max tokens, and API key from attributes
- JSON to XML conversion on Claude response
- AI report text extracted via XPath and stored as `OnboardingRPT.html`
- Cloud log on WWS response and Claude response for debugging
- Error handling on both Get Workers and Claude API steps
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- Worker filtering by hire date — `Transaction_Log_Criteria` returns all workers updated in the window, not just new hires. Add a hire date filter in an eval after the WWS response or use `Effective_From/Through` instead of `Updated_From/Through`
- Pagination — if more than 100 workers are returned the response will be paginated and only the first page goes to Claude. Add a `Response_Filter` with `Count` and loop logic for large orgs
- SFTP or email delivery — report is stored in Document Repository only. Add a delivery step for HR to receive it automatically
- Prompt injection protection — the prompt launch parameter is passed directly to Claude. Validate or sanitize input in production
- HTML sanitization — Claude response is written directly to file without validation
- Retry logic on Claude API failure

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Worker data volume fits within Claude's context window**
The raw Get_Workers XML response is sent directly to Claude. For large worker populations this will exceed the model's context limit and the API call will fail. Test with your expected new hire volume before deploying.

**2. Date parameters are in YYYY-MM-DD format**
The integration passes `from_date` and `to_date` directly into the WWS request. Workday's date launch parameter type should handle formatting but validate in sandbox first.

**3. Anthropic API key has sufficient quota**
The integration makes one API call per run. Ensure your Anthropic account has sufficient credits and the API key has not expired before scheduling.

### Integration System Attributes

| Attribute Map | Attribute | Type | Description |
|---------------|-----------|------|-------------|
| Anthropic_Config | `API_Key` | Password | Anthropic API key from console.anthropic.com |
| Anthropic_Config | `Endpoint` | Text | Anthropic base URL — `https://api.anthropic.com/v1` |
| Anthropic_Config | `Claude_Model` | Text | Model ID e.g. `claude-sonnet-4-20250514` |
| Anthropic_Config | `Max_Tokens` | Number | Max tokens for Claude response e.g. `1024` |

### Launch Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Date | Yes | Start of the worker pull window |
| `to_date` | Date | Yes | End of the worker pull window |
| `prompt` | Text | No | AI prompt sent to Claude. Defaults to standard onboarding gap report prompt |

### Default Prompt
```
You are an HR onboarding assistant. Review the following new hire data from Workday
and generate a concise onboarding status report. For each worker identify: full name,
hire date, job title, office location, manager, and work email. Flag any missing or
incomplete fields as gaps that HR should follow up on. Group workers by start date.
Write in plain English suitable for an HR team. Keep the report concise and actionable.
```

### Output

| File | Format | Destination |
|------|--------|-------------|
| `OnboardingRPT.html` | HTML | Workday Document Repository |
| `Log.html` | HTML | Workday Document Repository — cloud log audit trail |

### Flow Overview
```
Start → Init (launch params + attributes)
     → Get_Workers (Human_Resources v46.1) → Store response as variable
     → Build Claude JSON payload → Set auth headers
     → POST to Anthropic /v1/messages
     → JSON to XML → Extract report text
     → Write HTML → Store OnboardingRPT.html
     → Store audit log → Integration Complete
```

### Error Handling

| Scenario | Severity | Behaviour |
|----------|----------|-----------|
| Get Workers WWS fails | ERROR | Cloud log, integration stops |
| Claude API POST fails | ERROR | Cloud log, integration stops |
| Unexpected error | CRITICAL | Global handler, PutIntegrationMessage |
| Success | INFO | Two INFO messages — WWS success and Claude report created |

### 🤖 A Note on AI-Generated Content
The report content is generated by Claude AI based on the raw Workday XML response. The quality of the report depends on the data completeness in Workday and the prompt provided. Always review AI-generated reports before distributing to stakeholders. The prompt launch parameter makes it easy to refine output without touching the integration code.
---
## AI-Powered Worker PII Anonymization + Claude Analysis

### Overview
This integration pulls worker data from Workday via `Get_Workers`, strips PII by replacing real Worker IDs with anonymized keys (`WORKER_1`, `WORKER_2`, etc.), stores the mapping in a HashMap, and sends the sanitized XML to the Claude AI API for analysis. The prompt is fully configurable via launch parameter — no code changes needed to change the report format or focus.

### What's Included
- Date range launch parameters to control the worker pull window
- Configurable AI prompt via launch parameter with a sensible default
- `Get_Workers` SOAP call via `Human_Resources` v46.1 with transaction log data
- Per-worker PII anonymization via HashMap — real Worker ID replaced with `WORKER_N` key
- Leave status extraction per worker alongside anonymized ID
- Aggregator pattern to collect all anonymized worker entries into a single `<root>` XML payload
- POST to Anthropic `/v1/messages` endpoint with model, max tokens, and API key from attributes
- JSON to XML conversion on Claude response
- AI report text extracted via XPath and stored as `OnboardingRPT.html`
- Cloud log on WWS response and Claude response for debugging
- Error handling on both Get Workers and Claude API steps
- Global error handler for unexpected failures
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- HashMap reverse lookup — anonymized keys are stored but not currently used to re-identify workers in the Claude response. Add a reverse lookup step after parsing if needed
- Pagination — only the first page of workers is processed. Add `Response_Filter` with `Count` and loop logic for large orgs
- SFTP or email delivery — report is stored in Document Repository only
- Prompt injection protection — prompt launch parameter is passed directly to Claude. Validate or sanitize in production
- Retry logic on Claude API failure

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Worker data volume fits within Claude's context window**
The sanitized XML payload is sent directly to Claude. For large worker populations this will exceed the model's context limit and the API call will fail. Test with your expected worker volume before deploying.

**2. Date parameters are in YYYY-MM-DD format**
The integration passes `from_date` and `to_date` directly into the WWS request. Workday's date launch parameter type should handle formatting but validate in sandbox first.

**3. Anthropic API key has sufficient quota**
Ensure your Anthropic account has sufficient credits and the API key has not expired before scheduling.

**4. Leave status is populated in Workday**
If `On_Leave` is not populated for a worker the field will be blank in the anonymized payload sent to Claude.

### Integration System Attributes
| Attribute Map | Attribute | Type | Description |
|---------------|-----------|------|-------------|
| Anthropic_Config | `api_key` | Password | Anthropic API key from console.anthropic.com |
| Anthropic_Config | `endpoint` | Text | Anthropic base URL — `https://api.anthropic.com/v1` |
| Anthropic_Config | `claude_model` | Text | Model ID e.g. `claude-sonnet-4-20250514` |
| Anthropic_Config | `max_tokens` | Number | Max tokens for Claude response e.g. `1024` |

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Date | Yes | Start of the worker pull window |
| `to_date` | Date | Yes | End of the worker pull window |
| `prompt` | Text | No | AI prompt sent to Claude. Defaults to standard XML schema mapping prompt |

### Default Prompt
```
You will receive worker data in XML. Parse the values and return them
formatted in the Workday Get_Workers_Response XML schema.

Rules:
- Always wrap response in <bsvc:Get_Workers_Response>
- Use namespace xmlns:bsvc="urn:com.workday/bsvc"
- Map workerid to Worker_ID
- Map leavestatus to Leave_Status_Data/On_Leave
- Return only valid XML, no explanation
```

### Anonymized Payload Sent to Claude
```xml
<root>
  <entry>
    <worker_id>WORKER_1</worker_id>
    <leave_status>false</leave_status>
  </entry>
  <entry>
    <worker_id>WORKER_2</worker_id>
    <leave_status>true</leave_status>
  </entry>
</root>
```

### Output
| File | Format | Destination |
|------|--------|-------------|
| `OnboardingRPT.html` | HTML | Workday Document Repository |
| `log.html` | HTML | Workday Document Repository — cloud log audit trail |

### Flow Overview
```
Start → Init (launch params + attributes)
     → Get_Workers (Human_Resources v46.1) → Store response as variable
     → Split by Worker → Per worker:
     → Anonymize Worker ID → Extract Leave Status → Store in HashMap
     → Write anonymized <entry> XML
     → Aggregator → Collect all entries into <root> payload
     → Build Claude JSON payload → Set auth headers
     → POST to Anthropic /v1/messages
     → JSON to XML → Extract report text
     → Write HTML → Store OnboardingRPT.html
     → Store audit log → Integration Complete
```

### Error Handling
| Scenario | Severity | Behaviour |
|----------|----------|-----------|
| Get Workers WWS fails | ERROR | Cloud log, integration stops |
| Claude API POST fails | ERROR | Cloud log, integration stops |
| Unexpected error | CRITICAL | Global handler, PutIntegrationMessage |
| Success | INFO | Two INFO messages — WWS success and integration complete |

### 🤖 A Note on PII Anonymization
Real Worker IDs never leave Workday Studio. The HashMap stores the `WORKER_N` to real Worker ID mapping in memory for the duration of the integration run only. Claude receives only anonymized keys and leave status. If your use case requires Claude to reference specific workers in its response add a reverse lookup step after parsing the Claude response to re-identify workers from the HashMap before storing or delivering the report.

---
## AI-Powered Supervisory Org Data Governance Audit

### Overview
Inspired by the "first things first" principle — clean your data before you buy the robot. This integration pulls supervisory organization assignment restrictions and active worker data from Workday, sends both datasets to Claude AI, and returns a plain English HTML audit report identifying structural issues, misconfigurations, and orphaned orgs before you feed your tenant data into any AI tool or agent.

This is not an AI report on your workers. It is an AI report on whether your Workday data is ready for AI.

### What's Included
- Configurable AI prompt via launch parameter with a sensible default
- `Get_Organization_Assignment_Restrictions` SOAP call via `Human_Resources` v46.1 — pulls all sup org assignment defaults and allowed values
- `Get_Workers` SOAP call via `Human_Resources` v46.1 — pulls active workers with supervisory org and management chain data only
- Both responses stored as variables and passed together to Claude for cross reference analysis
- POST to Anthropic `/v1/messages` endpoint with model, max tokens, and API key from attributes
- JSON to XML conversion on Claude response
- AI audit report extracted and stored as `SupOrgAudit.html`
- Cloud log on both WWS responses and Claude response for debugging
- Global error handler for unexpected failures
- Per-step error handling on both WWS calls and Claude API call
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- Pagination — both WWS calls are set to a count of 999. If your tenant has more than 999 supervisory orgs or more than 999 workers the response will be paginated and only the first page goes to Claude. Add loop logic for large orgs
- PII anonymization — worker and org references are sent to Claude as-is. If your compliance requirements prohibit sending identifiers to an external AI API add an anonymization layer before the Claude call — see `INT_PII_Claude_Get_Workers.clar` for the HashMap anonymization pattern
- Prompt injection protection — the prompt launch parameter is passed directly to Claude. Validate or sanitize in production
- SFTP or email delivery — report is stored in Document Repository only. Add a delivery step for governance teams to receive it automatically
- Retry logic on Claude API failure
- Active manager validation — management chain data is included but Claude's ability to detect terminated managers depends on the data returned in the management chain. Validate this behavior in your sandbox

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Worker and org data volume fits within Claude's context window**
Both the Get_Workers and Get_Organization_Assignment_Restrictions responses are sent together to Claude. For large tenants this combined payload will exceed the model's context limit and the API call will fail. Test with your expected tenant size before deploying.

**2. Get_Organization_Assignment_Restrictions returns data**
This WWS only returns data for supervisory orgs that have assignment restrictions configured. Orgs with zero restrictions configured will not appear in the response at all. Claude will identify missing orgs by cross referencing against the worker data but if worker data is also missing for those orgs they may not be flagged. This is a known gap — document it for your stakeholders.

**3. Anthropic API key has sufficient quota**
The integration makes one API call per run combining both datasets. Ensure your Anthropic account has sufficient credits and the API key has not expired before scheduling.

**4. Sup org data reflects current tenant state**
No date filtering is applied. Both calls pull current active state. If your tenant has pending org changes in flight the report may reflect data mid-transition.

### Integration System Attributes
| Attribute Map | Attribute | Type | Description |
|---------------|-----------|------|-------------|
| Anthropic_Config | `API_Key` | Password | Anthropic API key from console.anthropic.com |
| Anthropic_Config | `Endpoint` | Text | Anthropic base URL — `https://api.anthropic.com/v1` |
| Anthropic_Config | `Claude_Model` | Text | Model ID e.g. `claude-sonnet-4-20250514` |
| Anthropic_Config | `Max_Tokens` | Text | Max tokens for Claude response e.g. `2048` |

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt` | Text | No | AI prompt sent to Claude. Defaults to the standard sup org governance audit prompt |

### Default Prompt
```
You are a Workday data governance auditor. You will receive two XML datasets:

1. Supervisory Organization Assignment Restrictions data
2. Worker data including their supervisory org assignments

Your job is to audit the supervisory org structure and return a clear HTML report.

For each issue found, categorize it as one of:
- CRITICAL: Immediate action required
- WARNING: Should be reviewed
- INFO: Worth noting

Audit Rules - Flag the following:

Org Assignment Restrictions:
- Sup org has no org assignment restrictions configured at all
- Sup org has no default cost center set
- Sup org has no default company set
- Sup org has allowed values defined but no default set

Worker Cross Reference:
- Sup org has active workers but no org assignment restrictions configured
- Sup org exists but has zero active workers assigned — possible orphaned org
- Sup org manager is terminated or inactive
- Multiple sup orgs with identical or near identical names — possible duplicates

Report Format:
- Start with an executive summary — total orgs audited, total issues found by severity
- Group issues by CRITICAL, WARNING, INFO
- For each issue state the org reference, the problem, and a recommended action
- End with a data readiness score out of 10 for AI readiness

Return only valid HTML. No explanation outside the HTML. No markdown.
```

### WWS Calls
| Call | Web Service | Version | Purpose |
|------|-------------|---------|---------|
| `Get_Organization_Assignment_Restrictions` | Human_Resources | v46.1 | Pulls sup org assignment defaults and allowed values |
| `Get_Workers` | Human_Resources | v46.1 | Pulls active workers with sup org and management chain data |

### Output
| File | Format | Destination |
|------|--------|-------------|
| `SupOrgAudit.html` | HTML | Workday Document Repository |
| `log.html` | HTML | Workday Document Repository — cloud log audit trail |

### Flow Overview
```
Start → Init (launch params + attributes)
     → Get_Workers (Human_Resources v46.1) → Store as workerResponse variable
     → Get_Organization_Assignment_Restrictions (Human_Resources v46.1) → Store as SupOrgResponse variable
     → Build Claude JSON payload with both responses
     → Set auth headers → POST to Anthropic /v1/messages
     → JSON to XML → Extract audit report text
     → Write HTML → Store SupOrgAudit.html
     → Store audit log → Integration Complete
```

### Error Handling
| Scenario | Severity | Behaviour |
|----------|----------|-----------|
| Get Workers WWS fails | ERROR | Cloud log, integration stops |
| Get Sup Org WWS fails | ERROR | Cloud log, integration stops |
| Claude API POST fails | ERROR | Cloud log, integration stops |
| Unexpected error | CRITICAL | Global handler, PutIntegrationMessage |
| Success | INFO | Three INFO messages — Workers success, Sup Org success, integration complete |

### 🤖 A Note on AI Governance Auditing
This integration is built on the principle that AI is only as smart as the data you feed it. Before running any AI agent, chatbot, or analytics layer on your Workday tenant, you need to know whether your supervisory org structure is clean. This kit uses Claude to do that reading for you — surfacing what's misconfigured, what's orphaned, and what needs attention before you go further. The data readiness score gives leadership a single number to understand where the tenant stands today and what needs to happen before AI can be trusted on it.

---
## AI-Powered Workday Integration Audit + Flex Credits Risk Report

### Overview
Inspired by Michael Domingo's piece in The Department of First Things First — *"Workday's AI Meter Is Running. The Grace Period Ends January 31."* — this integration audits your Workday integration landscape and uses Claude AI to assess Flex Credits consumption risk before the meter starts.

It pulls two datasets from Workday: all integration systems configured in the tenant, and execution event history for a specified date window. Both are sent to Claude, which returns a plain English HTML report identifying high-risk integrations, dormant systems, projected credit burn, and recommended actions before January 31, 2027.

This is not a replacement for the Platform Consumption Console. It is a Studio-native starting point for teams who haven't turned on the PCC yet or want a broader picture of their integration landscape before modeling credit exposure.

### What's Included
- Date range launch parameters to control the event history window
- Optional worker count launch parameter for per-worker credit burn modeling
- Configurable AI prompt via launch parameter with a sensible default
- `Get_Integration_Events` SOAP call via `Integrations` v46.1 — pulls execution history, record counts, and status for the date window
- `Get_Integration_Systems` SOAP call via `Integrations` v46.1 — pulls all integration systems in the tenant including name, type, and template
- Both responses stored as variables and passed together to Claude
- POST to Anthropic `/v1/messages` endpoint with model, max tokens, and API key from attributes
- JSON to XML conversion on Claude response
- AI audit report extracted and stored as `AuditRPT.html`
- Cloud log on both WWS responses and Claude response for debugging
- Global error handler for unexpected failures
- Per-step error handling on both WWS calls and Claude API call
- Audit log stored at integration completion

### What's NOT Included (still needed for production)
- Multi-instance integration system filtering — the launch parameter scaffold is in place but the WWS request does not currently filter by specific integration systems. If you want to scope the audit to a subset of integrations add `Integration_System_Reference` blocks to the `Get_Integration_Events` request criteria
- Pagination — both WWS calls are set to 999. If your tenant has more than 999 integration systems or more than 999 events in the date window only the first page is processed. Add loop logic for large tenants or wide date windows
- Exact API call counts — Workday does not expose raw API call counts via WWS. `Total_Records` is used as a proxy. Verify actual consumption in the Platform Consumption Console
- Rate card accuracy — the rate card baked into the default prompt is based on the Workday v262 Flex Credits card as published in May 2026. Workday may update rates — validate before using for financial modeling
- Prompt injection protection — the prompt launch parameter is passed directly to Claude. Validate or sanitize in production
- SFTP or email delivery — report is stored in Document Repository only
- Retry logic on Claude API failure

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Integration event and system data volume fits within Claude's context window**
Both responses are sent together to Claude. Tenants with large integration landscapes and wide date windows will produce payloads that exceed the model's context limit. Start with a narrow date window — 7 to 30 days — and expand once you know the payload size.

**2. Total_Records is a reasonable proxy for API consumption**
Exact API call counts are not available via WWS. Claude uses record counts to estimate API volume. This is an approximation — not a billing-accurate figure. Always validate in the PCC before making financial decisions.

**3. The grace period scope is correctly understood**
The grace period covers Application API overages only through January 31, 2027. It does not cover agent credit burn. The default prompt communicates this but confirm with your Workday account team before relying on it.

**4. Anthropic API key has sufficient quota**
The integration makes one API call per run combining both datasets. Ensure your Anthropic account has sufficient credits and the API key has not expired before scheduling.

**5. Worker count is accurate**
The worker count launch parameter is used by Claude to model per-worker credit burn. An inaccurate count will produce inaccurate projections. Use your actual active headcount.

### Integration System Attributes
| Attribute Map | Attribute | Type | Description |
|---------------|-----------|------|-------------|
| Anthropic_Config | `API_Key` | Password | Anthropic API key from console.anthropic.com |
| Anthropic_Config | `Endpoint` | Text | Anthropic base URL — `https://api.anthropic.com/v1` |
| Anthropic_Config | `Claude_Model` | Text | Model ID e.g. `claude-sonnet-4-20250514` |
| Anthropic_Config | `Max_Tokens` | Number | Max tokens for Claude response e.g. `2048` |

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Date | Yes | Start of the integration event window |
| `to_date` | Date | Yes | End of the integration event window |
| `worker_count` | Text | No | Approximate active headcount for per-worker credit burn modeling |
| `prompt` | Text | No | AI prompt sent to Claude. Defaults to standard Flex Credits audit prompt |

### Default Prompt
```
You are a Workday Flex Credits consumption auditor. You will receive two datasets:

1. Integration Systems — all integrations configured in the tenant including name, type, and owner
2. Integration Events — execution history including run dates, record counts, and status for a specified date window

Your job is to analyze this data and return a clear HTML audit report.

Context:
- The grace period for API overages runs through January 31 2027 — agent credit burn is NOT covered by the grace period
- Exact API call counts are not available. Use Total_Records as a proxy for API consumption volume
- Verify exact figures in the Workday Platform Consumption Console

Flex Credits Rate Card Reference:
- Self-service action: 1 credit per event
- Payroll Data Monitoring: 0.5 credits per worker per run — HIGH RISK at scale
- Talent Rediscovery: 750 credits per event — CRITICAL RISK
- Core Platform API: 60 credits per 10,000 calls over baseline
- Complimentary allotment scales by org size — model conservatively

Audit Rules:
- Flag integrations with high record counts as potential high API consumers
- Flag integrations that ran more than daily — highest volume API drivers
- Flag integrations with high failure rates — failed runs still consume credits
- Flag integrations with zero events in the window — dormant or abandoned
- For each integration estimate monthly run frequency based on the event window
- Project annual record volume at current cadence
- Assign a risk rating: LOW / MEDIUM / HIGH / CRITICAL
- Flag any integration processing more than 10000 records per run as HIGH minimum

Report Format:
- Executive summary — total integrations audited, total events in window, estimated total record volume, overall credit risk rating
- Integration breakdown table — name, type, runs in window, avg records per run, projected annual records, risk rating
- Top 5 highest risk integrations with detailed analysis and recommended action
- Dormant integrations section — integrations with zero events, flag for review or decommission
- Grace period advisory — remind reader what is and is not covered
- Recommended next steps before January 31 2027

Return only valid HTML. No explanation outside the HTML. No markdown. No backticks.
```

### WWS Calls
| Call | Web Service | Version | Purpose |
|------|-------------|---------|---------|
| `Get_Integration_Events` | Integrations | v46.1 | Pulls execution history, record counts, and status for the date window |
| `Get_Integration_Systems` | Integrations | v46.1 | Pulls all integration systems in the tenant including name and template type |

### Output
| File | Format | Destination |
|------|--------|-------------|
| `AuditRPT.html` | HTML | Workday Document Repository |
| `Log.html` | HTML | Workday Document Repository — cloud log audit trail |

### Flow Overview
```
Start → Init (launch params + attributes)
     → Get_Integration_Events (Integrations v46.1) → Store as intEventsWWS variable
     → Get_Integration_Systems (Integrations v46.1) → Store as IntSystemWWS variable
     → Build Claude JSON payload with both responses
     → Set auth headers → POST to Anthropic /v1/messages
     → JSON to XML → Extract audit report text
     → Write HTML → Store OnboardingRPT.html
     → Store audit log → Integration Complete
```

### Error Handling
| Scenario | Severity | Behaviour |
|----------|----------|-----------|
| Get Integration Events WWS fails | ERROR | Cloud log, integration stops |
| Get Integration Systems WWS fails | ERROR | Cloud log, integration stops |
| Claude API POST fails | ERROR | Cloud log, integration stops |
| Unexpected error | CRITICAL | Global handler, PutIntegrationMessage |
| Success | INFO | Three INFO messages — events success, systems success, integration complete |

### 📊 A Note on Rate Card Accuracy
The Flex Credits rate card used in the default prompt is based on the Workday v262 Platform Entitlement Policy as covered by Michael Domingo in The Department of First Things First (June 2026). Workday marks design-phase skill rates as subject to change. Do not use this report as a substitute for reviewing your actual agreement or consulting your Workday account team. The goal of this kit is directional awareness — not billing-accurate forecasting.

### 🤖 A Note on AI-Generated Credit Projections
Claude's projections are based on the data provided and the rate card baked into the prompt. Without exact API call counts — which are only available in the Platform Consumption Console — all figures are estimates. Use this report to identify which integrations deserve closer attention, then validate those specific integrations in the PCC before making any financial or architectural decisions.
---
## AI-Powered Yes/No Preferred Name Compliance Validator

### Overview
Inspired by the Stormloop session at Workday DevCon 2026 — *"Yes or No: The Surprisingly Simple AI Path to Quicker ROI"* — this integration pulls workers with preferred names set in Workday, sends each name to Claude AI along with your company policy and executive list, and receives a strict YES or NO compliance decision with a one sentence reason. Results are aggregated into a single HTML report for HR to review and action.

The pattern is intentionally generic. While this starter kit uses preferred name validation as the use case, the YES/NO prompt structure can be adapted to validate any text field against any written policy — justification text, comment moderation, role descriptions, and more.

### What's Included
- Date range launch parameters to control the worker pull window
- `policy` launch parameter — paste your preferred name policy text at runtime, no code changes needed
- `executive_names` launch parameter — paste a list of executive names Claude should flag if impersonated
- `Get_Workers` SOAP call via `Human_Resources` v46.1 with personal information including preferred name data
- Splitter pattern — loops per worker, one Claude API call per worker
- Per-worker eval extracting legal name, preferred name, and Worker ID via XPath
- Skip logic via `cc:validate-exp` — workers with no preferred name set are skipped and logged, integration continues
- Prompt built dynamically in Groovy per worker — policy, executive list, and preferred name interpolated at runtime
- HTTP POST to Anthropic `/v1/messages` per worker with `max_tokens` set to 100 for fast, cheap responses
- JSON to XML conversion on Claude response per worker
- Per-worker HTML fragment written with Worker ID, legal name, preferred name, and Claude decision
- Aggregator collects all fragments into a single HTML report
- Report stored as `RPT.html` in Workday Document Repository
- Cloud log on WWS response and per-worker Claude response for debugging
- Global error handler for unexpected failures
- Per-step error handling on WWS call and Claude API call

### What's NOT Included (still needed for production)
- Worker filtering by preferred name diff — `Get_Workers` with transaction log criteria returns workers updated in the window, not specifically workers who changed their preferred name. Depending on your date window this may return workers with no relevant preferred name change. Narrow the date window or add additional filtering post-splitter
- Rate limiting — one Claude API call fires per worker with a preferred name. For large populations or wide date windows this can result in hundreds of API calls per run. Consider batching multiple workers per prompt if cost or rate limits are a concern
- Pagination — `Get_Workers` is not paginated. If more than 999 workers are returned in the window only the first page is processed
- Action routing — the report flags YES/NO but takes no automated action. Wiring a notification or task creation for flagged NO decisions would need additional steps after the aggregator
- Prompt injection protection — policy and executive name launch parameters are passed directly into the prompt. Validate input before deploying to production

### ⚠️ Key Assumptions
> These assumptions must be validated before deploying to any environment.

**1. Preferred name is set and differs from legal name**
`Preferred_Name_Data` only exists in the response if the worker has explicitly set a preferred name in Workday. Workers without one are skipped via the validate-exp step. This is expected behavior — only workers with preferred names need validation.

**2. Date window returns meaningful data**
The transaction log criteria filters workers updated in the window, not specifically preferred name changes. A wide window may return many workers with no recent preferred name activity. Start with a narrow window — 7 to 14 days — and adjust based on volume.

**3. Anthropic API key has sufficient quota**
One API call fires per worker with a preferred name in the date window. Ensure your Anthropic account has sufficient credits before scheduling.

**4. Policy text fits within Claude's context**
The policy text is passed directly into the prompt per worker. Very long policy documents may push the prompt toward context limits. Keep policy text concise and focused on the key rules.

### Integration System Attributes
| Attribute Map | Attribute | Type | Description |
|---------------|-----------|------|-------------|
| Anthropic_Config | `API_Key` | Password | Anthropic API key from console.anthropic.com |
| Anthropic_Config | `Endpoint` | Text | Anthropic base URL — `https://api.anthropic.com/v1` |
| Anthropic_Config | `Claude_Model` | Text | Model ID e.g. `claude-sonnet-4-20250514` |
| Anthropic_Config | `Max_Tokens` | Number | Set to 100 — Claude only needs YES/NO + one sentence |

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | Date | Yes | Start of the worker update window |
| `to_date` | Date | Yes | End of the worker update window |
| `policy` | Text | Yes | Your preferred name policy text — pasted at runtime |
| `executive_names` | Text | Yes | Comma separated list of executive names Claude should flag |

### Prompt Built Per Worker
The prompt is constructed dynamically in Groovy per worker before each Claude call:

```
You are an HR policy validator. Review this preferred name
against the company policy below.

Policy: [policy launch param value]
Executive list: [executive_names launch param value]
Submitted preferred name: [worker preferred name from Workday]

Respond ONLY in this exact format:
DECISION: YES or NO
REASON: one sentence explanation

No other text. No exceptions.
```

### Example Claude Response
```
DECISION: NO
REASON: The submitted preferred name matches an executive name on the restricted list.
```

```
DECISION: YES
REASON: The preferred name appears appropriate and does not violate any policy criteria.
```

### Output
| File | Format | Destination |
|------|--------|-------------|
| `RPT.html` | HTML | Workday Document Repository — one entry per worker reviewed |
| `Log.html` | HTML | Workday Document Repository — cloud log audit trail |

### Flow Overview
```
Start → Init (launch params + attributes)
     → Get_Workers (Human_Resources v46.1) → Cloud log response
     → Splitter by bsvc:Worker → Per worker:
     → Extract legal name, preferred name, Worker ID
     → Skip if no preferred name (log and continue)
     → Build prompt dynamically with policy + exec list + preferred name
     → POST to Anthropic /v1/messages (max_tokens: 100)
     → JSON to XML → Extract DECISION + REASON
     → Write HTML fragment with worker context and Claude decision
     → Aggregator → Collect all fragments into single HTML body
     → Store RPT.html
     → Store Log.html → Integration Complete
```

### Error Handling
| Scenario | Severity | Behaviour |
|----------|----------|-----------|
| Get Workers WWS fails | ERROR | Cloud log, integration stops |
| Worker has no preferred name | ERROR | Cloud log per worker, splitter continues to next worker |
| Claude API POST fails | ERROR | Cloud log per worker, splitter continues to next worker |
| Unexpected error | CRITICAL | Global handler, PutIntegrationMessage |
| Success | INFO | Two INFO messages — WWS success and integration complete |

### 🤖 A Note on the YES/NO Pattern
The strict YES/NO format is intentional. Asking Claude for a binary decision plus a single sentence reason forces deterministic, auditable output that HR can act on without interpretation. The `max_tokens: 100` cap prevents Claude from going off-format. If Claude returns anything other than the expected format in testing, tighten the prompt with an explicit example of the exact output structure.

### 🎯 Adapting This Pattern
The YES/NO validator pattern is not limited to preferred names. The same structure works for any field where a written policy defines what is and isn't acceptable. To adapt it, change the `policy` launch parameter text and the XPath used to extract the field being validated. The rest of the flow — prompt construction, Claude call, aggregation, report — stays the same.

---
## How to Import a .clar File into Workday Studio

1. Open Workday Studio
2. Go to **File → Import → Existing Projects into Workspace**
3. Select **Select archive file** and browse to the `.clar` file
4. Click **Finish**
5. Configure your Integration System attributes before running

---

## Notes

- All credentials and endpoints are externalized via Integration System attributes — nothing is hardcoded
- Built and tested on Workday Studio 2026
- These files are original work shared freely for the Workday community

---

## Contributing

Have a Studio starter kit of your own? Feel free to open a PR. The goal is to build a library of clean, well-documented patterns for the Workday community.
---
## Supporting Me
If you want to support me and my repo! You can do so now by buying me a cup of coffee! You will be supporting my cafe meil! 

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow)](https://buy.stripe.com/cNibJ25yk97aaN9fUi5c400)
---

## Disclaimer

These integrations are provided as-is for educational purposes. Always review, test, and validate in a sandbox environment before deploying to production.