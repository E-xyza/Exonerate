defmodule :"pattern is not anchored-gpt-3.5" do
  def validate(json) do
    case json do
      %{"pattern" => pattern} ->
        result =
          case Regex.run(pattern, "a+") do
            nil -> :error
            _ -> :ok
          end

        result

      _ ->
        :error
    end
  end
end