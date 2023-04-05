defmodule :"minContains-maxContains = minContains" do
  def validate(json) do
    case json do
      list when is_list(list) ->
        count = Enum.count(list, fn x -> x == 1 end)
        if count == 2, do: :ok, else: :error

      _ ->
        :error
    end
  end
end
