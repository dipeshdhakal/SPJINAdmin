# Render Deployment Instructions

## Step-by-Step Guide for Render Deployment:

### 1. Create New Web Service in Render
- Go to https://render.com/
- Click "New +" → "Web Service"
- Connect your GitHub/GitLab repository

### 2. Service Configuration
**Basic Settings:**
- Name: `spjin`
- Environment: `Docker` (or `Native` if Docker fails)
- Region: Choose closest to your users
- Branch: `main` (or your default branch)

**Build & Deploy:**
- Build Command: `swift build --configuration release`
- Start Command: `./.build/release/App serve --env production --hostname 0.0.0.0 --port $PORT`

**Advanced Settings:**
- Auto-Deploy: `Yes`

### 3. Add PostgreSQL Database
- In Render Dashboard, click "New +" → "PostgreSQL"
- Name: `spjin-db`
- Database Name: `spjin`
- User: `spjin`
- Plan: Free
- Wait for database to be created

### 4. Environment Variables
In your Web Service settings, add these environment variables:

**Required:**
- `DATABASE_URL`: [Copy from your PostgreSQL database's "Internal Database URL"]
- `JWT_SECRET`: [Generate a random 32+ character string]
- `PORT`: [This should be auto-set by Render]

**Optional:**
- `LOG_LEVEL`: `info`
- `SWIFT_VERSION`: `5.9`

### 5. Deploy
- Save all settings
- Render will automatically start building and deploying
- Check the logs for any build errors

## Troubleshooting:

### If Docker build fails:
1. Try changing Environment from "Docker" to "Native"
2. Use these commands instead:
   - Build Command: `swift package resolve && swift build --configuration release`
   - Start Command: `./.build/release/App serve --hostname 0.0.0.0 --port $PORT`

### If Swift/dependencies fail:
- Render provides Swift 5.9 by default
- Check the build logs for specific error messages
- Ensure all dependencies in Package.swift are compatible

### If database connection fails:
- Verify DATABASE_URL is correctly set
- Make sure PostgreSQL service is running
- Check that the database URL format is correct: `postgresql://user:password@host:port/database`
