defmodule ExZipProtect.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if ExZipProtect.Config.rotation() == :round_robin do
        [
          {Task,
           fn ->
             :ets.new(:ex_zip_protect_rr, [:set, :public, :named_table, read_concurrency: true])
           end}
        ]
      else
        []
      end

    :telemetry.attach(
      "ex_zip_protect-logger",
      [:ex_zip_protect, :bomb, :served],
      &__MODULE__.log_event/4,
      nil
    )

    Application.put_env(
      :ex_zip_protect,
      :s3_client,
      ExZipProtect.Adapters.S3Client.ExAws
    )

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  @doc false
  def log_event(_event, meas, meta, _cfg) do
    require Logger

    Logger.warning(
      "ex_zip_protect served (level=#{meta.level}) ip=#{meta.ip} bytes=#{meas.bytes} source=#{inspect(meta.source)}"
    )
  end
end
