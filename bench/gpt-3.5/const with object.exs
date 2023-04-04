defmodule :"const with object-gpt-3.5" do
  def validate(object)
      when is_map(object) and read_const(object) == {:ok, %{"baz" => "bax", "foo" => "bar"}} do
    :ok
  end

  def validate(_) do
    :error
  end

  defp read_const(%{"const" => %{"baz" => "bax", "foo" => "bar"}}) do
    {:ok, %{"baz" => "bax", "foo" => "bar"}}
  end

  defp read_const(_) do
    :error
  end
end
