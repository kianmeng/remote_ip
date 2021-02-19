defmodule RemoteIp.Debugger do
  # TODO
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require Logger
      import unquote(__MODULE__)
    end
  end

  defmacro debug(id, inputs \\ [], do: output) do
    if debug?(id) do
      quote do
        inputs = unquote(inputs)
        output = unquote(output)
        unquote(__MODULE__).__log__(unquote(id), inputs, output)
        output
      end
    else
      output
    end
  end

  @debug Application.get_env(:remote_ip, :debug, false)

  cond do
    is_list(@debug) ->
      defp debug?(id), do: Enum.member?(@debug, id)

    is_boolean(@debug) ->
      defp debug?(_), do: @debug
  end

  @level Application.get_env(:remote_ip, :level, :debug)

  defmacro __log__(id, inputs, output) do
    quote do
      Logger.log(
        unquote(@level),
        unquote(__MODULE__).__message__(
          unquote(id),
          unquote(inputs),
          unquote(output)
        )
      )
    end
  end

  def __message__(:options, [], options) do
    headers = inspect(options[:headers])
    proxies = inspect(options[:proxies] |> Enum.map(&InetCidr.to_string/1))
    clients = inspect(options[:clients] |> Enum.map(&InetCidr.to_string/1))

    [
      "Processing remote IP\n",
      "  headers: #{headers}\n",
      "  proxies: #{proxies}\n",
      "  clients: #{clients}"
    ]
  end

  def __message__(:headers, [], headers) do
    "Taking forwarding headers from #{inspect(headers)}"
  end

  def __message__(:forwarding, [], headers) do
    "Parsing IPs from forwarding headers: #{inspect(headers)}"
  end

  def __message__(:ips, [], ips) do
    "Parsed IPs from forwarding headers: #{inspect(ips)}"
  end

  def __message__(:type, [ip], type) do
    case type do
      :client -> "#{inspect(ip)} is a known client IP"
      :proxy -> "#{inspect(ip)} is a known proxy IP"
      :reserved -> "#{inspect(ip)} is a reserved IP"
      :unknown -> "#{inspect(ip)} is an unknown IP, assuming it's the client"
    end
  end

  def __message__(:call, [old], new) do
    origin = inspect(old.remote_ip)
    client = inspect(new.remote_ip)

    if client != origin do
      "Processed remote IP, found client #{client} to replace #{origin}"
    else
      "Processed remote IP, no client found to replace #{origin}"
    end
  end

  def __message__(:from, [], ip) do
    if ip == nil do
      "Processed remote IP, no client found"
    else
      "Processed remote IP, found client #{inspect(ip)}"
    end
  end
end