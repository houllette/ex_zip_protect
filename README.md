# ExZipProtect

[![Module Version](https://img.shields.io/hexpm/v/ex_zip_protect.svg)](https://hex.pm/packages/ex_zip_protect)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_zip_protect/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_zip_protect.svg)](https://hex.pm/packages/ex_zip_protect)
[![License](https://img.shields.io/hexpm/l/ex_zip_protect.svg)](https://hex.pm/packages/ex_zip_protect)
[![Last Updated](https://img.shields.io/github/last-commit/houllette/ex_zip_protect.svg)](https://github.com/houllette/ex_zip_protect/commits/main)

Protect your Phoenix/Plug applications from low‑effort scrapers, scanners, and spam bots by serving them **compressed "zip bombs"**—ultra‑small payloads that expand to hundreds of MB/GB and exhaust their memory.

ExZipProtect does **zero detection itself**; it simply makes it trivial for *you* to return a pre‑built bomb when your own heuristics say, “Nuke this request.”

---

## ✨ Features

| Feature                        | Details                                                                                                                                 |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| **BYOB**                       | *Bring Your Own Bomb*—the library never ships with or generates payloads. You point to files you already built (gzip / zstd / brotli, etc.). |
| **Multiple storage back‑ends** | `{:file, path}` · `{:s3, bucket: …, key: …}` · `{:url, "https://…"}`                                                                    |
| **Rotation (opt‑in)**          | `:none` (default), `:random`, or `:round_robin` across multiple bombs per severity level.                                               |
| **Staging safe‑guard**         | Entire library can be disabled with a single flag (default off in non‑`prod` envs).                                                     |
| **Enable bypass header**       | Configure an optional HTTP header to serve as bypass to ExZipProtect (useful for security scanners).                                    |
| **Telemetry audit event**      | Emits `[:ex_zip_protect, :bomb, :served]` so you can track activations.                                                                 |
| **Mix generator**              | `mix ex_zip_protect.gen.config` scaffolds a ready‑to‑edit config file.                                                                  |

---

## 📦 Installation

Add to `mix.exs`:

```elixir
defp deps do
  [
    {:ex_zip_protect, "~> 0.1"},

    # OPTIONAL — required only if you use these source types:
    {:ex_aws, "~> 2.5", optional: true}
    {:ex_aws_s3, "~> 2.5", optional: true},   # for :s3 sources
    {:finch,     "~> 0.18", optional: true}    # for :url streaming if not already in deps
  ]
end
```

Run `mix deps.get`.

---

## 🔧 Quick start

```bash
$ mix ex_zip_protect.gen.config   # creates config/ex_zip_protect.exs
$ $EDITOR config/ex_zip_protect.exs   # edit paths / bucket names / rotation
```

Then in a controller or plug:

```elixir
alias ExZipProtect.Plug, as: Bomb

plug :maybe_bomb

defp maybe_bomb(conn, _opts) do
  case Detection.classify(conn) do
    {:bomb, :low   } -> Bomb.send(conn, :low)
    {:bomb, :medium} -> Bomb.send(conn, :medium)
    {:bomb, :high  } -> Bomb.send(conn, :high)
    _other           -> conn
  end
end
```

Done!  Your normal pipeline proceeds unless you explicitly call `Bomb.send/2`.

---

## ⚙️ Configuration reference (`config/*.exs`)

```elixir
import Config

config :ex_zip_protect,
  enabled?: config_env() == :prod,   # disable library outside prod by default
  rotation: :none,                  # :none | :random | :round_robin
  levels: [
    low:    [ %{source: {:file, "/srv/bombs/low.gz"},    encoding: :gzip} ],
    medium: [ %{source: {:s3, bucket: "bombs", key: "5mb.zst"}, encoding: :zstd} ],
    high:   [
      %{source: {:url, "https://cdn.example.com/10mb.br"}, encoding: :br},
      %{source: {:url, "https://cdn2.example.com/20mb.br"}, encoding: :br}
    ]
  ]
```

### Keys

| Key               | Type         | Default | Notes                                                                                                             |
| ----------------- | ------- | ------- | ----------------------------------------------------------------------------------------------------------------- |
| `enabled?`        | bool    | `true`  | When `false`, `Bomb.send/2` is a no‑op.                                                                           |
| `rotation`        | atom    | `:none` | Distribution strategy across a list of bombs for the same level.                                                  |
| `levels`          | keyword | —       | Map severity `level => [bomb_spec, …]`.                                                                           |
| `bypass_header`   | string  | nil     | If set, _any_ request containing that header bypasses bombs. Leave `nil` (or comment out) to disable the feature. |

### Bomb spec

```elixir
%{
  source: {:file, "/path"} | {:s3, bucket: "…", key: "…", opts: [...] } | {:url, "https://…"},
  encoding: :gzip | :zstd | :br | :deflate | atom(),
  bytes: 1_000_000            # optional – sets Content‑Length without stat
}
```

*If `:bytes` is absent*, ExZipProtect tries to derive size via `File.stat/2`, `HEAD` request, or S3 object metadata.

---

## 💣 Bring Your Own Bomb (BYOB)

ExZipProtect **never** creates or bundles payloads. A few popular one‑liners:

```bash
# 1GB inflate → 1MB gzip
$ dd if=/dev/zero bs=1G count=1 | gzip -c > 1mb-1gb.gz

# 10GB inflate → 10MB zstd (fast)
$ dd if=/dev/zero bs=1G count=10 | zstd -19 -o 10mb-10gb.zst

# 50GB inflate → 10MB brotli (aggressive)
$ dd if=/dev/zero bs=50G count=1 | brotli -q11 -o 10mb-50gb.br
```

> **Danger:** Decompressing these files locally may hang or crash your machine. Build them in a throwaway container or server.

Upload the resulting file to your chosen storage, then reference it in `config`.

---

## 🚚 Where to host bombs?

| Source               | `source:` tuple                       | Pros                    | Cons                                   |
| -------------------- | ------------------------------------- | ----------------------- | -------------------------------------- |
| **Local file**       | `{:file, "/srv/bombs/…"}`             | Fast, no network        | Consumes disk on every app node        |
| **S3 / GCS / MinIO** | `{:s3, bucket: "…", key: "…"}`        | Offloads storage; cheap | Requires `ex_aws_s3` dep & network I/O |
| **HTTPS URL (CDN)**  | `{:url, "https://cdn.example.com/…"}` | Global edge caching     | Adds latency; ensure CORS/ACL OK       |

---

## 📈 Telemetry

`[:ex_zip_protect, :bomb, :served]`

| Measurements                    | Metadata                   |
| ------------------------------- | -------------------------- |
| `:bytes` – size (or `:unknown`) | `:level`, `:ip`, `:source` |

The application supervisor attaches a default `Logger.warning/1` handler—you can detach it and forward to Honeycomb, Datadog, OpenTelemetry, etc.

---

## 🛡️ Legal & ethical notes

* Serving bomb files is a form of denial‑of‑service **against the client**. Ensure this practice is allowed by your provider & jurisdiction.
* Provide a bypass header (e.g. `X‑ZipBomb: false`) if you need certain security scanners to skip bombs.
* Never serve bombs accidentally in dev/staging—leave `enabled?: config_env() == :prod`.

---

## 🛠️ Advanced topics

* **Streaming upgrades** — S3/URL senders are synchronous for now; PRs welcome for fully stream‑chunked variants.
* **Custom rotation** — Implement the `ExZipProtect.Rotation` behaviour and set `rotation: MyModule`.

---

## 🤝 Contributing

Issues and PRs are welcome!  Please run `mix test` and keep the `README.md` examples in sync.

---

## 📜 License

ExZipProtect is released under the MIT License.
