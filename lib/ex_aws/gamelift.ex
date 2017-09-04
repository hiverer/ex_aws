defmodule ExAws.GameLift do
  @moduledoc """
  Operations on the AWS GameLift service.

  http://docs.aws.amazon.com/LINK_MUST_BE_HERE
  """

  import ExAws.Utils, only: [camelize_key: 1, camelize_keys: 2]
  alias __MODULE__

  @namespace "GameLift"
  
  defp encode_root(value, options \\ []) do
      case ExAws.GameLift.Encodable.encode(value, options) do
        %{"M" => value} -> value
        %{"L" => value} -> value
      end
  end
  
  defp convert_player_attributes(attributes_list) do
    case is_nil(attributes_list) do
        true->[]
        false->encode_root(attributes_list)
    end
  end

  defp request(action, data) do
    operation = action
    |> Atom.to_string
    |> Macro.camelize

    ExAws.Operation.JSON.new(:gamelift, %{
      data: data,
      headers: [
        {"x-amz-target", "#{@namespace}.#{operation}"},
        {"content-type", "application/x-amz-json-1.1"},
      ]
    })
  end

  defp camelize_opts(opts) do
    opts
    |> Map.new
    |> ExAws.Utils.camelize_keys
  end

  @spec get_aliases(Map.t) :: Map.t
  def get_aliases(opts \\ []) do
    request(:list_aliases, camelize_opts(opts))
  end

  @spec start_matchmaking(Map.t) :: Map.t
  def start_matchmaking(opts \\ []) do
    opts = opts
    |> Map.new
    |> Map.merge(%{players: Enum.map(opts[:players], 
      fn 
          player -> 
              case Map.get(player, :player_attributes, nil) do
                  nil->%{player_id: player[:player_id], team: player[:team], latency_in_ms: player[:latency_in_ms]}
                  attrs->%{player_id: player[:player_id], team: player[:team], latency_in_ms: player[:latency_in_ms], 
                  player_attributes: convert_player_attributes(attrs)}
              end
              |> ExAws.Utils.camelize_keys
      end)})
    |> ExAws.Utils.camelize_keys

    request(:start_matchmaking, opts)
  end

  @spec stop_matchmaking(Map.t) :: Map.t
  def stop_matchmaking(opts \\ []) do
    request(:stop_matchmaking, camelize_opts(opts))
  end

  @spec accept_match(
    ticket_id :: String.t,
    player_ids :: [String.t],
    :accept | :reject) :: ExAws.Operation.JSON.t
  def accept_match(ticket_id, player_ids, acceptance_type \\ :accept) do
    data = %{
      "TicketId" => ticket_id,
      "PlayerIds" => player_ids,
      "AcceptanceType" => acceptance_type |> Atom.to_string |> String.upcase,
    }
    request(:accept_match, data)
  end
end
