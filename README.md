# Pushy

Pushy is a simple server to send SSE (Server-Sent Events) to HTTP clients. It allows you to listen to a list of channels and post events to them.

## Requirements

* Elixir ~> 1.12
* Erlang/OTP 23+

## Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/ananto30/pushy.git
   cd pushy
   ```

2. Install dependencies:

   ```sh
   mix deps.get
   ```

3. Compile the project:

   ```sh
   mix compile
   ```

## Running the Server

To start the server, set environment variables for the `AUTH_SECRET_KEY`

```sh
export AUTH_SECRET_KEY=secret
```

then run:

```sh
mix run --no-halt
```

The server will start on port 4000 by default.

## Usage

### Auth Token

Very first thing you need to do is to generate a token to authenticate the client. You can generate a token by running:

```sh
mix run -e "{:ok, token} = Pushy.Auth.make_token(%{user_id: 1}); IO.puts(\"Generated JWT Token: #{token}\")"
```

### Listening to Channels

To listen to channels, make an HTTP POST request to `/sse` with the channel names in the body.

Example using [script](/example/listen.exs):

```sh
elixir example/listen.exs
```

\*\* Update the token in the file before running the script.

### Posting Events to Channels

To post an event to a channel, make an HTTP POST request to `/publish/:channel_name` with the event data in the request body.

Example using [script](/example/publish.exs):

```sh
elixir example/publish.exs
```

\*\* Update the token in the file before running the script.

## Testing

To run the tests, execute:

```sh
mix test
```

## Docker Instructions

### Building the Docker Image

To build the Docker image for your Elixir application, run the following command in the root directory of your project:

```sh
docker build -t pushy:latest . --build-arg AUTH_SECRET_KEY=secret
```

**Creating `AUTH_SECRET_KEY` as a build argument will reduce runtime signed token validation execution time.*

### Running the Docker Container

To run the Docker container, execute:

```sh
docker run -p 4000:4000 pushy:latest
```

The server will start on port 4000 inside the container and will be exposed on port 4000 on your host machine.

## Dependencies

Pushy uses the following dependencies:

* `plug_cowboy` - A Plug adapter for Cowboy
* `jason` - A JSON library for Elixir
* `uuid` - A UUID library for Elixir
* `phoenix_pubsub` - A distributed PubSub system for Phoenix
* `joken` - A JSON Web Token (JWT) library for Elixir

## License

This project is licensed under the MIT License.
