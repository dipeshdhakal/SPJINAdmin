# Use Swift official image
FROM swift:5.9-jammy as build

# Install system dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libssl-dev zlib1g-dev libsqlite3-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /build

# Copy package files first for better caching
COPY Package.swift Package.resolved ./

# Resolve dependencies
RUN swift package resolve

# Copy source code and resources
COPY Sources ./Sources
COPY Resources ./Resources
COPY Public ./Public

# Build the project
RUN swift build --configuration release --skip-update

# Production stage
FROM swift:5.9-jammy-slim

# Install runtime dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get install -y libssl3 libsqlite3-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a vapor user and group
RUN useradd --user-group --create-home --shell /bin/bash vapor

# Set work directory
WORKDIR /app

# Copy built executable and resources
COPY --from=build --chown=vapor:vapor /build/.build/release /app
COPY --from=build --chown=vapor:vapor /build/Public /app/Public
COPY --from=build --chown=vapor:vapor /build/Resources /app/Resources

# Create directory for SQLite database with proper permissions
RUN mkdir -p /app/data && chown vapor:vapor /app/data

# Switch to vapor user
USER vapor:vapor

# Create volume for SQLite database persistence
VOLUME ["/app/data"]

# Expose port
EXPOSE 8080

# Set entry point
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
