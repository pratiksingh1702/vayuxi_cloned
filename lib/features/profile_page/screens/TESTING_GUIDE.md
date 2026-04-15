# Phone OTP Authentication - Quick Testing Guide

## Prerequisites
- Server running on `http://localhost:3000`
- Valid phone number for testing
- Access to phone to receive OTP

---

## Test Scenario 1: New User Registration

### Step 1: Send OTP
```bash
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

**Expected Response:**
```json
{
  "message": "OTP sent successfully",
  "sessionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "expiresIn": 600,
  "isExistingUser": false
}
```

### Step 2: Verify OTP (Replace 1234 with actual OTP)
```bash
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "9876543210",
    "otp": "1234"
  }'
```

**Expected Response:**
```json
{
  "message": "Registration successful. Please complete your profile within 24 hours.",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "isPhoneVerified": true
  },
  "token": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "isNewUser": true,
  "requiresProfileCompletion": true,
  "gracePeriodEndsAt": "2024-04-15T..."
}
```

**⚠️ Save the token from this response!**

### Step 3: Complete Profile
```bash
# Replace YOUR_TOKEN_HERE with the token from Step 2
curl -X POST http://localhost:3000/api/v1/auth/complete-profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "companyName": "John Construction Co"
  }'
```

**Expected Response:**
```json
{
  "message": "Profile completed successfully",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "company": {
      "_id": "...",
      "name": "John Construction Co"
    }
  },
  "token": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## Test Scenario 2: Existing User Login

### Step 1: Send OTP
```bash
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

**Expected Response:**
```json
{
  "message": "OTP sent successfully",
  "sessionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "expiresIn": 600,
  "isExistingUser": true
}
```

### Step 2: Verify OTP (Login Complete)
```bash
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "9876543210",
    "otp": "1234"
  }'
```

**Expected Response:**
```json
{
  "message": "Login successful",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "company": {
      "_id": "...",
      "name": "John Construction Co"
    }
  },
  "token": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "isNewUser": false,
  "requiresProfileCompletion": false
}
```

---

## Test Scenario 3: Error Cases

### Invalid Phone Number
```bash
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "123"}'
```

**Expected Response (400):**
```json
{
  "error": "Phone number must be 10 digits"
}
```

### Invalid OTP
```bash
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "9876543210",
    "otp": "0000"
  }'
```

**Expected Response (400):**
```json
{
  "error": "Invalid OTP"
}
```

### Complete Profile Without Token
```bash
curl -X POST http://localhost:3000/api/v1/auth/complete-profile \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Doe",
    "email": "john.doe@example.com"
  }'
```

**Expected Response (401):**
```json
{
  "error": "Unauthorized"
}
```

### Duplicate Email
```bash
# After completing profile once, try again with same email but different phone
curl -X POST http://localhost:3000/api/v1/auth/complete-profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "fullName": "Jane Doe",
    "email": "john.doe@example.com"
  }'
```

**Expected Response (409):**
```json
{
  "error": "Email already exists"
}
```

---

## Quick Copy-Paste Test Script

Save this as `test-auth.sh` and run with `bash test-auth.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:3000/api/v1/auth"
PHONE="9876543210"

echo "=== Test 1: Send OTP ==="
curl -X POST $BASE_URL/send-otp \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$PHONE\"}"

echo -e "\n\n=== Enter OTP received on phone: ==="
read OTP

echo -e "\n=== Test 2: Verify OTP ==="
RESPONSE=$(curl -s -X POST $BASE_URL/verify-otp \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$PHONE\", \"otp\": \"$OTP\"}")

echo $RESPONSE | jq '.'

TOKEN=$(echo $RESPONSE | jq -r '.token.token')
IS_NEW=$(echo $RESPONSE | jq -r '.isNewUser')

if [ "$IS_NEW" = "true" ]; then
  echo -e "\n=== New User - Complete Profile ==="
  echo "Enter Full Name:"
  read FULLNAME
  echo "Enter Email:"
  read EMAIL
  echo "Enter Company Name (optional):"
  read COMPANY
  
  curl -X POST $BASE_URL/complete-profile \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"fullName\": \"$FULLNAME\", \"email\": \"$EMAIL\", \"companyName\": \"$COMPANY\"}" | jq '.'
else
  echo -e "\n=== Existing User - Login Successful ==="
fi
```

---

## Postman Collection

Import this JSON into Postman:

```json
{
  "info": {
    "name": "Phone OTP Authentication",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Send OTP",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"phoneNumber\": \"9876543210\"\n}"
        },
        "url": {
          "raw": "http://localhost:3000/api/v1/auth/send-otp",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "v1", "auth", "send-otp"]
        }
      }
    },
    {
      "name": "Verify OTP",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"phoneNumber\": \"9876543210\",\n  \"otp\": \"1234\"\n}"
        },
        "url": {
          "raw": "http://localhost:3000/api/v1/auth/verify-otp",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "v1", "auth", "verify-otp"]
        }
      }
    },
    {
      "name": "Complete Profile",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"fullName\": \"John Doe\",\n  \"email\": \"john@example.com\",\n  \"companyName\": \"John Construction Co\"\n}"
        },
        "url": {
          "raw": "http://localhost:3000/api/v1/auth/complete-profile",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "v1", "auth", "complete-profile"]
        }
      }
    }
  ]
}
```

---

## Checklist

- [ ] Test new user registration flow
- [ ] Test existing user login flow
- [ ] Test invalid phone number
- [ ] Test invalid OTP
- [ ] Test expired OTP (wait 10 minutes)
- [ ] Test complete profile with valid data
- [ ] Test complete profile without token
- [ ] Test complete profile with duplicate email
- [ ] Test complete profile after grace period (wait 24 hours)
- [ ] Verify JWT token is set in cookies
- [ ] Verify company is created
- [ ] Verify dummy data is set up

---

## Common Issues

### Issue: OTP not received
- Check 2factor.in API key is correct
- Verify phone number format (10 digits)
- Check 2factor.in account balance

### Issue: "Invalid OTP" error
- Ensure OTP is entered within 10 minutes
- Check for typos in OTP
- Verify session hasn't expired

### Issue: "Grace period expired"
- User must complete profile within 24 hours
- Contact support to reset grace period

### Issue: Token not working
- Ensure token is included in Authorization header
- Check token format: `Bearer <token>`
- Verify token hasn't expired

---

**Happy Testing! 🚀**
