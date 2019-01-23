defmodule Exonerate.Reduce do

  @type json :: Exonerate.json
  @type mismatch :: Exonerate.mismatch

  @spec anyof(json, module, [atom], atom, atom) :: :ok | mismatch
  def anyof(val, module, functions, base, method) do
    functions
    |> Enum.map(&apply(module, &1, [val]))
    |> Enum.any?(&(&1 == :ok))
    |> if do
      apply(module, base, [val])
    else
      {:mismatch, {module, method, [val]}}
    end
  end

  @spec allof(json, module, [atom], atom) :: :ok | mismatch
  def allof(val, module, functions, method) do
    functions
    |> Enum.map(&apply(module, &1, [val]))
    |> Enum.all?(&(&1 == :ok))
    |> if do
      :ok
    else
      {:mismatch, {module, method, [val]}}
    end
  end

  @spec oneof(json, module, [atom], atom) :: :ok | mismatch
  def oneof(val, module, options, method_ref) do
    options
    |> Enum.map(&apply(module, &1, [val]))
    |> Enum.count(&(&1 == :ok))
    |> case do
      1 -> :ok
      _ -> {:mismatch, {module, method_ref, [val]}}
    end
  end

  @spec apply_not(json, module, atom) :: :ok | mismatch
  def apply_not(val, module, method) do
    module
    |> apply(method, [val])
    |> case do
      :ok -> {:mismatch, {module, method, [val]}}
      {:mismatch, _} -> :ok
    end
  end

end
