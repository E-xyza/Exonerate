defmodule :"enum with 0 does not match false-gpt-3.5" do
  @spec validate(any()) :: :ok | :error
  def validate(json) do
    case json do
      %{"enum" => [0]} -> :ok
      _ -> :error
    end
  end
end