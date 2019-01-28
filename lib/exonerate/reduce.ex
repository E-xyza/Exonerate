defmodule Exonerate.Reduce do

  @type json :: Exonerate.json
  @type mismatch :: Exonerate.mismatch
  @type check_fn :: ((json) -> :ok | mismatch)

  @spec anyof(json, [check_fn], check_fn, mismatch) :: :ok | mismatch
  def anyof(val, check_fns, base_fn, mismatch) do
    check_fns
    |> Enum.map(&(&1.(val)))
    |> Enum.any?(&(&1 == :ok))
    |> if do
      base_fn.(val)
    else
      mismatch
    end
  end

  @spec allof(json, [check_fn], mismatch) :: :ok | mismatch
  def allof(val, check_fns, mismatch) do
    check_fns
    |> Enum.map(&(&1.(val)))
    |> Enum.all?(&(&1 == :ok))
    |> if do
      :ok
    else
      mismatch
    end
  end

  @spec oneof(json, [check_fn], check_fn, mismatch) :: :ok | mismatch
  def oneof(val, check_fns, base_fn, mismatch) do
    check_fns
    |> Enum.map(&(&1.(val)))
    |> Enum.count(&(&1 == :ok))
    |> case do
      1 -> base_fn.(val)
      _ -> mismatch
    end
  end

  @spec apply_not(json, check_fn, check_fn, mismatch) :: :ok | mismatch
  def apply_not(val, not_fn, base_fn, mismatch) do
    val
    |> not_fn.()
    |> case do
      :ok -> mismatch
      {:mismatch, _} -> base_fn.(val)
    end
  end

end
