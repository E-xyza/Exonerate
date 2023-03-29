defmodule :"maxContains < minContains-gpt-3.5" do
  def validate(decoded_json) do
    case decoded_json do
      %{"contains" => %{"const" => 1}, "maxContains" => 1, "minContains" => 3} -> :ok
      _ -> :error
    end
  end
end
