defmodule :"minContains=1 with contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Enum.count(Enum.filter_values(object, &(&1 == 1))) >= 1 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end