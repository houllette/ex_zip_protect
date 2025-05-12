defmodule ExZipProtect.Adapters.S3Client.ExAws do
  @moduledoc false
  @behaviour ExZipProtect.Adapters.S3Client

  @impl true
  def get_object(bucket, key, opts) do
    ExAws.S3.get_object(bucket, key, opts) |> ExAws.stream!()
  end
end
