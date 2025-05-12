ExUnit.start()
Application.ensure_all_started(:briefly)

# Start a local Finch supervisor that the HTTP sender will use
{:ok, _} = Finch.start_link(name: ExZipProtectFinch)
