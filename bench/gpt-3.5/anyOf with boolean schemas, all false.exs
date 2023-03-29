defmodule :"anyOf with boolean schemas, all false-gpt-3.5" do
  def validate({:array, _meta, items}) when items == [boolean: _meta] do
    :ok
  end

  def validate(_) do
    :error
  end
end
