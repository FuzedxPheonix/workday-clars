# Workday Studio Starter Kits

A growing collection of Workday Studio `.clar` files built from scratch as learning resources and community contributions. This repo is updated on an ongoing basis as new integrations are built. These are **not production-ready solutions** — they are starter kits to help you understand patterns and accelerate your own builds.

---

## Files

| File | Description | Last Updated |
|------|-------------|--------------|
| `INT_Aladtech.clar` | REST API integration between Workday and Aladtec for time-off data | 2025 |

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

## How to Import a .car File into Workday Studio

1. Open Workday Studio
2. Go to **File → Import → Existing Projects into Workspace**
3. Select **Select archive file** and browse to the `.car` file
4. Click **Finish**
5. Configure your Integration System attributes before running

---

## Notes

- All credentials and endpoints are externalized via Integration System attributes — nothing is hardcoded
- Built and tested on Workday Studio 2025
- These files are original work shared freely for the Workday community

---

## Contributing

Have a Studio starter kit of your own? Feel free to open a PR. The goal is to build a library of clean, well-documented patterns for the Workday community.

---

## Disclaimer

These integrations are provided as-is for educational purposes. Always review, test, and validate in a sandbox environment before deploying to production.