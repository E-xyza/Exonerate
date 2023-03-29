defmodule :"heterogeneous enum-with-null validation-gpt-3.5" do
  def validate(nil) do
    {:error, "Null is not allowed."}
  end

  def validate(6) do
    :ok
  end

  def validate(_) do
    {:error, "Value must be either 6 or null."}
  end
end
