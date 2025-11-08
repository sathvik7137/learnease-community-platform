# Use official Dart runtime as base image
FROM google/dart:latest

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN dart pub get

# Copy application code
COPY . .

# Build the application
RUN dart compile exe bin/server.dart -o bin/server

# Expose port
EXPOSE 8080

# Run the compiled binary
CMD ["./bin/server"]
