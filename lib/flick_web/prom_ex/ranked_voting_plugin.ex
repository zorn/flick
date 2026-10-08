defmodule FlickWeb.PromEx.RankedVotingPlugin do
  @moduledoc """
  Turns the telemetry events from `Flick.RankedVoting` into Prometheus metrics.
  """

  use PromEx.Plugin

  @impl PromEx.Plugin
  def event_metrics(_opts) do
    Event.build(:flick_ranked_voting_event_metrics, [
      distribution(
        [:flick, :ranked_voting, :create_vote, :duration, :milliseconds],
        event_name: [:flick, :ranked_voting, :create_vote, :stop],
        description: "The time it takes to validate and record a vote.",
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:result],
        reporter_options: [buckets: [1, 2, 5, 10, 25, 50, 100, 250]]
      )
    ])
  end
end
