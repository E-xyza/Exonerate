# Dockerfile for Bowtie integration
# This builds a container that runs the Exonerate Bowtie harness

FROM elixir:1.17-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files first for better caching
COPY mix.exs mix.lock ./

# Set MIX_ENV to prod
ENV MIX_ENV=prod

# Get dependencies
RUN mix deps.get --only prod

# Copy source
COPY lib ./lib

# Compile the application
RUN mix compile

# Build the escript
RUN mix escript.build

# Runtime image
FROM elixir:1.17-alpine

WORKDIR /app

# Copy the escript from builder
COPY --from=builder /app/exonerate_bowtie ./

# Set the entrypoint
ENTRYPOINT ["./exonerate_bowtie"]
