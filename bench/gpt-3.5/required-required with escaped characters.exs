defmodule :"required-required with escaped characters-gpt-3.5" do
  def validate(object) when is_map(object), do: :ok
  def validate(_), do: :error

  def validate([_ | _] = list) do
    {errors, _} = Enum.reduce(list, {[], []}, fn
      required, {acc_errors, acc_reqs} ->
        case validate_required(required) do
          :ok ->
            {acc_errors, [required | acc_reqs]}
          _error ->
            {[required | acc_errors], acc_reqs}
        end
    end)
    if errors, do: {:error, Enum.reverse(errors)}
    else, do: :ok
  end

  defp validate_required(required) do
    required
    |> Poison.decode!()
    |> validate_required_decoded()
  end

  defp validate_required_decoded(%{"required" => [value | _]}) when is_binary(value), do: :ok
  defp validate_required_decoded(_), do: :error
end
