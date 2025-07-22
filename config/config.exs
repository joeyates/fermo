import Config

env_config = "#{config_env()}.exs"

if "config" |> Path.join(env_config) |> File.regular?() do
  import_config env_config
end
