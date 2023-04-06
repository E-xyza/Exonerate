defmodule :"type-integer type matches integers-gpt-3.5" do
  def validate(value)
        when is_integer(value), do: :ok
    def validate(_), do: :error
  end
end
