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

### 3. Environment Configuration
The app uses SQLite which is file-based and included in the container. For data persistence, a volume is configured in the Dockerfile.

**Key points:**
- SQLite database file will be stored at `/app/data/db.sqlite` in production
- The Docker configuration includes a volume at `/app/data` for persistence
- No external database service is required

### 4. Environment Variables
In your Web Service settings, add these environment variables:

**Required:**
- `JWT_SECRET`: [Generate a random 32+ character string]
- `PORT`: [This should be auto-set by Render]

**Optional:**
- `LOG_LEVEL`: `info`

### 5. Deploy
- Save all settings
- Render will automatically start building and deploying
- Check the logs for any build errors
- The app will run migrations automatically on first startup
- Default admin user will be created (check your SeedAdminUser migration for credentials)

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

### If database issues occur:
- SQLite database is file-based and should work without connection parameters
- Ensure the app has write permissions to the directory where db.sqlite is stored
- Check build logs for any SQLite-related errors

### For data persistence:
- Render automatically manages persistent disks for Docker deployments
- If data isn't persisting between deployments, add a Render disk:
  1. Go to your Web Service → Disks
  2. Add a disk with mount path: `/app/data`
  3. Size: 1 GB (increase if needed)
