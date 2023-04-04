defmodule :"unevaluatedItems false-gpt-3.5" do
  def validate(object) when is_list(object) and not Enum.any?(object, &is_map/1) do
    :ok
  end

  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
