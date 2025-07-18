# Use Swift official image
FROM swift:5.9-jammy as build

# Install system dependencies
RUN apt-get update -y \
    && apt-get install -y libssl-dev zlib1g-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /build

# Copy entire project
COPY . .

# Build the project
RUN swift build --configuration release

# Production stage
FROM swift:5.9-jammy-slim

# Install runtime dependencies
RUN apt-get update -y \
    && apt-get install -y libssl3 libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create a vapor user and group
RUN useradd --user-group --create-home --shell /bin/bash vapor

# Set work directory
WORKDIR /app

# Copy built executable and resources
COPY --from=build --chown=vapor:vapor /build/.build/release /app
COPY --from=build --chown=vapor:vapor /build/Public /app/Public
COPY --from=build --chown=vapor:vapor /build/Resources /app/Resources

# Switch to vapor user
USER vapor:vapor

# Expose port
EXPOSE 8080

# Set entry point
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
