# Claude Code Session Instructions for TripSync

## 🚀 Quick Start for New Sessions

When starting a new session, **ALWAYS** perform these steps first to understand the project context:

### 1. Read Project Documentation
```bash
# Read the complete developer summary
Read Documentation/TripSync_COMPLETE_Developer_Summary.txt

# Review wireframes (HTML file - can be opened in browser)
Read Documentation/Wireframes/TripSync\ -\ Complete\ Low-Fi\ UI\ Wireframes.html

# Check project management files
Read Documentation/ProjectManagement/TripSync_Trello_Backlog.txt
Read Documentation/ProjectManagement/TripSync_Trello_Board_Organization.txt
```

### 2. Understand Project Structure
```bash
# Scan the organized project structure
find . -type f -name "*.swift" | head -20
ls -la Models/ ViewControllers/ Services/ Extensions/ Utils/
```

### 3. Core Project Context

**Student:** Tien Tran (tgtien286@gmail.com)  
**Project:** TripSync - iOS Travel Companion App  
**Architecture:** Core Data + Firebase hybrid approach  

**Key Features to Implement:**
- Trip organization & planning
- Document management 
- Real-time flight integration
- QR code sharing
- Budget planning with currency conversion
- Calendar integration
- Offline access capabilities

**Target Audience:** Business travelers, digital nomads, organized leisure travelers (22-45 years)

### 4. Current Implementation Status

**✅ Completed:**
- Basic project structure with organized folders
- Core Data models: Trip, Participant, Activity
- Services layer: CoreDataManager, FirebaseManager (skeleton)
- Basic view controllers: TripListViewController
- Extensions and utilities
- Comprehensive documentation moved into project

**🔄 Next Steps:**
- Implement Core Data entities in .xcdatamodeld
- Add Firebase SDK and configure
- Build UI components based on wireframes
- Implement trip creation/management features
- Add document management capabilities

### 5. Development Guidelines

- **Follow iOS best practices** and existing code patterns
- **Reference wireframes** for UI design decisions (flexible, not strict)
- **Use hybrid approach**: Core Data for local storage, Firebase for sync
- **Maintain offline capabilities** as core requirement
- **Follow the existing folder organization**

### 6. Git Configuration

**Repository:** Personal use, not GitLab  
**User:** Tien Tran <tgtien286@gmail.com>  
**Ignored:** .claude/ folder (Claude Code workspace)

## 📋 Session Checklist

- [ ] Read Documentation/TripSync_COMPLETE_Developer_Summary.txt
- [ ] Review wireframes HTML file  
- [ ] Scan project files to understand current implementation
- [ ] Understand the Core Data + Firebase hybrid approach
- [ ] Check current todo list and project priorities

---

*This file helps maintain context between Claude Code sessions for consistent development progress.*