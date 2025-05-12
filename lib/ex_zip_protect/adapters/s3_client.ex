defmodule ExZipProtect.Adapters.S3Client do
  @moduledoc false
  @callback get_object(bucket :: binary, key :: binary, opts :: keyword) :: term()
end
