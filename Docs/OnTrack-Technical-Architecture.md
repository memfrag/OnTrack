
# OnTrack Technical Architecture Specification

## Purpose

This document is intended for code-generating LLMs and engineers implementing OnTrack.

The goal is to provide sufficient technical detail to generate production-quality Swift code and backend services.

---

# Technology Stack

## Apple Clients

- Swift 6
- SwiftUI
- SwiftData
- CloudKit
- Charts
- WidgetKit
- AppIntents
- BackgroundTasks
- AuthenticationServices

Minimum targets:

- iOS 27+
- macOS 27+

---

# Repository Structure

OnTrack/

├── apps/
│   ├── ios/
│   └── macos/
│
├── shared/
│   ├── Models/
│   ├── Services/
│   ├── Sync/
│   ├── Analytics/
│   ├── Charts/
│   └── Utilities/
│
├── backend/
│   ├── API/
│   ├── Database/
│   ├── Withings/
│   └── Webhooks/
│
└── docs/

---

# SwiftData Models

## WeightEntry

```swift
@Model
final class WeightEntry {

    @Attribute(.unique)
    var id: UUID

    var timestamp: Date

    var weightKg: Double

    var source: EntrySource

    var note: String?

    var externalMeasurementId: String?

    var createdAt: Date

    var updatedAt: Date
}
```

## EntrySource

```swift
enum EntrySource: String, Codable {
    case manual
    case withings
}
```

## WeightGoal

```swift
@Model
final class WeightGoal {

    var targetWeightKg: Double

    var targetDate: Date?
}
```

## SyncMetadata

```swift
@Model
final class SyncMetadata {

    var lastSyncDate: Date?

    var lastSuccessfulImportDate: Date?
}
```

---

# CloudKit Strategy

## Database

Use:

Private CloudKit Database

Never use Public Database.

## Sync Ownership

Each user owns all records.

No sharing required in v1.

## Record Types

WeightEntry
WeightGoal
SyncMetadata

## Conflict Resolution

Last-write-wins.

Manual edits always override older values.

---

# Analytics Engine

## Trend Weight

Use rolling average.

Default:

7-day moving average.

Formula:

trendWeight =
average(last7Days)

## Weekly Change

weeklyChange =
currentTrend - previousWeekTrend

## Goal Forecast

remainingWeight =
currentTrend - targetWeight

estimatedDays =
remainingWeight / dailyRate

estimatedGoalDate =
today + estimatedDays

---

# Withings Architecture

## Authentication Flow

Client:

1. Open authorization URL.
2. Launch ASWebAuthenticationSession.
3. Receive authorization code.
4. Send code to backend.

Backend:

1. Exchange code.
2. Store tokens.
3. Return success.

---

# Token Storage

Database table:

WithingsAccount

Fields:

id
userId
accessToken
refreshToken
expiresAt
createdAt
updatedAt

Refresh tokens replace previous refresh tokens after each refresh.

---

# Measurement Import

## Initial Import

Fetch entire measurement history.

Store measurement identifiers.

Prevent duplicates.

## Incremental Import

Fetch only measurements newer than:

lastSuccessfulImportDate

---

# Backend Database

## Users

id
appleUserIdentifier
createdAt

## WithingsAccounts

id
userId
accessToken
refreshToken
expiresAt

## ImportedMeasurements

id
userId
externalMeasurementId
timestamp
weightKg

---

# Backend APIs

## POST /oauth/withings/callback

Request:

```json
{
  "code": "authorization_code"
}
```

Response:

```json
{
  "success": true
}
```

---

## GET /measurements

Response:

```json
{
  "measurements": []
}
```

---

## POST /sync

Response:

```json
{
  "imported": 12
}
```

---

# Webhooks

Endpoint:

POST /webhooks/withings

Workflow:

1. Notification received.
2. Validate source.
3. Refresh token if needed.
4. Fetch new measurements.
5. Persist data.
6. Trigger client refresh.

---

# Sync Services

## MeasurementSyncService

Responsibilities:

- import measurements
- deduplicate
- persist locally

## CloudSyncService

Responsibilities:

- CloudKit sync
- merge handling

## WithingsService

Responsibilities:

- authentication
- measurement retrieval

---

# Deduplication Rules

Primary key:

externalMeasurementId

Fallback:

timestamp + weightKg

Ignore duplicates.

---

# Charts

## Main Trend Chart

Series:

1. Raw Weight
2. Trend Weight

Trend line emphasized.

Raw data visually secondary.

## Time Ranges

- 7D
- 30D
- 90D
- 1Y
- All

---

# Widget Architecture

## Small Widget

Current weight.

## Medium Widget

Current weight.
Trend weight.
Goal progress.

Refresh after CloudKit updates.

---

# Background Refresh

## iOS

Use:

BGAppRefreshTask

Triggers:

- app launch
- push notification
- scheduled refresh

## macOS

Refresh when app launches.

Periodic refresh while running.

---

# CSV Import

Expected schema:

timestamp,weight_kg,source,note

Validate:

- timestamp exists
- weight > 0

Reject invalid rows.

---

# Error Handling

## Authentication Errors

Display:

"Unable to connect to Withings."

## Sync Errors

Display:

"Sync failed. Will retry automatically."

## Network Errors

Retry with exponential backoff.

---

# Logging

Development:

OSLog

Production:

OSLog only.

No third-party analytics in v1.

---

# Testing Strategy

## Unit Tests

AnalyticsEngine
ForecastEngine
CSVImporter
MeasurementDeduplicator

## Integration Tests

CloudKit sync
OAuth flow
Webhook ingestion

## UI Tests

Create entry
Delete entry
Connect Withings
Goal creation

---

# Security Requirements

Never expose:

- client secret
- refresh tokens

All API communication:

HTTPS only.

Store credentials securely.

---

# Future Expansion

Potential v2 models:

BodyFatEntry
MuscleMassEntry
WaterPercentageEntry

Keep current architecture extensible.

---

# Coding Standards

- MVVM
- Dependency Injection
- Async/Await
- No singleton business logic
- Testable services
- SwiftLint enabled

---

# MVP Delivery Order

Phase 1:
- data models
- manual entries

Phase 2:
- charts
- goals

Phase 3:
- CloudKit

Phase 4:
- Withings OAuth

Phase 5:
- automatic sync

Phase 6:
- widgets

The implementation should prioritize simplicity, reliability, and maintainability over abstraction.
