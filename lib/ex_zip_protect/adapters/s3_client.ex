defmodule ExZipProtect.Adapters.S3Client do
  @moduledoc false
  @callback get_object(bucket :: binary, key :: binary, opts :: keyword) :: term()
  @callback head_object(bucket :: binary, key :: binary, opts :: keyword) ::
              {:ok, %{headers: [{binary, binary}]}} | {:error, term()}
end
