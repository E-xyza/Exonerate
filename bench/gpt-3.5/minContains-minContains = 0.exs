defmodule :"minContains-minContains = 0-gpt-3.5" do
  def validate(decoded_json) do
    case decoded_json do
      %{"contains" => %{"const" => 1}, "minContains" => 0} -> :ok
      _ -> :error
    end
  end
end
