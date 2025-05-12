defmodule ExZipProtect.Config do
  @moduledoc """
  Provides convenient accessors for all `:ex_zip_protect` application
  configuration keys.

  This module wraps calls to `Application.get_env/3` and exposes:

    * `enabled?/0`      – whether the library is enabled (default: `true`)
    * `rotation/0`      – rotation strategy (`:none`, `:round_robin`, etc.; default: `:none`)
    * `levels/0`        – definitions of zip-bomb levels (default: `[]`)
    * `bypass_header/0` – optional HTTP header to skip serving bombs (default: `nil`)

  All values are fetched from the `:ex_zip_protect` OTP application environment.
  """
  @app :ex_zip_protect

  def enabled?, do: Application.get_env(@app, :enabled?, true)
  def rotation, do: Application.get_env(@app, :rotation, :none)
  def levels, do: Application.get_env(@app, :levels, [])
  def bypass_header, do: Application.get_env(@app, :bypass_header, nil)
end
