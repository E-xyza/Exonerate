defmodule :"minContains-minContains=1 with contains-gpt-3.5" do
  require Jason.Schema

  def validate(json) when is_map(json) do
    case Jason.Schema.validate(json, %{"contains" => %{"const" => 1}, "minContains" => 1}) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  def validate(_) do
    :error
  end
end
