defmodule :"if-then-else-if with boolean schema false-gpt-3.5" do
  def validate(%{else: %{const: "else"}, if: false, then: %{const: "then"}}) do
    :ok
  end

  def validate(_) do
    :error
  end
end