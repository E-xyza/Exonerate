defmodule :"unevaluatedItems-unevaluatedItems as schema-gpt-3.5" do
  def validate(object) when is_list(object) do
    if Enum.all?(object, fn elem -> is_binary(elem) end) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
