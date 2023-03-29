defmodule Benchmark.Test do
  @enforce_keys [:description, :data, :valid]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          description: String.t(),
          data: Exonerate.Type.json(),
          valid: boolean
        }

  def unpack_tests(tests) do
    Enum.map(tests, fn test ->
      %__MODULE__{
        description: test["description"],
        data: test["data"],
        valid: test["valid"]
      }
    end)
  end
end
