# This file contains the configuration for Credo and you are probably reading
# this after creating it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/",
          "priv/repo/migrations/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      #
      # Load and configure plugins here:
      #
      plugins: [],
      #
      # If you create your own checks, you must specify the source files for
      # them here, so they can be loaded by Credo before running the analysis.
      #
      requires: ["credo/checks/*.ex"],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      strict: true,
      #
      # To modify the timeout for parsing files, change this value:
      #
      parse_timeout: 5000,
      #
      # If you want to use uncolored output by default, you can change `color`
      # to `false` below:
      #
      color: true,
      #
      # You can customize the parameters of any check by adding a second element
      # to the tuple.
      #
      # To disable a check put `false` as second element:
      #
      #     {Credo.Check.Design.DuplicatedCode, false}
      #
      checks: %{
        enabled: [
          #
          ## Consistency Checks
          #
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},
          {Credo.Check.Consistency.MultiAliasImportRequireUse, []},

          #
          ## Design Checks
          #
          {Credo.Check.Design.AliasUsage,
           [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 2]},
          # {Credo.Check.Design.TagFIXME, []}
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Design.SkipTestWithoutComment, []},
          {Credo.Check.Design.DuplicatedCode, []},

          #
          ## Readability Checks
          #
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.BlockPipe, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.ImplTrue, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.MultiAlias, []},
          {Credo.Check.Readability.OneArityFunctionInPipe, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SeparateAliasRequire, []},
          {Credo.Check.Readability.SingleFunctionToBlockPipe, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          # Migrations only implement `Ecto.Migration` callbacks, which need no
          # `@spec`.
          {Credo.Check.Readability.Specs, files: %{excluded: ["priv/repo/migrations/"]}},
          {Credo.Check.Readability.StrictModuleLayout, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.WithCustomTaggedTuple, []},
          {Credo.Check.Readability.WithSingleClause, []},

          #
          ## Refactoring Opportunities
          #
          {Credo.Check.Refactor.ABCSize, []},
          {Credo.Check.Refactor.AppendSingleItem, []},
          {Credo.Check.Refactor.Apply, []},
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity, []},
          {Credo.Check.Refactor.DoubleBooleanNegation, []},
          {Credo.Check.Refactor.FilterCount, []},
          {Credo.Check.Refactor.FilterFilter, []},
          {Credo.Check.Refactor.FilterReject, []},
          {Credo.Check.Refactor.FunctionArity, []},
          {Credo.Check.Refactor.IoPuts, []},
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MapJoin, []},
          {Credo.Check.Refactor.MapMap, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.ModuleDependencies, [max_deps: 15]},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.NegatedIsNil, []},
          {Credo.Check.Refactor.Nesting, []},
          {Credo.Check.Refactor.PassAsyncInTestCases, []},
          {Credo.Check.Refactor.PipeChainStart, []},
          {Credo.Check.Refactor.RedundantWithClauseResult, []},
          {Credo.Check.Refactor.RejectFilter, []},
          {Credo.Check.Refactor.RejectReject, []},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.UtcNowTruncate, []},
          {Credo.Check.Refactor.WithClauses, []},

          #
          ## Warnings
          #
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.Dbg, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.LeakyEnvironment, []},
          {Credo.Check.Warning.MapGetUnsafePass, []},
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.SpecWithStruct, []},
          {Credo.Check.Warning.UnsafeExec, []},
          {Credo.Check.Warning.UnsafeToAtom, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},
          {Credo.Check.Warning.WrongTestFileExtension, []},

          #
          ## Jump.CredoChecks (https://github.com/Jump-App/credo_checks)
          ##
          ## Catches weak or vacuous tests and LiveView anti-patterns. The
          ## migration checks are under "Migration safety" below. Flick skips
          ## UseObanProWorker because it has no Oban. UndeclaredExternalResource
          ## misfires on `File.posix()` typespecs, but Flick has none.
          #
          {Jump.CredoChecks.AssertElementSelectorCanNeverFail, []},
          {Jump.CredoChecks.AssertReceiveTimeout,
           min_assert_receive_timeout: 1_000, max_refute_receive_timeout: 100},
          {Jump.CredoChecks.AvoidFunctionLevelElse, []},
          {Jump.CredoChecks.AvoidLoggerConfigureInTest, []},
          {Jump.CredoChecks.AvoidSocketAssignsInTest, []},
          {Jump.CredoChecks.ConditionalAssertion, []},
          {Jump.CredoChecks.DoctestIExExamples,
           derive_test_path: fn filename ->
             filename
             |> String.replace_leading("lib/", "test/")
             |> String.replace_trailing(".ex", "_test.exs")
           end},
          {Jump.CredoChecks.ForbiddenFunction,
           functions: [
             {:erlang, :binary_to_term,
              "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}
           ]},
          {Jump.CredoChecks.LiveViewFormCanBeRehydrated, []},
          {Jump.CredoChecks.LiveViewPubSubRequiresConnected, []},
          {Jump.CredoChecks.NoManualContentDisposition, []},
          {Jump.CredoChecks.SafeBinaryToTerm, []},
          {Jump.CredoChecks.TestHasNoAssertions, []},
          {Jump.CredoChecks.TooManyAssertions, max_assertions: 20},
          {Jump.CredoChecks.TopLevelAliasImportRequire, []},
          {Jump.CredoChecks.UndeclaredExternalResource, []},
          {Jump.CredoChecks.UnusedLiveViewAssign, []},
          {Jump.CredoChecks.VacuousTest, []},
          {Jump.CredoChecks.WeakAssertion, []},

          #
          ## Migration safety
          ##
          ## Fails an unsafe migration, or one that is hard to roll back, before
          ## it merges. The checks skip every migration up to the backfill,
          ## 20260927221423, so applied migrations are never edited. Jump's
          ## checks take the cutoff as `start_after` below. ExcellentMigrations
          ## reads it from `config/config.exs`.
          ##
          ## Known gaps in ExcellentMigrations:
          ##
          ##   * It detects data writes only through `Repo.*` calls, so it misses
          ##     a backfill written with `repo().query!`.
          ##   * It flags an index or a foreign key created together with a new
          ##     table. Mark those with a `safety-assured` comment.
          #
          {ExcellentMigrations.CredoCheck.MigrationsSafety, []},
          {Jump.CredoChecks.PreferChangeOverUpDownMigrations, start_after: "20260927221423"},
          {Jump.CredoChecks.PreferTextColumns, start_after: "20260927221423"},

          #
          ## OeditusCredo (https://github.com/Oeditus/oeditus_credo)
          ##
          ## Catches concurrency and exception-handling mistakes that compile
          ## cleanly. A check runs only when it is listed here. Flick skips
          ## PreferDotAccessForStructs because it misfires on keyword lists and
          ## maps. The trial in #225 found the rest to be noise here.
          #
          {OeditusCredo.Check.Warning.UnmanagedTask, []},
          {OeditusCredo.Check.Warning.SyncOverAsync, []},
          {OeditusCredo.Check.Warning.MissingHandleAsync, []},
          {OeditusCredo.Check.Warning.BlockingInPlug, []},
          {OeditusCredo.Check.Warning.SwallowingException, []},
          {OeditusCredo.Check.Refactoring.PreferFunctionCapture, []},

          #
          ## Custom Checks
          #
          {Flick.Credo.Check.CaseOnBoolean, []},
          {Flick.Credo.Check.RawInHeex, []}
        ],
        disabled: [
          {Credo.Check.Consistency.UnusedVariableNames, []},
          {Credo.Check.Readability.AliasAs, []},
          {Credo.Check.Readability.NestedFunctionCalls, []},
          {Credo.Check.Readability.OnePipePerLine, []},
          {Credo.Check.Readability.SinglePipe, []},
          {Credo.Check.Refactor.VariableRebinding, []},
          {Credo.Check.Warning.LazyLogging, []}

          # Custom checks can be created using `mix credo.gen.check`.
        ]
      }
    }
  ]
}
