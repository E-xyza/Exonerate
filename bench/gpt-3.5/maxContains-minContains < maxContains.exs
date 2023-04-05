defmodule :"maxContains-minContains < maxContains-gpt-3.5" do
  def validate(decoded_json) when is_map(decoded_json) do
    case decoded_json do
      %{"contains" => contains, "maxContains" => max_contains, "minContains" => min_contains} ->
        case contains do
          %{"const" => 1} ->
            if Map.keys(decoded_json) |> (length() in min_contains..max_contains) do
              :ok
            else
              :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
