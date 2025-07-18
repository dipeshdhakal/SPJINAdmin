# Use Swift official image
FROM swift:5.9-jammy as build

# Install system dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libssl-dev zlib1g-dev libpq-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /build

# Copy package files first for better caching
COPY Package.swift Package.resolved ./

# Resolve dependencies
RUN swift package resolve

# Copy source code
COPY Sources ./Sources
COPY Public ./Public
COPY Resources ./Resources

# Build the project with verbose output for debugging
RUN swift build --configuration release -v

# Production stage
FROM swift:5.9-jammy-slim

# Install runtime dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get install -y libssl3 libpq5 ca-certificates \
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
