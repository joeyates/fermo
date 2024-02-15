Fermo produces static web sites.

# HTML Templates

Projects using Fermo contain EEx and Slime templates.

Fermo compiles the project's templates into modules, thanks to the addition of `:fermo`
to the list of project compilers.
This addition causes the `compile.fermo` Mix task to be called by the Elixir compiler.

# Assets

Assests are handled via optional pipelines which can be configured.

# config

All information about what is to be built is put into a Map called `config`.

# Modes

Fermo has two modes, build mode for making the final static build
of the site, the live mode for development.

# build mode

Two GenServers are started by `Fermo.App`.

1. `I18n` handles internationalization mapping keys to translations,
2. `Fermo.Assets` which uses the asset manifest to map asset names
to their fingerprinted paths.

`Fermo.Build` runs any configured asset builds, and has `Fermo.Assets`
create and load the asset manifest.

# live mode

Live mode is started by running `mix fermo.live` in nthe project's root directory.

`Fermo.Live.App` starts various processes which handle monitoring for
modifications and reloading changed pages. It can also optionally
start other processes, both for external asset pipelines and
for other types of change handling.

In 'live' mode, also runs an internal web server, `Fermo.Live.Server`
which builds pages on the fly and injects a socket listener to allow
page reloads when content changes.

Live mode can be integrated with various change-listener mechanisms,
so that changes cause pages to be reloaded (see Fermo.Live.Dependencies).
