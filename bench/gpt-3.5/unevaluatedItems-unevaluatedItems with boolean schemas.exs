defmodule :"unevaluatedItems with boolean schemas-gpt-3.5" do
  def validate(object) when is_list(object) do
    if Enum.all?(object, &is_boolean/1) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end