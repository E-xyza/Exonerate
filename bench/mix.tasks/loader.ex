defmodule JsonXema.Loader do
  @moduledoc false

  @behaviour Xema.Loader

  @spec fetch(binary) :: {:ok, map} | {:error, any}
  def fetch(uri) do
    with {:ok, response} <- Req.get(uri),
         {:ok, json} <- Jason.decode(response.body) do
      {:ok, json}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
