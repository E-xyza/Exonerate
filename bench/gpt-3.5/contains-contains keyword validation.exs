defmodule :"contains-contains keyword validation-gpt-3.5" do
  def validate(object) when is_integer(object) do
    if object >= 5 do
      :ok
    else
      :error
    end
  end

  def validate(object) when is_list(object) do
    if length(object) >= 5 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end