# API Write Protection Documentation

## Overview
The API controllers now have write protection controlled by the `AdminConfig.allowAPIWrite` boolean variable.

## Configuration
In `Sources/App/Config/AdminConfig.swift`:

```swift
static let allowAPIWrite: Bool = false  // Set to true to enable API writes
```

## Protected Endpoints

### Books API (`/api/books`)
- ✅ **GET** `/api/books` - List all books (always allowed)
- ✅ **GET** `/api/books/:id` - Get specific book (always allowed)
- 🔒 **POST** `/api/books` - Create book (requires allowAPIWrite = true)
- 🔒 **PUT** `/api/books/:id` - Update book (requires allowAPIWrite = true)
- 🔒 **DELETE** `/api/books/:id` - Delete book (requires allowAPIWrite = true)

### Prakarans API (`/api/prakarans`)
- ✅ **GET** `/api/prakarans` - List all prakarans (always allowed)
- ✅ **GET** `/api/prakarans/:id` - Get specific prakaran (always allowed)
- 🔒 **POST** `/api/prakarans` - Create prakaran (requires allowAPIWrite = true)
- 🔒 **PUT** `/api/prakarans/:id` - Update prakaran (requires allowAPIWrite = true)
- 🔒 **DELETE** `/api/prakarans/:id` - Delete prakaran (requires allowAPIWrite = true)

### Chaupais API (`/api/chaupais`)
- ✅ **GET** `/api/chaupais` - List all chaupais (always allowed)
- ✅ **GET** `/api/chaupais/:id` - Get specific chaupai (always allowed)
- 🔒 **POST** `/api/chaupais` - Create chaupai (requires allowAPIWrite = true)
- 🔒 **PUT** `/api/chaupais/:id` - Update chaupai (requires allowAPIWrite = true)
- 🔒 **DELETE** `/api/chaupais/:id` - Delete chaupai (requires allowAPIWrite = true)

## Error Response
When `allowAPIWrite = false` and a write operation is attempted:

```json
{
  "error": true,
  "reason": "API write operations are disabled"
}
```

HTTP Status: `403 Forbidden`

## How to Enable API Writes
1. Change `allowAPIWrite = true` in `AdminConfig.swift`
2. Rebuild and redeploy the application
3. Write operations will then be allowed

## Security Note
This provides a simple toggle to disable all API write operations for production environments where you want read-only API access.
