# --------------------------------------------------------------------
# ex_zip_protect — sample configuration
# --------------------------------------------------------------------

import Config

config :ex_zip_protect,
  enabled?: config_env() == :prod,
  rotation: :none,  # :none | :random | :round_robin
  # bypass_header: "x-zipprotect-skip",  # any request with this header bypasses bombs, uncomment to enable
  levels: [
    low: [
      %{
        source: {:file, "/srv/bombs/low.gz"},
        encoding: :gzip
      }
    ],
    medium: [
      %{
        source: {:s3,
          bucket: "my-bomb-bucket",
          key: "5mb-zstd.zst",
          opts: [region: "us-west-2"]
        },
        encoding: :zstd
      }
    ],
    high: [
      %{
        source: {:url, "https://cdn.example.com/10mb.br"},
        encoding: :br
      }
    ]
  ]
