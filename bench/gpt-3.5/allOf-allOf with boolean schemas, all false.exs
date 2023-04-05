defmodule :"allOf-allOf with boolean schemas, all false-gpt-3.5" do
  def validate({:array, values} = json) when values == [false, false] do
    :error
  end

  def validate(json) do
    :ok
  end
end
