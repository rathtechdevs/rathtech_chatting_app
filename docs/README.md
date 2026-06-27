# SecureChat — Software Design Documentation

## Overview

SecureChat is a production-ready, end-to-end encrypted private messaging application built exclusively for two users. This documentation is the single source of truth for the entire development process.

**Technology Stack:** Flutter · Supabase · Signal Protocol · Firebase Cloud Messaging  
**Architecture:** Clean Architecture · MVVM · Riverpod · GoRouter · Material 3

---

## Quick Start for Developers

1. Read `00_Project_Overview.md` — understand what we're building and why
2. Read `05_Clean_Architecture.md` — understand the mandatory architecture rules
3. Read `34_AI_Development_Rules.md` — understand the mandatory coding rules
4. Follow the milestones in `30_Roadmap.md`
5. Track progress in `31_Project_Checklist.md`

---

## Document Index

| # | Document | Description |
|---|---|---|
| 00 | [Project Overview](00_Project_Overview.md) | Product summary, tech stack, key decisions |
| 01 | [Product Requirements](01_Product_Requirements.md) | What the product must do and why |
| 02 | [Functional Requirements](02_Functional_Requirements.md) | Detailed testable requirements |
| 03 | [Non-Functional Requirements](03_Non_Functional_Requirements.md) | Performance, security, reliability targets |
| 04 | [System Architecture](04_System_Architecture.md) | C4 diagrams, data flows, ADRs |
| 05 | [Clean Architecture](05_Clean_Architecture.md) | Layer rules, DI, anti-patterns |
| 06 | [Feature Breakdown](06_Feature_Breakdown.md) | Feature inventory with priority and complexity |
| 07 | [User Flows](07_User_Flows.md) | Complete user journeys with decision trees |
| 08 | [Database Design](08_Database_Design.md) | PostgreSQL schema, RLS policies, SQLite schema |
| 09 | [API Architecture](09_API_Architecture.md) | Supabase API contracts, Realtime, Edge Functions |
| 10 | [Security Architecture](10_Security_Architecture.md) | Threat model, defenses, key management |
| 11 | [Encryption Architecture](11_Encryption_Architecture.md) | Signal Protocol: X3DH, Double Ratchet |
| 12 | [Authentication](12_Authentication.md) | Auth flows, session management, deep links |
| 13 | [State Management](13_State_Management.md) | Riverpod providers, ViewModels, state shapes |
| 14 | [Routing](14_Routing.md) | GoRouter, routes, guards, deep links |
| 15 | [UI/UX Guidelines](15_UI_UX_Guidelines.md) | Design principles, Material 3, accessibility |
| 16 | [Animation System](16_Animation_System.md) | Animation catalog, performance rules |
| 17 | [Theme System](17_Theme_System.md) | Colors, typography, dark mode, chat backgrounds |
| 18 | [Component Library](18_Component_Library.md) | Reusable widget catalog |
| 19 | [Folder Structure](19_Folder_Structure.md) | Complete file and directory layout |
| 20 | [Data Models](20_Data_Models.md) | Entities, value objects, DTOs, mappers |
| 21 | [Repository Pattern](21_Repository_Pattern.md) | Interfaces, implementations, error conversion |
| 22 | [Offline Strategy](22_Offline_Strategy.md) | Outbox queue, gap fill, connectivity UI |
| 23 | [Realtime Architecture](23_Realtime_Architecture.md) | Supabase Realtime channels, presence |
| 24 | [Notification System](24_Notification_System.md) | FCM, push payload, all app states |
| 25 | [File Storage](25_File_Storage.md) | Media encryption, upload, download, cache |
| 26 | [Error Handling](26_Error_Handling.md) | Failure types, Either pattern, UI presentation |
| 27 | [Testing Strategy](27_Testing_Strategy.md) | Test types, coverage, patterns |
| 28 | [Performance Strategy](28_Performance_Strategy.md) | Targets, optimization techniques |
| 29 | [Deployment](29_Deployment.md) | Build, signing, Supabase, release checklist |
| 30 | [Roadmap](30_Roadmap.md) | Milestones, deliverables, dependencies |
| 31 | [Project Checklist](31_Project_Checklist.md) | Master feature checklist |
| 32 | [Risks and Assumptions](32_Risks_and_Assumptions.md) | Technical and product risks, mitigations |
| 33 | [Development Guidelines](33_Development_Guidelines.md) | Coding standards, git workflow, code review |
| 34 | [AI Development Rules](34_AI_Development_Rules.md) | Mandatory rules for all code generation |

---

## Architecture at a Glance

```
Flutter App (Clean Architecture)
┌──────────────────────────────────────────────────┐
│  Presentation  │  Domain (Pure Dart)  │  Data     │
│  Riverpod MVVM │  Use Cases           │  Repos    │
│  GoRouter      │  Entities            │  Supabase │
│  Material 3    │  Value Objects       │  SQLite   │
└──────────────────────────────────────────────────┘
         │ HTTPS + WebSocket (TLS 1.3)
┌──────────────────────────────────────────────────┐
│              Supabase Backend                     │
│  Auth · PostgreSQL · Realtime · Storage · Deno   │
└──────────────────────────────────────────────────┘
         │ Signal Protocol (client-side only)
┌──────────────────────────────────────────────────┐
│  Server NEVER reads message plaintext             │
│  Keys NEVER leave device                          │
│  Forward secrecy on every message                 │
└──────────────────────────────────────────────────┘
```

---

## Core Principle

> The server stores only ciphertext. The app stores decrypted messages locally only. Private keys never leave the device. This is not a goal — it is a constraint enforced at every layer.

---

## Current Status

**Phase:** Pre-development (documentation complete)  
**Next Step:** M0 Foundation — set up dependencies, folder structure, and core wiring  
**See:** `30_Roadmap.md` for complete milestone plan  
**Track:** `31_Project_Checklist.md` for feature-level progress
