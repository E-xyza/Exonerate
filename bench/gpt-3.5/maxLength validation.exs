defmodule :"maxLength validation-gpt-3.5" do
  defmodule MySchema do
    def validate(value) when is_map(value) do
      if MapSize.check(value) <= 2 do
        :ok
      else
        :error
      end
    end

    def validate(_) do
      :error
    end
  end

  defmodule MapSize do
    def check(map) do
      :erlang.map_size(map)
    end
  end
end
