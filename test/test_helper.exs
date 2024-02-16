run_integration = System.get_env("FERMO_RUN_INTEGRATION")
if run_integration do
  ExUnit.start(capture_log: true)
else
  ExUnit.start(capture_log: true, exclude: [:integration])
end
