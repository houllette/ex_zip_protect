defmodule ExZipProtect.Sender.File do
  @moduledoc false
  import Plug.Conn, only: [send_file: 3]

  def send(conn, path) do
    send_file(conn, 200, path)
  end
end
