
# OnTrack PRD

## Executive Summary

OnTrack is a native Apple ecosystem application for weight tracking and trend analysis.
Its primary value proposition is automatic weight collection from Withings smart scales and
clear visualization of long-term trends rather than daily fluctuations.

Target platforms:
- iOS
- macOS

Core principles:
- Privacy-first
- Native Apple UI
- Trend-focused
- Automatic sync
- No calorie tracking
- No social features

---

# Goals

1. Automatically import weight data from Withings.
2. Present meaningful trend analysis.
3. Sync across Apple devices.
4. Require near-zero user effort.
5. Feel like a first-party Apple app.

---

# User Stories

### Initial Setup

As a user,
I want to connect my Withings account,
so that my weight is imported automatically.

### Daily Use

As a user,
I want to open the app and immediately understand whether I am progressing toward my goal.

### Historical Analysis

As a user,
I want to review months or years of measurements.

### Device Sync

As a user,
I want my data available on all Apple devices.

---

# Architecture

## High-Level

Withings Scale
→ Withings Cloud
→ OnTrack Backend
→ CloudKit
→ iPhone App
→ Mac App

## Components

### Client Apps

Responsibilities:
- UI
- Local storage
- Charts
- Goal calculations
- CloudKit sync

### Backend

Responsibilities:
- OAuth
- Token storage
- Token refresh
- Webhook handling
- Measurement ingestion

### CloudKit

Responsibilities:
- Cross-device sync
- Offline support
- Conflict resolution

---

# Data Model

## WeightEntry

```swift
@Model
final class WeightEntry {
    var id: UUID
    var timestamp: Date
    var weightKg: Double
    var source: String
    var note: String?
    var externalId: String?
    var createdAt: Date
    var updatedAt: Date
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

# Trend Engine

## Trend Weight

Use rolling averages.

Default:
- 7-day average

Additional:
- 30-day average

## Weekly Change

Formula:

weeklyChange =
(currentTrend - priorTrend)

## Forecasting

estimatedDays =
remainingWeight / averageDailyLoss

estimatedGoalDate =
today + estimatedDays

---

# Screens

## Overview

Sections:

### Current Weight

Shows:
- latest weight
- measurement time

### Trend Weight

Shows:
- 7-day average

### Weekly Change

Shows:
- kg/week

### Goal Progress

Shows:
- target
- remaining
- percent complete

### Forecast

Shows:
- projected goal date

### Recent Measurements

Shows:
- last 10 entries

---

## Entries Screen

Capabilities:
- list entries
- search entries
- edit manual entries
- delete manual entries

Columns:
- date
- time
- weight
- source

---

## Statistics

Metrics:

- highest weight
- lowest weight
- average weight
- largest weekly loss
- largest weekly gain
- total measurements

Time ranges:

- 30 days
- 90 days
- 1 year
- all time

---

## Goals

Capabilities:
- create goal
- edit goal
- remove goal

---

## Settings

Sections:

### Account

Withings status

### Appearance

- system
- light
- dark

### Units

- kg
- lb

### Data

- export CSV
- import CSV

---

# Charts

Framework:
Apple Charts

## Main Trend Chart

Series:
- raw weight
- trend weight

Ranges:
- 7D
- 30D
- 90D
- 1Y
- All

Interactions:
- hover (macOS)
- drag (iOS)

---

# Withings Integration

## OAuth

Client launches authentication session.

Backend exchanges code.

Store:
- access token
- refresh token

## Token Refresh

Automatic refresh before expiration.

## Initial Import

Import full history.

Deduplicate using external identifiers.

## Incremental Sync

Triggered via webhook.

---

# Backend API

## POST /oauth/withings/callback

Exchange authorization code.

## POST /webhooks/withings

Receive notifications.

## GET /measurements

Fetch user measurements.

## POST /sync

Trigger manual sync.

---

# CloudKit

Use private database.

Requirements:

- automatic sync
- offline support
- conflict resolution

---

# Widgets

## Small

Current Weight

## Medium

Current Weight
Trend Weight
Goal Progress

---

# Menu Bar App (macOS)

Capabilities:

- show current weight
- quick add weight
- open app

---

# CSV Format

timestamp,weight_kg,source,note

Example:

2026-06-23T07:30:00Z,72.4,withings,

---

# Accessibility

Requirements:

- VoiceOver support
- Dynamic Type
- Keyboard navigation
- High contrast support

---

# Performance

Startup:
< 500 ms

Dashboard rendering:
< 100 ms

10,000+ entries supported.

---

# Security

Never store Withings client secret on device.

Store tokens server-side.

Use HTTPS everywhere.

Encrypt sensitive data at rest.

---

# Roadmap

## v1

- manual entries
- Withings sync
- charts
- goals
- CloudKit sync
- widgets

## v1.1

- additional body metrics
- enhanced insights

## v2

- Apple Health import
- advanced forecasting

---

# Explicit Non-Goals

- calorie tracking
- nutrition tracking
- workout tracking
- social feeds
- AI coach
- subscriptions in v1
- advertisements

The application should excel at a single task:
providing a clear understanding of weight trends and progress.
