defmodule :"minContains-minContains=1 with contains-gpt-3.5" do
  def validate(decoded_json) do
    case decoded_json do
      %{"contains" => %{"const" => 1}, "minContains" => 1} -> :ok
      _ -> :error
    end
  end
end