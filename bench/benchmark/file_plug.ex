defmodule Benchmark.FilePlug do
  @content_dir Path.join(__DIR__, "../../test/_draft7/remotes")

  use Plug.Router
  plug(:match)
  plug(:dispatch)

  match _ do
    content =
      @content_dir
      |> Path.join(conn.request_path)
      |> File.read!()

    send_resp(conn, 200, content)
  end
end
