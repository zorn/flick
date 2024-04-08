# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Flick.Repo.insert!(%Flick.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Flick.Ballots
alias Flick.Ballots.Question

{:ok, _} =
  Ballots.create_ballot("What is your favorite programming language?", [
    %Question{title: "C"},
    %Question{title: "C#"},
    %Question{title: "C++"},
    %Question{title: "Elixir"},
    %Question{title: "Java"},
    %Question{title: "JavaScript"},
    %Question{title: "Python"},
    %Question{title: "Ruby"},
    %Question{title: "Swift"}
  ])

{:ok, _} =
  Ballots.create_ballot("What is your preferred development environment?", [
    %Question{title: "Windows"},
    %Question{title: "MacOS"},
    %Question{title: "Linux"},
    %Question{title: "Other"}
  ])

{:ok, _} =
  Ballots.create_ballot("What is your favorite programming paradigm?", [
    %Question{title: "Imperative"},
    %Question{title: "Declarative"},
    %Question{title: "Functional"},
    %Question{title: "Object-Oriented"},
    %Question{title: "Procedural"},
    %Question{title: "Event-Driven"},
    %Question{title: "Aspect-Oriented"},
    %Question{title: "Logic"},
    %Question{title: "Constraint"}
  ])

{:ok, _} =
  Ballots.create_ballot("What is your go-to framework or library?", [
    %Question{title: "React"},
    %Question{title: "Angular"},
    %Question{title: "Vue.js"},
    %Question{title: "Ember.js"},
    %Question{title: "Backbone.js"},
    %Question{title: "jQuery"},
    %Question{title: "Bootstrap"},
    %Question{title: "Foundation"},
    %Question{title: "Materialize"}
  ])

{:ok, _} =
  Ballots.create_ballot("What is the most challenging programming problem you've solved?", [
    %Question{title: "Memory management"},
    %Question{title: "Concurrency"},
    %Question{title: "Performance optimization"},
    %Question{title: "Security vulnerabilities"},
    %Question{title: "Algorithm design"},
    %Question{title: "Data structures"},
    %Question{title: "Distributed systems"},
    %Question{title: "Machine learning"},
    %Question{title: "Natural language processing"}
  ])

{:ok, _} =
  Ballots.create_ballot("What programming language or technology would you like to learn next?", [
    %Question{title: "Rust"},
    %Question{title: "Go"},
    %Question{title: "Kotlin"},
    %Question{title: "Scala"},
    %Question{title: "Haskell"},
    %Question{title: "Clojure"},
    %Question{title: "TypeScript"},
    %Question{title: "Dart"},
    %Question{title: "WebAssembly"}
  ])
