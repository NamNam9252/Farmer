# 🌾 Farmer One Stop Solution
## Engineering Rulebook & Architecture Standards

This document defines STRICT architectural rules for:
- Folder structure
- Middleware & schema separation
- API design
- Response standards
- Client & server structure
- Coding conventions

This is the single source of truth for all developers.

---

# 1️⃣ ARCHITECTURE PHILOSOPHY

We follow a **Hybrid Modular Architecture**:

- Global concerns → `core/`
- Business domains → `modules/`
- Cross-feature validation → `schema/`
- Cross-feature middleware → `middleware/`

We organize by:
> Business Domain first, Technical Layer second.

---

# 2️⃣ SERVER STRUCTURE (STRICT FORMAT)

```
server/
│
├── src/
│   ├── core/
│   │   ├── config/
│   │   ├── constants/
│   │   ├── types/
│   │   └── utils/
│   │
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   ├── rate-limit.middleware.ts
│   │   └── logger.middleware.ts
│   │
│   ├── schema/
│   │   ├── user.schema.ts
│   │   ├── crop.schema.ts
│   │   ├── marketplace.schema.ts
│   │   ├── loan.schema.ts
│   │   └── disease.schema.ts
│   │
│   ├── modules/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── marketplace/
│   │   ├── crops/
│   │   ├── disease/
│   │   ├── weather/
│   │   ├── alerts/
│   │   ├── crowdfunding/
│   │   ├── warehouse/
│   │   ├── news/
│   │   └── chat/
│   │
│   ├── routes.ts
│   ├── app.ts
│   └── server.ts
│
└── prisma/
    └── schema.prisma
```

---

# 3️⃣ MIDDLEWARE RULES

## What Goes Inside `/middleware`?

Only GLOBAL cross-cutting logic.

Allowed:
- Authentication
- Role authorization
- Error handling
- Rate limiting
- Logging
- File upload control

Not Allowed:
- Business logic
- Database queries
- Feature-specific rules

Middleware must:
- Be reusable
- Not depend on a specific module
- Not import feature services

---

# 4️⃣ SCHEMA RULES

`/schema/` contains Zod validation schemas.

Each schema file:
- Contains only validation
- No database logic
- No business rules
- No external service calls

Example responsibility:
- Field validation
- Required fields
- Type validation
- Input transformation

Business rules belong in Service layer.

---

# 5️⃣ MODULE STRUCTURE RULE

Each module must contain:

```
module-name/
│
├── module.controller.ts
├── module.service.ts
├── module.repository.ts
└── module.routes.ts
```

## Responsibilities

Controller:
- Accept request
- Call validation schema
- Call service
- Return formatted response

Service:
- Business logic
- Orchestrate repositories
- Apply rules

Repository:
- Prisma only
- No logic

Routes:
- Define API endpoints

---

# 6️⃣ API DESIGN STANDARDS

## Versioning

All routes must start with:

```
/api/v1/
```

---

## REST Naming Rules

Correct:
- GET /api/v1/marketplace/products
- POST /api/v1/marketplace/products
- PATCH /api/v1/marketplace/products/:id
- DELETE /api/v1/marketplace/products/:id

Incorrect:
- /createProduct
- /getAllProducts

---

# 7️⃣ STANDARD API RESPONSE FORMAT (MANDATORY)

Every response must follow this structure:

Success:

```
{
  "success": true,
  "message": "Readable message",
  "data": {}
}
```

Error:

```
{
  "success": false,
  "message": "Error description",
  "error": {}
}
```

Rules:
- Never return raw database output
- Never expose internal stack traces
- Always send meaningful messages

---

# 8️⃣ ERROR HANDLING STANDARD

- All errors go through `error.middleware.ts`
- No try/catch inside controller unless necessary
- Use custom error classes

---

# 9️⃣ DATABASE RULES

- All DB logic inside repository
- No direct Prisma in controller
- No raw SQL inside service
- Every entity must link to FarmerProfile where applicable

---

# 🔟 CLIENT STRUCTURE (FLUTTER)

```
client/lib/
│
├── core/
│   ├── theme/
│   ├── constants/
│   ├── services/
│   ├── network/
│   └── utils/
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
│   ├── news/
│   └── chat/
│
├── shared/
│   ├── widgets/
│   ├── models/
│   └── providers/
│
└── main.dart
```

---

# 1️⃣1️⃣ CLIENT FEATURE STRUCTURE

```
feature-name/
│
├── data/
│   ├── models/
│   ├── api/
│   └── repository/
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
│
└── routes.dart
```

Rules:
- API calls only inside data/api
- No UI logic inside repository
- No network call inside widget

---

# 1️⃣2️⃣ NAMING CONVENTIONS

Files → kebab-case
Variables → camelCase
Classes → PascalCase
API Routes → lowercase REST

---

# 1️⃣3️⃣ DEVELOPMENT RULES

- One developer owns one module
- No editing other modules without approval
- All APIs documented in shared Postman collection
- Schema changes must be logged
- Every new feature must include validation

---

# 1️⃣4️⃣ SCALABILITY PRINCIPLE

Design every module so it can later become a microservice.

This means:
- No circular dependencies
- No shared database access outside repository
- Clear input/output contracts

---

# FINAL ENGINEERING PRINCIPLE

We are not building screens.
We are building systems.

Every feature must be:
- Modular
- Replaceable
- Testable
- Predictable
- Secure

This rulebook is mandatory for all contributors.

