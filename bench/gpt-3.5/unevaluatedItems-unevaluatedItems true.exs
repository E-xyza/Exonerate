defmodule :"unevaluatedItems-unevaluatedItems true-gpt-3.5" do
  def validate(object) when is_list(object) do
    if Enum.all?(object, &is_map/1) do
      :ok
    else
      :error
    end
  end

  def validate(object) do
    :error
  end
end
