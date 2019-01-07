defmodule Exonerate do

  # module typedefs
  @type schema ::
    %{optional(String.t) => schema}
    | list(schema)
    | String.t
    | number

  def error_reduction(arr) when is_list(arr),
    do: arr |> Enum.reduce(:ok, &Exonerate.error_reduction/2)

  def error_reduction(:ok, :ok), do: :ok
  def error_reduction(:ok, err), do: err
  def error_reduction(err, _), do: err

  def invert(nil, :ok), do: :ok
  def invert(_, :ok), do: {:error, "does not conform to JSON schema"}
  def invert(_, {:error, _}), do: :ok

end
