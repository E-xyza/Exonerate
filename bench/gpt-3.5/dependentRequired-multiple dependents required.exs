defmodule :"dependentRequired-multiple dependents required-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object["quux"] do
      nil ->
        :error

      _ ->
        if Enum.any?(object["quux"], &is_nil/1) do
          :error
        else
          :ok
        end
    end
  end

  def validate(_) do
    :error
  end
end