# Farmer Application API Routes Documentation

Below is a list of all current routes implemented on the server, their expected input payloads, and the expected responses.

---

## 1. Authentication Routes
Base Path: `/api/v1/auth`

### A. Signup
- **Endpoint:** `POST /api/v1/auth/signup`
- **Description:** Registers a new user.
- **Request Body (JSON):**
  ```json
  {
    "name": "string (min 2 chars)",
    "phone": "string (min 10 digits)",
    "password": "string (min 6 chars)",
    "role": "FARMER" | "BUYER" | "LABOR" | "EXPERT" | "ADMIN",
    "email": "string (optional)"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "User registered successfully",
    "data": { 
      "user": { 
        "id": "ObjectId",
        "name": "string",
        "phone": "string",
        "email": "string | null",
        "role": "FARMER | BUYER | LABOR | EXPERT | ADMIN",
        "status": "PENDING_VERIFICATION",
        "isEmailVerified": false,
        "preferredLanguage": "hi",
        "isPhoneVerified": false,
        "profileImageUrl": "string | null",
        "createdAt": "date-string"
      }, 
      "token": "jwt_token_string" 
    }
  }
  ```

### B. Login
- **Endpoint:** `POST /api/v1/auth/login`
- **Description:** Authenticates an existing user and returns a token.
- **Request Body (JSON):**
  ```json
  {
    "phone": "string (min 10 digits)",
    "password": "string (min 6 chars)"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": { 
      "user": { 
        "id": "ObjectId",
        "name": "string",
        "phone": "string",
        "email": "string | null",
        "role": "FARMER | BUYER | LABOR | EXPERT | ADMIN",
        "status": "ACTIVE | PENDING_VERIFICATION",
        "isEmailVerified": boolean,
        "preferredLanguage": "string",
        "isPhoneVerified": boolean,
        "profileImageUrl": "string | null",
        "createdAt": "date-string"
      }, 
      "token": "jwt_token_string"  
    }
  }
  ```

### C. Request OTP
- **Endpoint:** `POST /api/v1/auth/request-otp`
- **Description:** Requests an OTP to be sent to the user's email.
- **Request Body (JSON):**
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "OTP sent to email."
  }
  ```

### D. Verify OTP
- **Endpoint:** `POST /api/v1/auth/verify-otp`
- **Description:** Verifies an OTP sent to the user's email to activate their account.
- **Request Body (JSON):**
  ```json
  {
    "email": "user@example.com",
    "otp": "123456"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Email verified successfully",
    "data": { 
      "user": { 
        "id": "ObjectId",
        "name": "string",
        "phone": "string",
        "email": "string",
        "role": "FARMER | BUYER | LABOR | EXPERT | ADMIN",
        "status": "ACTIVE",
        "isEmailVerified": true,
        "preferredLanguage": "hi",
        "isPhoneVerified": false,
        "profileImageUrl": "string | null",
        "createdAt": "date-string"
      }, 
      "token": "jwt_token_string" 
    }
  }
  ```

---

## 2. User & Profile Routes
Base Path: `/api/v1/users`
*(All routes require Bearer Token Authentication)*

### A. Set Primary Location
- **Endpoint:** `POST /api/v1/users/location`
- **Description:** Records spatial coordinates and creates the primary location data for the user.
- **Request Body (JSON):**
  ```json
  {
    "type": "HOME" | "FARM" | "WAREHOUSE" | "DELIVERY" | "COMMUNITY_HUB" | "ALERT_ZONE" | "OTHER",
    "label": "string (optional)",
    "stateId": "string (ObjectId)",
    "districtId": "string (ObjectId)",
    "pincodeId": "string (ObjectId)",
    "village": "string (optional)",
    "addressLine": "string (optional)",
    "latitude": 12.345,
    "longitude": 67.890
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Location created successfully",
    "data": { ...locationSchema }
  }
  ```

### B. Create Farmer Profile
- **Endpoint:** `POST /api/v1/users/profile/farmer`
- **Description:** Creates the farmer specific profile fields.
- **Request Body (JSON):**
  ```json
  {
    "totalLandArea": 5.5,
    "experienceYears": 10,
    "aadhaarLast4": "1234"
  }
  ```

### C. Create Labor Profile
- **Endpoint:** `POST /api/v1/users/profile/labor`
- **Description:** Creates the labor specific profile fields.
- **Request Body (JSON):**
  ```json
  {
    "skills": ["Harvesting", "Plowing"],
    "experienceYears": 5,
    "dailyRate": 500,
    "serviceRadiusKm": 20
  }
  ```

### D. Create Expert Profile
- **Endpoint:** `POST /api/v1/users/profile/expert`
- **Description:** Creates the expert specific profile fields.
- **Request Body (JSON):**
  ```json
  {
    "specializations": ["Horticulture", "Pest Management"],
    "qualifications": "PhD Agriculture",
    "institution": "UAS Bangalore",
    "yearsExperience": 15
  }
  ```

---

## 3. Disease Analysis Routes
Base Path: `/api/v1/disease`

### A. Analyze Crop Disease
- **Endpoint:** `POST /api/v1/disease/analyze`
- **Description:** Uploads an image of a crop and returns an AI-driven disease analysis.
- **Content-Type:** `multipart/form-data`
- **Request Payload:**
  - `image`: File (Required - .jpg, .jpeg, .png, .webp) - Max 5MB
  - `cropType`: String (Optional)
  - `language`: String (Optional, e.g., "hi" or "en")
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Analysis complete / जांच पूरी हुई",
    "data": {
      "diseaseName": "...",
      "diseaseNameHindi": "...",
      "severity": "high" | "medium" | "low" | "none",
      "confidenceScore": 0.95,
      ...
    }
  }
  ```
