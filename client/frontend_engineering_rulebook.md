# 🌾 Farmer One Stop Solution  
# Frontend Engineering Rulebook & Architecture Standards

This document defines STRICT architectural rules for:

- Folder structure  
- State management  
- API integration  
- UI separation  
- Navigation  
- Error handling  
- Theming  
- Code conventions  

This is the single source of truth for all frontend developers.

---

# 1️⃣ FRONTEND ARCHITECTURE PHILOSOPHY

We follow:

> Feature-First Clean Architecture

Organized by:

- Business Feature first
- Technical Layer second

Frontend must be:

- Predictable
- Testable
- Replaceable
- API-agnostic
- Scalable to 1M+ users

---

# 2️⃣ ROOT CLIENT STRUCTURE (STRICT FORMAT)

```
client/lib/
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   ├── services/
│   ├── errors/
│   └── utils/
│
├── shared/
│   ├── widgets/
│   ├── models/
│   ├── enums/
│   └── extensions/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── marketplace/
│   ├── crops/
│   ├── disease/
│   ├── weather/
│   ├── alerts/
│   ├── crowdfunding/
│   ├── warehouse/
│   ├── communities/
│   ├── blog/
│   ├── chat/
│   └── profile/
│
├── router/
│   ├── app_router.dart
│   └── route_names.dart
│
└── main.dart
```

---

# 3️⃣ FEATURE STRUCTURE (MANDATORY)

Each feature must follow this structure:

```
feature-name/
│
├── data/
│   ├── models/
│   ├── dto/
│   ├── api/
│   ├── repository/
│   └── mappers/
│
├── domain/
│   ├── entities/
│   ├── repository_contract.dart
│   └── usecases/
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   ├── providers/
│   └── state/
│
└── routes.dart
```

---

# 4️⃣ LAYER RESPONSIBILITIES

## 🟢 DATA Layer

Contains:
- API calls
- DTOs
- Model parsing
- Repository implementation

Rules:
- No UI imports
- No Flutter widgets
- Only network & parsing logic
- No business decisions

---

## 🔵 DOMAIN Layer

Contains:
- Pure Dart code
- Business logic
- Use cases
- Entity definitions

Rules:
- No Flutter imports
- No HTTP imports
- No Firebase imports
- No Provider/Bloc imports

This makes domain portable.

---

## 🟣 PRESENTATION Layer

Contains:
- Screens
- Widgets
- State management
- UI-specific logic

Rules:
- No direct API calls
- No JSON parsing
- No DTO usage
- Use domain entities only

---

# 5️⃣ STATE MANAGEMENT RULES

Approved:
- Riverpod (preferred)
- Bloc (allowed)
- Provider (allowed for small modules)

Not allowed:
- setState for business logic
- Global variables
- Direct static state storage

Rules:
- One provider per feature
- No cross-feature provider dependency
- State must be immutable
- Use sealed states (Loading / Success / Error)

---

# 6️⃣ NETWORK LAYER RULES

Located in:

```
core/network/
```

Must contain:
- Base API client
- Interceptors
- Auth token injector
- Error parser

Rules:
- Only one HTTP client instance
- All API calls go through ApiClient
- No raw Dio/HTTP inside features
- Auto-attach JWT token
- Auto-handle 401 → redirect to login

---

# 7️⃣ API RESPONSE STANDARD

Backend returns:

```
{
  "success": true,
  "message": "...",
  "data": {}
}
```

Frontend must:
- Parse into ApiResponse<T>
- Never trust backend blindly
- Validate success flag
- Show message from server

---

# 8️⃣ ERROR HANDLING RULES

All errors must be converted to:

```
AppError
```

Types:
- NetworkError
- ServerError
- ValidationError
- UnauthorizedError
- UnknownError

UI must never receive raw exception.

---

# 9️⃣ NAVIGATION RULES

Centralized routing only.

Use:

```
router/app_router.dart
```

Rules:
- No Navigator.push inside widget directly
- Use named routes
- No hardcoded route strings
- Route guards for:
  - Auth required
  - Role-based access

---

# 🔟 THEME SYSTEM RULES

Theme must be centralized in:

```
core/theme/
```

Must include:
- Light theme
- Dark theme
- Color constants
- Typography
- Spacing system

Rules:
- No hardcoded colors
- No hardcoded font sizes
- Use theme extension

---

# 1️⃣1️⃣ WIDGET RULES

Widgets must be:
- Small
- Reusable
- Stateless whenever possible

Rules:
- No API calls in widget
- No heavy logic in widget
- Extract repeated UI to shared/widgets
- Max 300 lines per file

---

# 1️⃣2️⃣ PERFORMANCE RULES

Mandatory:
- Use const constructors
- Use ListView.builder
- Use pagination for large data
- Lazy load images
- Use caching for network images
- Debounce search fields
- Dispose controllers properly

No unnecessary rebuilds.

---

# 1️⃣3️⃣ FORM & VALIDATION RULES

Validation logic:
- Inside domain usecase OR
- Inside client validator

Never:
- Inline validation inside widget only

---

# 1️⃣4️⃣ OFFLINE STRATEGY (Future-Ready)

All repositories must be designed so:

Repository
   ↓
RemoteDataSource
   +
LocalDataSource

This enables:
- Future offline sync
- Caching
- Partial data availability

---

# 1️⃣5️⃣ TESTING RULES

Every feature must have:
- Unit tests (domain)
- Widget tests (UI)
- Repository tests (mock API)

No feature is complete without test coverage.

---

# 1️⃣6️⃣ SCALABILITY PRINCIPLE

Every feature must be designed so:
- It can become a separate Flutter module
- It can connect to a different backend
- It has no hard dependency on other features

No circular imports allowed.

---

# 1️⃣7️⃣ SECURITY RULES

- Never store JWT in plain SharedPreferences
- Use secure storage
- Sanitize all user input
- Mask sensitive fields
- Protect sensitive screens in future

---

# 1️⃣8️⃣ NAMING CONVENTIONS

Files → snake_case  
Classes → PascalCase  
Variables → camelCase  
Providers → featureNameProvider  
State → FeatureState  

---

# 1️⃣9️⃣ CODE REVIEW RULES

Every PR must check:
- No business logic in widget
- No API calls in presentation
- Proper error handling
- No hardcoded strings
- No debug prints
- No TODO in production

---

# 2️⃣0️⃣ FINAL FRONTEND ENGINEERING PRINCIPLE

We are not building screens.

We are building:
- A scalable client architecture
- A resilient mobile system
- A maintainable platform

Frontend must be:
- Modular
- Replaceable
- Predictable
- Testable
- Secure
- Performant

---

**This rulebook is mandatory for all contributors.**

