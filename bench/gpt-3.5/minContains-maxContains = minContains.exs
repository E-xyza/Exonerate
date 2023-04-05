defmodule :"maxContains = minContains-gpt-3.5" do
  def validate(schema) do
    case schema do
      %{"contains" => %{"const" => constant}, "maxContains" => max, "minContains" => min} ->
        fn decoded when is_list(decoded) ->
          count = decoded |> Enum.count(&(&1 == constant))

          if min <= count and count <= max do
            :ok
          else
            :error
          end
        end

      _ ->
        fn _ -> :error end
    end
  end
end
