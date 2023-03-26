defmodule ExonerateTest.FilePlug do
  @test_dir Path.dirname(__DIR__)

  use Plug.Router
  plug(:match)
  plug(:dispatch)

  match _ do
    content =
      @test_dir
      |> Path.join(conn.request_path)
      |> File.read!()

    send_resp(conn, 200, content)
  end
end
