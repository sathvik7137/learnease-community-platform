# Use official Dart runtime as base image (stable version)
FROM dart:stable

# Install SQLite3 library (both runtime and dev packages for dynamic linking)
RUN apt-get update && \
    apt-get install -y libsqlite3-0 libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec files first
COPY pubspec.yaml ./
COPY pubspec.lock* ./

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
