defmodule :"uniqueItems validation" do
  def validate(list) when is_list(list) do
    unique_list = Enum.uniq(list)

    if length(list) == length(unique_list) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
