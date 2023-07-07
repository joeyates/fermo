Fermo produces static web sites.

It is included as a dependency in projects containing template files.

To do so, it uses EEx and Slime to convert HTML templates into HTML.

Assests are handled via optional pipelines which can be configured.

# config

All information about what is to be built is put into a Map called `config`.

# Modes

Fermo has two modes, build mode for making the final static build
of the site, the live mode for development.

# build mode

Two GenServers are started by `Fermo.App`.

`I18n` handles internationalization mapping keys to translations.

`Fermo.Assets` handles linking to digested assets files.

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
