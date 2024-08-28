# Ubiquitous Language

## Domain Terms

* **Ballot Owner** -- The user who created and can administer the ballot.
* **Voter** -- A user who is encouraged to answer the question presented on the
  ballot with their preferences.
* **Ballot** -- A user creates a ballot when they want to present a question to
  a potential voter and capture ranked answers (preferences).
* **Question** -- A phrase that inspires a voter to provide a collection of
  ranked answers.
* **Possible Answers** -- When building a question on a ballot, a ballot owner
  creates a comma-separated list of possible answers for the ballot question.
* First Preference—When a user comes to have their vote captured, we ask for
  their preferences. (See `Sharp Edges #1` below for more info.)
* **Ranked Answer** -- The captured ranked answer provided by a voter for a
  question.

## Sharp Edges

1. In the code, we have a schema for `Flick.RankedVoting.RankedAnswer`, and when
   a user is creating a ballot, we ask them for `Possible Answers (comma
   separated)`. However, when capturing a vote, we ask those users for their
   `First Preference`, `Second Preference`, etcetera. Under the hood, these
   "preferences" are stored as `RankedAnswers` which feels like an unfortunate
   misalignment of terms. Currently, the presentation perspective is worth the
   cost of this misalignment, but feedback is welcome.

## Software Terms

### Structs, Values, and Entities 

* **Struct** -- When we need to represent a complex domain concept that Elixir
  primitives can not represent, we often lean on [Elixir Structs] and [Ecto
  Schemas] to build those concepts.  
* **Entity** -- Many domain concepts are not defined primarily by their
  attributes but rather by their continued identity; these are called entities.
  Entities typically change over time, and equality is based on identity, not
  attributes.
* **Value Object** -- When you only care about the attributes of a domain
  concept, classify it as a value object. These value objects describe things
  but have no identity in and of themselves. Generally, value objects do not
  change over time.

> **Aside:** Working in the Elixir environment, we tend to say `Value` over
> `Value Object` since that distinction is needed only for object-oriented
> languages. 

[Elixir Structs]: https://hexdocs.pm/elixir/main/structs.html
[Ecto Schemas]: https://hexdocs.pm/ecto/Ecto.html#module-schema

#### An example: Is an `Address` an entity or a value object? It depends.

Whether or not any domain concept should consider an entity or a value object
depends entirely on its usage. An example from [Domain-Driven Design]:

> In software for a mail-order company, an address is needed to confirm the
> credit card, and to address the parcel. But if a roommate also orders from the
> same company, it is not important to realize they are in the same location.
> Address is a VALUE OBJECT. 
> 
> In software for the postal service, intended to organize delivery routes, the
> country could be formed into a hierarchy of regions, cities, postal zones, and
> blocks, terminating in individual addresses. These address objects would
> derive their zip code from their parent in the hierarchy, and if the postal
> service decided to reassign postal zones, all the addresses within would go
> along for the ride. Here, Address is an ENTITY.
>
> In software for an electric utility company, an address corresponds to a
> destination for the company's lines and service. If roommates each called to
> order electrical service, the company would need to realize it. Address is an
> ENTITY. Alternatively, the model could associate utility service with a
> "dwelling," an ENTITY with an attribute of address. Then Address would be a
> VALUE OBJECT.
>
> Tracking the identity of ENTITIES is essential, but attaching identity to
> other objects can hurt system performance, add analytical work, and muddle the
> model by making all objects look the same. 

[Domain-Driven Design]:
    https://www.goodreads.com/book/show/179133.Domain_Driven_Design
