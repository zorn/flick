defmodule Flick.RankedVoting do
  @moduledoc """
  Provides functions related to managing `Flick.RankedVoting.Ballot` entities.
  """

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
  def update_ballot(%Ballot{published_at: published_at}, _attrs)
      when not is_nil(published_at) do
    {:error, :can_not_update_published_ballot}
  end

  def update_ballot(%Ballot{published_at: nil} = ballot, attrs) do
    ballot
    |> change_ballot(attrs)
    |> Repo.update()
  end

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

  def publish_ballot(%Ballot{published_at: published_at}, _published_at)
      when not is_nil(published_at) do
    {:error, :ballot_already_published}
  end

  def publish_ballot(%Ballot{} = ballot, published_at) do
    ballot
    |> change_ballot(%{published_at: published_at})
    |> Repo.update()
  end

  @doc """
  Returns a list of all `Flick.RankedVoting.Ballot` entities.
  """
  @spec list_ballots() :: [Ballot.t()]
  def list_ballots() do
    # TODO: Currently there is no expectation regarding the order of the
    # returned list. We should add something.

    Repo.all(Ballot)
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
  def get_ballot_by_url_slug!(url_slug)
      when is_binary(url_slug) do
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
    Repo.get_by!(Ballot, url_slug: url_slug, id: secret)
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
  @spec record_vote(Ballot.t(), map()) :: {:ok, Vote.t()} | {:error, Ecto.Changeset.t(Vote.t())}
  def record_vote(ballot, attrs) do
    attrs = Map.put(attrs, "ballot_id", ballot.id)

    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.RankedVoting.Vote`
  entity.

  ## Options

  * `:action` - An optional atom applied to the changeset, useful for forms that
    look to a changeset's action to influence form behavior.
  """
  @spec change_vote(Vote.t() | Vote.struct_t(), map()) :: Ecto.Changeset.t(Vote.t())
  def change_vote(%Vote{} = vote, attrs, opts \\ []) do
    opts = Keyword.validate!(opts, action: nil)
    changeset = Vote.changeset(vote, attrs)

    if opts[:action] do
      Map.put(changeset, :action, opts[:action])
    else
      changeset
    end
  end
end