- **Error Response (400 Bad Request - Missing Image):**
  ```json
  {
    "success": false,
    "message": "Image file is required / फोटो आवश्यक है"
  }
  ```
- **Error Response (429 Too Many Requests - Rate Limit Exceeded):**
  ```json
  {
    "success": false,
    "message": "Rate limit string message",
    "retryAfter": 60
  }
  ```

---

## 4. Community Routes
Base Path: `/api/v1/community`
*(All routes require Bearer Token Authentication)*

### A. Create Community
- **Endpoint:** `POST /api/v1/community`
- **Description:** Creates a new community.
- **Request Body (JSON):**
  ```json
  {
    "name": "Community Name",
    "description": "Optional description",
    "type": "GENERAL | DISTRICT | CROP_SPECIFIC | STATE_WIDE | RADIUS_BASED",
    "isPrivate": false,
    "latitude": 12.345,
    "longitude": 67.890,
    "radiusKm": 50
  }
  ```

### B. Get Nearby Communities
- **Endpoint:** `GET /api/v1/community/nearby?lat={lat}&lng={lng}&radius={radius}`
- **Description:** Returns a list of nearby communities based on the provided coordinates and radius.

### C. Join Community
- **Endpoint:** `POST /api/v1/community/:id/join`
- **Description:** Joins a specific community. If it is a private community, it creates a `PENDING` join request instead of an immediate join.
- **Success Response (Private Community):**
  ```json
  {
    "success": true,
    "data": { "message": "Join request sent and pending approval", "request": { ... } }
  }
  ```

---

## 4.1 Community Admin & Membership
Base Path: `/api/v1/community`
*(All routes require Bearer Token Authentication)*

### A. List Members
- **Endpoint:** `GET /api/v1/community/:id/members`
- **Description:** Returns the list of members in the community, with Admins appearing first. Each member includes safe user details (`id`, `name`, `profileImageUrl`).

### B. List Pending Join Requests
- **Endpoint:** `GET /api/v1/community/:id/requests`
- **Description:** Lists `PENDING` join requests. **Requires `ADMIN` or `MODERATOR` role.**

### C. Approve Join Request
- **Endpoint:** `POST /api/v1/community/:id/requests/:requestId/approve`
- **Description:** Approves a pending join request and creates a `CommunityMember` entry. **Requires `ADMIN` or `MODERATOR` role.**

### D. Reject Join Request
- **Endpoint:** `POST /api/v1/community/:id/requests/:requestId/reject`
- **Description:** Rejects a pending join request. **Requires `ADMIN` or `MODERATOR` role.**

### E. Update Member Role
- **Endpoint:** `POST /api/v1/community/:id/members/:memberId/role`
- **Description:** Modifies a member's role within a community.
- **Request Body (JSON):**
  ```json
  {
    "role": "ADMIN" | "MODERATOR" | "MEMBER"
  }
  ```
- **Requirements:** **Requires `ADMIN` role.**

---

## 4.2 Loans

### A. Create Loan Request
- **Endpoint:** `POST /api/v1/community/:id/loan`
- **Description:** Creates a community loan request (only for registered farmers).
- **Request Body (JSON):**
  ```json
  {
    "title": "Need funds for seeds",
    "amount": 5000,
    "reason": "Buying new high-yield seeds",
    "description": "I need support to buy seeds for the upcoming season.",
    "deadline": "2024-12-31"
  }
  ```

### E. Vote / Approve Loan
- **Endpoint:** `POST /api/v1/community/loan/:loanId/vote`
- **Description:** Upvotes/Approves a loan request in a community.

### F. Fund a Loan (Crowdfunding)
- **Endpoint:** `POST /api/v1/community/loan/:loanId/fund`
- **Description:** Pledges funds towards a loan request.
- **Request Body (JSON):**
  ```json
  {
    "amount": 1000,
    "message": "Best of luck!",
    "isAnonymous": false
  }
  ```

---

## WebSocket - Realtime Chat
- **Endpoint/URL:** `ws://localhost:3000` (or `http://localhost:3000` for Socket.IO clients)
- **Authentication:** Provide the Bearer token in `auth.token` or `headers.authorization` during the socket connection.

### Available Events
- **`join_room`**: Connects the socket to a room. Payload: `{ roomId: "string", communityId: "string" }`
- **`leave_room`**: Disconnects from a room. Payload: `{ roomId: "string" }`
- **`send_message`**: Sends a message to the room. Payload: `{ roomId, communityId, content, images, replyToId }`
- **`new_message`**: Received from server when a new message is broadcasted to the room.
