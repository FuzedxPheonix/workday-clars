# Workday Studio Starter Kits

A growing collection of Workday Studio `.clar` files built from scratch as learning resources and community contributions. This repo is updated on an ongoing basis as new integrations are built. These are **not production-ready solutions** — they are starter kits to help you understand patterns and accelerate your own builds.

---

## Files

| File | Description | Last Updated |
|------|-------------|--------------|
| `INT_Aladtech.clar` | REST API integration between Workday and Aladtec for time-off data | 2026 |
| `INT_ADP_Oauth_Example.clar` | ADP Workforce Now OAuth 2.0 integration with worker data retrieval | 2026 |
| `INT_ADP_Upload_Worker_Image_Example.clar` | ADP worker photo upload via multipart/form-data with Groovy binary handling | 2026 |
| `INT_EIB_File_Router.clar` | EIB output file renaming by schedule type (monthly/weekly) without cloning | 2026 |
| `INT_NewHire_VendorSync.clar` | New hire worker data + photo sync to vendor via SFTP — AI-assisted build | 2026 |

---

## Aladtec Time-Off Integration

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
- XPath namespace map on Get_Worker_Photos response — required for correct field extraction
- Handling for workers with no photo on file
- Retry logic on failed upload
- Full validation of ADP response codes

### Launch Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Worker` | text | Yes | Employee ID of the worker whose photo will be uploaded |

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

## Disclaimer

These integrations are provided as-is for educational purposes. Always review, test, and validate in a sandbox environment before deploying to production.