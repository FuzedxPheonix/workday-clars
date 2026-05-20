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