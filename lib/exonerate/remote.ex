defmodule Exonerate.Remote do
  @moduledoc false

  # management of connection to remote schemata.

  alias Exonerate.Cache
  alias Exonerate.Degeneracy

  @spec ensure_authority_loaded!(Env.t, atom, keyword) :: :ok
  @doc """
  Ensures the authority represented by atom exists in the cache.

  If it doesn't exist in the cache, then attempt to fetch it from Exonerate's
  priv directory (or app pointed to by options).

  If it doesn't exist there, prompt the user that the remote json will be
  loaded. If the user picks yes, then download it.

  ### Options

  - `:cache_app`: specifies the otp app whose priv directory cached remote
    JSONs are stored.

    Defaults to `:exonerate`.

  - `:cache_path`: specifies the subdirectory of priv where cached remote
    JSONs are stored.

    Defaults to `/`.

  - `:remote_fetch_adapter`: specifies the module that exposes the public
    function `fetch_remote_cache!/2`.  This function should take an atom
    representing the URL and the options passed to `ensure_authority_loaded!/2`
    and raise if failures occur, or return :ok if it succeeds.

    Defaults to `#{__MODULE__}`.
  """
  def ensure_authority_loaded!(caller, authority, opts) do
    if Cache.has_context?(caller.module, authority) do
      :ok
    else
      load_cache(caller, authority, opts)
    end
  end

  defp load_cache(caller, authority, opts) do
    remote_fetch_adapter = Keyword.get(opts, :remote_fetch_adapter, __MODULE__)
    case File.read(path_for(authority, opts)) do
      {:ok, binary} ->
        # TODO: support YAML here.
        schema = binary
        |> Jason.decode!
        |> Degeneracy.canonicalize(opts)

        Cache.put_schema(caller.module, authority, schema)
        :ok
      {:error, _} ->
        guard_fetch!(authority)
        ensure_priv_directory!(opts)

        body = remote_fetch_adapter.fetch_remote_cache!(authority, opts)

        authority
        |> path_for(opts)
        |> File.write!(body)

        load_cache(caller, authority, opts)
    end
  end

  defp guard_fetch!(authority) do
    response = IO.gets(IO.ANSI.yellow() <> "Exonerate would like to fetch a schema from #{authority}" <> IO.ANSI.reset() <> "\nOk? (y/n) ")

    case response do
      <<yes, _::binary>> when yes in ~C'Yy' ->
        :ok
      _ ->
       raise IO.ANSI.red() <> "fetch rejected for online content #{authority}" <> IO.ANSI.reset()
    end
  end

  @doc false
  def fetch_remote_cache!(authority, _opts) do
    Application.ensure_all_started(:req)

    %{status: 200, body: body} = authority
    |> to_string
    |> Req.get!(decode_body: false)

    body
  end

  # utilities

  defp priv_dir(opts) do
    opts
    |> Keyword.get(:cache_app, :exonerate)
    |> :code.priv_dir
  end

  defp path_for(authority, opts) do
    priv_path = Keyword.get(opts, :cache_path, "/")
    file_name = URI.encode_www_form(to_string(authority))

    opts
    |> priv_dir
    |> Path.join(priv_path)
    |> Path.join(file_name)
  end

  defp ensure_priv_directory!(opts) do
    priv_dir = priv_dir(opts)
    if File.dir?(priv_dir), do: :ok, else: File.mkdir_p!(priv_dir)
  end

end
