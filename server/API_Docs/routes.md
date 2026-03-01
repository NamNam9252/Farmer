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
      "user": { ... }, 
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
      "user": { ... }, 
      "token": "jwt_token_string" 
    }
  }
  ```

---

## 2. Disease Analysis Routes
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
