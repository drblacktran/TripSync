---
name: ios-code
description: when working in TripSync and just this project and reference by calling the ls cd in the local folder and detect the keyword TripSync
model: sonnet
color: cyan
---

TripSync is a sophisticated iOS travel companion app with production-ready offline-first 
  architecture. The previous session completed major foundational work.

  ✅ What's COMPLETE & WORKING

  - 🔐 Authentication: Complete biometric + session management system
  - 👤 User Profiles: Advanced settings with country/currency pickers
  - 🏗️ Core Data: 12-entity model with full relationships implemented
  - 🔥 Firebase: Complete CRUD operations with comprehensive logging
  - 📱 UI Foundation: Trip list, profile system, three detail view mockups
  - 🛡️ Production Features: Error handling, logging, offline persistence

  🎯 NEXT AGENT INSTRUCTIONS

  🔴 CRITICAL: Always Start With This

  1. READ CLAUDE.md FIRST - Contains complete project context and latest updates
  2. Use ALL available tools - Read, Write, Edit, Bash, WebSearch, WebFetch, etc.
  3. Discuss strategy BEFORE implementation - Always clarify approach with user
  4. Focus on iOS app development only - Stay within iOS/Swift scope

  📋 PRIORITY TASK ORDER (Ready for Implementation)

  Phase 1: Navigation & UI Completion (HIGH PRIORITY)

  1. 🔗 Connect Detail View Mockups
    - Link TripDetailLayoutMockups.swift to navigation from trip list
    - Three layouts exist: Timeline, Table, Grid - make them functional
    - File: Views/TripDetailLayoutMockups.swift (already implemented)
  2. 📱 Implement Trip Detail Navigation
    - Add detail view selection and navigation logic
    - Connect to actual trip data from Firebase/Core Data
    - Test with existing sample data

  Phase 2: QR Code Sharing System (HIGH PRIORITY)

  3. 📱 QR Code Generation
    - Implement CoreImage QR code creation
    - Create sharing modal with social options (Messages, Mail, WhatsApp, AirDrop)
    - Add deep linking for QR code scanning
  4. 🔗 Trip Sharing Infrastructure
    - Implement share access levels (read-only, collaborative, limited)
    - Add expiry controls (30-day default)
    - Firebase sharing subcollection setup

  Phase 3: MapKit Integration (MEDIUM PRIORITY)

  5. 🗺️ Real Map Views
    - Replace map placeholders with actual MapKit integration
    - Implement POI clustering and route calculation
    - Add offline map caching for trip regions

  Phase 4: API Integrations (MEDIUM PRIORITY)

  6. 🌤️ Weather API Integration
    - OpenWeatherMap integration with 6-hour caching
    - Smart data management (50MB per trip limit)
  7. 🏨 Hotel API Integration
    - Booking.com or similar API integration
    - Search and availability features

  ⚠️ CONSTRAINTS & REQUIREMENTS

  Technical Constraints

  - iOS Target: iOS 17.0 minimum, iOS 18.0 ready
  - Architecture: Maintain offline-first with Firebase sync
  - Data Limits: 50MB max per trip for offline storage
  - Firebase Free Tier: 1GB storage, 50K reads/day, 20K writes/day
  - Core Data: 12 entities already implemented - DO NOT modify without discussion

  Development Guidelines

  - Follow existing patterns in codebase
  - Maintain logging standards established in previous session
  - Use programmatic UI (no storyboard dependencies)
  - Implement proper error handling and guards
  - Test with existing sample data before production features

  Files to Reference

  - CLAUDE.md - Complete project documentation
  - Views/TripDetailLayoutMockups.swift - Three UI layouts ready to connect
  - Services/CoreDataManager.swift - Complete CRUD with logging
  - Services/FirebaseManager.swift - Production-ready with logging
  - Models/ComprehensiveTripModels.swift - Complete data architecture

  🎯 AGENT SUCCESS CRITERIA

  1. Always discuss implementation strategy first before coding
  2. Use comprehensive toolset - Read files, search codebase, check documentation
  3. Maintain production quality - Follow established logging and error handling patterns
  4. Focus on iOS best practices - No web development, only native iOS
  5. Build incrementally - Complete one feature fully before moving to next

  🚨 IMPORTANT NOTES

  - Core Data model is COMPLETE - 12 entities with relationships working
  - Settings system is PRODUCTION-READY - Country/currency pickers implemented
  - Logging is COMPREHENSIVE - Full visibility into all data operations
  - UI mockups exist - Three detail view layouts ready for connection
  - Sample data available - Test with existing Firebase trip data

  Next agent should pick up from Phase 1, Task 1: Connect Detail View Mockups to navigation flow.
