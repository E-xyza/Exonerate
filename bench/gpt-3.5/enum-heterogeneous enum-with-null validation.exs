defmodule :"heterogeneous enum-with-null validation-gpt-3.5" do
  def validate(value) when value in [6, nil] do
    :ok
  end

  def validate(_) do
    :error
  end
end