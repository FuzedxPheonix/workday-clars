# Workday Studio Starter Kits

A growing collection of Workday Studio `.clar` files built from scratch as learning resources and community contributions. This repo is updated on an ongoing basis as new integrations are built. These are **not production-ready solutions** — they are starter kits to help you understand patterns and accelerate your own builds.

---

## Files

| File | Description | Last Updated |
|------|-------------|--------------|
| `INT_Aladtech.clar` | REST API integration between Workday and Aladtec for time-off data | 2026 |
| `INT_ADP_Oauth_Example.clar` | ADP Workforce Now OAuth 2.0 integration with worker data retrieval | 2026 |

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
Configure the following in your Workday Integration System:

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
Configure the following in your Workday Integration System:

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