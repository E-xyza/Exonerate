defmodule :"prefixItems with boolean schemas-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate({"prefixItems", [true, false]}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
