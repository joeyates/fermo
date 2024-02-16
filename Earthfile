VERSION 0.6

all:
  # Keep these versions in sync with the versions in .github/workflows/elixir.yml
  BUILD \
    --build-arg ELIXIR_BASE=1.13.4-erlang-24.3.4.16-ubuntu-jammy-20240125 \
    --build-arg ELIXIR_BASE=1.14.5-erlang-24.3.4.16-ubuntu-jammy-20240125 \
    --build-arg ELIXIR_BASE=1.16.1-erlang-24.3.4.16-ubuntu-jammy-20240125 \
    +test

test:
  ARG ELIXIR_BASE=1.16.1-erlang-24.3.4.16-ubuntu-jammy-20240125
  FROM hexpm/elixir:$ELIXIR_BASE
  RUN apt update
  RUN apt install --yes git build-essential
  RUN mix local.rebar --force
  RUN mix local.hex --force
  WORKDIR /src/fermo

  COPY mix.exs mix.lock .formatter.exs ./
  COPY --dir config ./
  RUN mix deps.get
  RUN MIX_ENV=test mix compile

  COPY --dir lib priv test ./
  RUN mix test
