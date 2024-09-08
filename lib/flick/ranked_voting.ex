defmodule Flick.RankedVoting do
  @moduledoc """
  Provides functions related to managing `Flick.RankedVoting.Ballot` entities.
  """

  import Ecto.Query

  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.Vote
  alias Flick.Repo

  @doc """
  Creates a new `Flick.RankedVoting.Ballot` entity with the given `title` and `questions`.
  """
  @spec create_ballot(map()) :: {:ok, Ballot.t()} | {:error, Ecto.Changeset.t(Ballot.t())}
  def create_ballot(attrs) when is_map(attrs) do
    %Ballot{}
    |> change_ballot(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given `Flick.RankedVoting.Ballot` entity with the given attributes.

  If the `Flick.RankedVoting.Ballot` has already been published, an error is returned.
  """
  @spec update_ballot(Ballot.t(), map()) ::
          {:ok, Ballot.t()}
          | {:error, Ecto.Changeset.t(Ballot.t())}
          | {:error, :can_not_update_published_ballot}

  def update_ballot(%Ballot{published_at: nil} = ballot, attrs) do
    ballot
    |> change_ballot(attrs)
    |> Repo.update()
  end

  def update_ballot(_ballot, _attrs) do
    {:error, :can_not_update_published_ballot}
  end

  @doc """
  Returns a boolean value indicating whether the given
  `Flick.RankedVoting.Ballot` entity can be updated.
  """
  @spec can_update_ballot?(Ballot.t()) :: boolean()
  def can_update_ballot?(%Ballot{published_at: nil}), do: true
  def can_update_ballot?(_), do: false

  @doc """
  Publishes the given `Flick.RankedVoting.Ballot` entity.

  Once a `Flick.RankedVoting.Ballot` entity is published, it can no longer be updated.
  Only a published ballot can be voted on.
  """
  @spec publish_ballot(Ballot.t(), DateTime.t()) ::
          {:ok, Ballot.t()}
          | {:error, Ecto.Changeset.t(Ballot.t())}
          | {:error, :ballot_already_published}
  def publish_ballot(ballot, published_at \\ DateTime.utc_now())

  def publish_ballot(%Ballot{published_at: nil} = ballot, published_at) do
    ballot
    |> change_ballot(%{published_at: published_at})
    |> Repo.update()
  end

  def publish_ballot(_ballot, _published_at) do
    {:error, :ballot_already_published}
  end

  @doc """
  Returns a list of all `Flick.RankedVoting.Ballot` entities.
  """
  @spec list_ballots() :: [Ballot.t()]
  def list_ballots do
    Ballot
    |> order_by([ballot], desc: ballot.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns a `Flick.RankedVoting.Ballot` entity for the given id.

  Raises `Ecto.NoResultsError` if no entity was found.
  """
  @spec get_ballot!(Ballot.id()) :: Ballot.t()
  def get_ballot!(ballot_id) do
    Repo.get!(Ballot, ballot_id)
  end

  @doc """
  Returns a `Flick.RankedVoting.Ballot` entity for the given `url_slug` value.

  Raises `Ecto.NoResultsError` if no entity was found.
  """
  @spec get_ballot_by_url_slug!(String.t()) :: Ballot.t()
  def get_ballot_by_url_slug!(url_slug) when is_binary(url_slug) do
    Repo.get_by!(Ballot, url_slug: url_slug)
  end

  @doc """
  Returns a `Flick.RankedVoting.Ballot` entity for the given `url_slug` value
  and `secret`.

  Raises `Ecto.NoResultsError` if no entity was found.
  """
  @spec get_ballot_by_url_slug_and_secret!(String.t(), String.t()) :: Ballot.t()
  def get_ballot_by_url_slug_and_secret!(url_slug, secret)
      when is_binary(url_slug) and is_binary(secret) do
    Repo.get_by!(Ballot, url_slug: url_slug, secret: secret)
  end

  @doc """
  Fetches a `Flick.RankedVoting.Ballot` entity for the given id.
  """
  @spec fetch_ballot(Ballot.id()) :: {:ok, Ballot.t()} | {:error, :ballot_not_found}
  def fetch_ballot(ballot_id) do
    case Repo.get(Ballot, ballot_id) do
      nil -> {:error, :ballot_not_found}
      ballot -> {:ok, ballot}
    end
  end

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.RankedVoting.Ballot` entity.
  """
  @spec change_ballot(Ballot.t() | Ballot.struct_t(), map()) :: Ecto.Changeset.t(Ballot.t())
  def change_ballot(%Ballot{} = ballot, attrs) do
    Ballot.changeset(ballot, attrs)
  end

  @doc """
  Records a vote for the given `Flick.RankedVoting.Ballot` entity.
  """
  @spec create_vote(Ballot.t(), map()) :: {:ok, Vote.t()} | {:error, Ecto.Changeset.t(Vote.t())}
  def create_vote(ballot, attrs) do
    attrs = Map.put(attrs, "ballot_id", ballot.id)

    %Vote{}
    |> Vote.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given `Flick.RankedVoting.Vote` entity with the given attributes.

  The `:weight` field is the only expected edited value.

  If the given `Flick.RankedVoting.Ballot` does not align with the `ballot_id`
  of the `Flick.RankedVoting.Vote`, then the function will not match.
  """
  @spec update_vote(Ballot.t(), Vote.t(), map()) ::
          {:ok, Vote.t()} | {:error, Ecto.Changeset.t(Vote.t())}
  def update_vote(%Ballot{id: id}, %Vote{ballot_id: ballot_id} = vote, attrs)
      when id == ballot_id do
    vote
    |> Vote.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `Ecto.Changeset` to changes to a `Flick.RankedVoting.Vote` value.

  If the incoming `vote` struct has an `id`, the changeset will be created for
  updating, else creation. See `Flick.RankedVoting.Vote.create_changeset/2` and
  `Flick.RankedVoting.Vote.update_changeset/2` for more details.

  ## Options

  * `:action` - An optional atom applied to the changeset, useful for forms that
    look to a changeset's action to influence form behavior.
  """
  @spec change_vote(Vote.t() | Vote.struct_t(), map(), keyword()) :: Ecto.Changeset.t(Vote.t())
  def change_vote(%Vote{} = vote, attrs, opts \\ []) do
    opts = Keyword.validate!(opts, action: nil)

    changeset =
      if vote.id do
        Vote.update_changeset(vote, attrs)
      else
        Vote.create_changeset(vote, attrs)
      end

    if opts[:action] do
      Map.put(changeset, :action, opts[:action])
    else
      changeset
    end
  end

  @doc """
  Returns a list of `Flick.RankedVoting.Vote` entities associated with the given
  `ballot_id`.
  """
  @spec list_votes_for_ballot_id(Ballot.id()) :: [Vote.t()]
  def list_votes_for_ballot_id(ballot_id) do
    Vote
    |> where(ballot_id: ^ballot_id)
    |> order_by([vote], desc: vote.inserted_at)
    |> Repo.all()
  end

  @typedoc """
  A report describing the voting results for a ballot, displaying each possible
  answer and the point total it received.
  """
  @type ballot_results_report :: [%{value: String.t(), points: float()}]

  @doc """
  Returns a `t:ballot_results_report/0` for the passed in ballot id.

  When calculating the points:

  - 5 points are awarded for the first preference
  - 4 points are awarded for the second preference
  - 3 points are awarded for the third preference
  - 2 points are awarded for the fourth preference
  - 1 point is awarded for the fifth preference

  These numbers are multiplied by the weight of the vote.
  """
  @spec get_ballot_results_report(Ballot.id()) :: ballot_results_report()
  def get_ballot_results_report(ballot_id) do
    ballot = get_ballot!(ballot_id)
    answers = Ballot.possible_answers_as_list(ballot.possible_answers)
    votes = list_votes_for_ballot_id(ballot_id)

    reports =
      Enum.reduce(answers, [], fn answer, acc ->
        answer_report = %{
          value: answer,
          points: points_for_answer_in_votes(votes, answer)
        }

        [answer_report | acc]
      end)

    reports
    |> Enum.sort(&(&1.value <= &2.value))
    |> Enum.sort(&(&1.points >= &2.points))
  end

  @spec points_for_answer_in_votes([Vote.t()], any()) :: float()
  defp points_for_answer_in_votes(votes, answer) do
    # Returns the total points for the given answer across all votes while
    # taking into account the index of the answer in the full list of ranked
    # answers and the weight of each vote.
    Enum.reduce(votes, 0, fn vote, total ->
      ranked_answer_index =
        Enum.find_index(vote.ranked_answers, fn ranked_answer ->
          ranked_answer.value == answer
        end)

      case ranked_answer_index do
        nil -> total
        0 -> total + 5 * vote.weight
        1 -> total + 4 * vote.weight
        2 -> total + 3 * vote.weight
        3 -> total + 2 * vote.weight
        4 -> total + 1 * vote.weight
      end
    end)
  end

  @doc """
  Returns the number of allowed answers a vote can provide for a ballot.

  This number will match the count of possible answers the ballot has defined,
  up to a maximum of 5.
  """
  @spec allowed_answer_count_for_ballot(Ballot.t()) :: non_neg_integer()
  def allowed_answer_count_for_ballot(%Ballot{} = ballot) do
    possible_answer_count =
      ballot.possible_answers
      |> Ballot.possible_answers_as_list()
      |> length()

    min(5, possible_answer_count)
  end
end
