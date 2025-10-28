# Community Server for LearnEase

This is the backend server that enables **shared community contributions** across all users of the LearnEase app.

## Features

- ✅ Share contributions between all users
- ✅ Real-time updates when users add content
- ✅ Persistent storage (saved to `contributions.json`)
- ✅ RESTful API with CORS support
- ✅ Offline fallback in the Flutter app

## Quick Start

### 1. Start the Server

```powershell
cd community_server
dart run bin/server.dart
```

Server will run on `http://localhost:8080`

### 2. Run the Flutter App

```powershell
cd ..
flutter run -d chrome
```

The app will automatically connect to the local server.

## API Endpoints

### GET /health
Health check endpoint
```
Response: "Community Server is running!"
```

### GET /api/contributions
Get all contributions
```json
Response: [
  {
    "id": "user_123456",
    "authorName": "JohnDoe",
    "type": "topic",
    "category": "java",
    "createdAt": "2025-10-23T...",
    "content": {...}
  }
]
```

### GET /api/contributions/:category
Get contributions by category (java or dbms)
```
GET /api/contributions/java
GET /api/contributions/dbms
```

### POST /api/contributions
Add new contribution
```json
Request Body: {
  "id": "user_123456",
  "authorName": "JohnDoe",
  "type": "topic",
  "category": "java",
  "content": {...}
}

Response: {
  "success": true,
  "id": 1
}
```

### PUT /api/contributions/:id
Update existing contribution
```json
Request Body: {Updated contribution object}
Response: {"success": true}
```

### DELETE /api/contributions/:id
Delete contribution
```
Response: {"success": true}
```

## Deploy with Cloudflare Tunnel

### Option 1: Using Cloudflare Tunnel (Recommended)

1. **Install Cloudflare Tunnel:**
   ```powershell
   # Download from https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
   ```

2. **Start the server:**
   ```powershell
   cd community_server
   dart run bin/server.dart
   ```

3. **Create tunnel:**
   ```powershell
   cloudflared tunnel create learnease-community
   ```

4. **Run tunnel:**
   ```powershell
   cloudflared tunnel --url http://localhost:8080 run learnease-community
   ```

5. **Update Flutter app:**
   - Get your tunnel URL (e.g., `https://xyz.trycloudflare.com`)
   - Update `SERVER_URL` in the app:
   
   ```powershell
   flutter run -d chrome --dart-define=SERVER_URL=https://your-tunnel-url.trycloudflare.com
   ```

### Option 2: Deploy to Cloud Platform

#### Deploy to Heroku
```bash
# Create Procfile
echo "web: dart run bin/server.dart" > Procfile

# Deploy
heroku create learnease-community
git push heroku main
```

#### Deploy to Google Cloud Run
```bash
# Create Dockerfile
FROM dart:stable

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o server

CMD ["./server"]

# Deploy
gcloud run deploy learnease-community --source .
```

## Environment Variables

- `PORT`: Server port (default: 8080)
- Set via command line or `.env` file

## Data Storage

- **Development**: Data stored in `contributions.json`
- **Production**: Consider using a database:
  - PostgreSQL
  - MongoDB
  - Firestore
  - Supabase

## Security Considerations

For production deployment:

1. ✅ Add authentication (JWT tokens)
2. ✅ Add rate limiting
3. ✅ Add input validation
4. ✅ Use HTTPS only
5. ✅ Add content moderation
6. ✅ Implement user roles (admin, moderator, user)

## Monitoring

Server logs include:
- All HTTP requests (via `logRequests()` middleware)
- Server startup information
- Error messages
- Total contribution count

## Testing

Test the API using curl or Postman:

```powershell
# Health check
curl http://localhost:8080/health

# Get all contributions
curl http://localhost:8080/api/contributions

# Add contribution
curl -X POST http://localhost:8080/api/contributions `
  -H "Content-Type: application/json" `
  -d '{\"id\":\"test_123\",\"authorName\":\"Test\",\"type\":\"topic\",\"category\":\"java\",\"content\":{}}'
```

## Troubleshooting

### Port already in use
```powershell
# Change port
$env:PORT=8081
dart run bin/server.dart
```

### CORS errors
- Check that CORS headers are properly set
- Verify the Flutter app URL is allowed

### Connection refused
- Ensure server is running
- Check firewall settings
- Verify correct URL in Flutter app

## Offline Support

The Flutter app includes automatic offline fallback:
- If server is unreachable, uses local cache
- Syncs when connection is restored
- No data loss during offline periods

## Contributing

To add new features to the server:
1. Add route in `bin/server.dart`
2. Update this README
3. Test with Flutter app
4. Deploy

---

**Made with ❤️ for the LearnEase Community**
