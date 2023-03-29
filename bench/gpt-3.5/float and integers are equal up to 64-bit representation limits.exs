defmodule :"float and integers are equal up to 64-bit representation limits-gpt-3.5" do
  def validate(json) do
    try do
      case json do
        %{"const" => value} ->
          if value == 9_007_199_254_740_992 do
            :ok
          else
            :error
          end

        %{"type" => "object"} ->
          if is_map(json) do
            :ok
          else
            :error
          end

        _ ->
          :error
      end
    rescue
      _ -> :error
    end
  end
end
