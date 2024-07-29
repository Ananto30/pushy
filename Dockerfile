# Use the official Elixir image
FROM elixir:1.12-alpine

# Define build argument
ARG AUTH_SECRET_KEY

# Set environment variables
ENV MIX_ENV=prod

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create and set the working directory
WORKDIR /app

# Copy the mix files and install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy the rest of the application code
COPY . .

# Compile the application
RUN mix do compile

# Expose the port the app runs on
EXPOSE 4000

# Start the application
CMD ["mix", "run", "--no-halt"]