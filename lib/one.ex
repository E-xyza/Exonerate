defmodule Foo do
  def one(data) do
    entrypoint_at_(data, "/")
  end
  defp entrypoint_at_(array, path) when is_list(array) do
    require Exonerate.Combining
    []

    with :ok <- entrypoint_at_allOf(array, path) do
      :ok
    end
  end
  defp entrypoint_at_(boolean, path) when is_boolean(boolean) do
    with :ok <- entrypoint_at_allOf(boolean, path) do
      :ok
    end
  end
  defp entrypoint_at_(integer, path) when is_integer(integer) do
    with :ok <- entrypoint_at_allOf(integer, path) do
      :ok
    end
  end
  defp entrypoint_at_(null, path) when is_nil(null) do
    with :ok <- entrypoint_at_allOf(null, path) do
      :ok
    end
  end
  defp entrypoint_at_(float, path) when is_float(float) do
    with :ok <- entrypoint_at_allOf(float, path) do
      :ok
    end
  end
  defp entrypoint_at_(object, path) when is_map(object) do
    seen = MapSet.new()

    with {:ok, new_seen} <- entrypoint_at_allOf__tracked_object(object, path),
         seen = MapSet.union(seen, new_seen),
         :ok <- entrypoint_at__object_iterator(object, path, seen) do
      :ok
    end
  end
  defp entrypoint_at_(string, path) when is_binary(string) do
    if String.valid?(string) do
      with :ok <- entrypoint_at_allOf(string, path) do
        :ok
      end
    else
      require Exonerate.Tools

      Exonerate.Tools.mismatch(
        string,
        "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
        ["type"],
        path
      )
    end
  end
  defp entrypoint_at_(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["type"],
      path
    )
  end
  defp entrypoint_at_allOf(data, path) do
    entrypoint_at_allOf_0(data, path)
  end
  defp entrypoint_at_allOf_0(array, path) when is_list(array) do
    require Exonerate.Combining
    []

    with :ok <- entrypoint_at_allOf_0_allOf(array, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(boolean, path) when is_boolean(boolean) do
    with :ok <- entrypoint_at_allOf_0_allOf(boolean, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(integer, path) when is_integer(integer) do
    with :ok <- entrypoint_at_allOf_0_allOf(integer, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(null, path) when is_nil(null) do
    with :ok <- entrypoint_at_allOf_0_allOf(null, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(float, path) when is_float(float) do
    with :ok <- entrypoint_at_allOf_0_allOf(float, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(object, path) when is_map(object) do
    with :ok <- entrypoint_at_allOf_0_allOf(object, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0(string, path) when is_binary(string) do
    if String.valid?(string) do
      with :ok <- entrypoint_at_allOf_0_allOf(string, path) do
        :ok
      end
    else
      require Exonerate.Tools

      Exonerate.Tools.mismatch(
        string,
        "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
        ["allOf", "0", "type"],
        path
      )
    end
  end
  defp entrypoint_at_allOf_0(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["allOf", "0", "type"],
      path
    )
  end
  defp entrypoint_at_allOf_0_allOf(data, path) do
    entrypoint_at_allOf_0_allOf_0(data, path)
  end
  defp entrypoint_at_allOf_0_allOf_0(array, path) when is_list(array) do
    require Exonerate.Combining
    []

    with do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(boolean, path) when is_boolean(boolean) do
    with do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(integer, path) when is_integer(integer) do
    with do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(null, path) when is_nil(null) do
    with do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(float, path) when is_float(float) do
    with do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(object, path) when is_map(object) do
    with :ok <- entrypoint_at_allOf_0_allOf_0_maxProperties(object, path) do
      :ok
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(string, path) when is_binary(string) do
    if String.valid?(string) do
      with do
        :ok
      end
    else
      require Exonerate.Tools

      Exonerate.Tools.mismatch(
        string,
        "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
        ["allOf", "0", "allOf", "0", "type"],
        path
      )
    end
  end
  defp entrypoint_at_allOf_0_allOf_0(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["allOf", "0", "allOf", "0", "type"],
      path
    )
  end
  defp entrypoint_at_allOf_0_allOf_0_maxProperties(object, path) do
    case object do
      object when map_size(object) <= 3 ->
        :ok

      _ ->
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          object,
          "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
          ["allOf", "0", "allOf", "0", "maxProperties"],
          path
        )
    end
  end
  defp entrypoint_at__object_iterator(object, path, seen) do
    require Exonerate.Tools

    Enum.reduce_while(object, :ok, fn
      {key, value}, :ok ->
        result =
          if key in seen do
            :ok
          else
            entrypoint_at_unevaluatedProperties(value, Path.join(path, key))
          end

        {:cont, result}

      _, Exonerate.Tools.error_match(error) ->
        {:halt, error}
    end)
  end
  defp entrypoint_at_unevaluatedProperties(string, path) when is_binary(string) do
    if String.valid?(string) do
      with do
        :ok
      end
    else
      require Exonerate.Tools

      Exonerate.Tools.mismatch(
        string,
        "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
        ["unevaluatedProperties", "type"],
        path
      )
    end
  end
  defp entrypoint_at_unevaluatedProperties(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["unevaluatedProperties", "type"],
      path
    )
  end
  defp entrypoint_at_allOf__tracked_object(data, path) do
    entrypoint_at_allOf_0__tracked_object(data, path)
  end
  defp entrypoint_at_allOf_0__tracked_object(object, path) when is_map(object) do
    seen = MapSet.new()

    with {:ok, new_seen} <- entrypoint_at_allOf_0_allOf__tracked_object(object, path),
         seen = MapSet.union(seen, new_seen) do
      {:ok, seen}
    end
  end
  defp entrypoint_at_allOf_0__tracked_object(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["allOf", "0", "type"],
      path
    )
  end
  defp entrypoint_at_allOf_0_allOf__tracked_object(data, path) do
    entrypoint_at_allOf_0_allOf_0__tracked_object(data, path)
  end
  defp entrypoint_at_allOf_0_allOf_0__tracked_object(object, path) when is_map(object) do
    seen = MapSet.new()

    with :ok <- entrypoint_at_allOf_0_allOf_0_maxProperties__tracked_object(object, path) do
      {:ok, seen}
    end
  end
  defp entrypoint_at_allOf_0_allOf_0__tracked_object(content, path) do
    require Exonerate.Tools

    Exonerate.Tools.mismatch(
      content,
      "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
      ["allOf", "0", "allOf", "0", "type"],
      path
    )
  end
  defp entrypoint_at_allOf_0_allOf_0_maxProperties__tracked_object(object, path) do
    case object do
      object when map_size(object) <= 3 ->
        :ok

      _ ->
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          object,
          "exonerate://26BB2E1A928191A1EBA7384D16B16C1DCEE684935D3489C5EA6F9445C80DBFA4/",
          ["allOf", "0", "allOf", "0", "maxProperties"],
          path
        )
    end
  end
  defp entrypoint_at_allOf_0_allOf__tracked_object(data, path) do
    entrypoint_at_allOf_0_allOf_0__tracked_object(data, path)
  end
end
