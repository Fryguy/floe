# Disable rubocops against the `match` method, since this is a Parslet specific
#   match method and not the typical `Object#match`.
# rubocop:disable Performance/RegexpMatch, Performance/RedundantMatch

require "parslet"
require "securerandom"

module Floe
  class Workflow
    class IntrinsicFunction
      class Transformer < Parslet::Transform
        def self.resolve_args(args)
          if args.nil?
            # 0 args
            []
          elsif args.kind_of?(Array)
            # >1 arg
            args.map { |a| a[:arg] }
          else
            # 1 arg
            [args[:arg]]
          end
        end

        rule(:null_literal  => simple(:v)) { nil }
        rule(:true_literal  => simple(:v)) { true }
        rule(:false_literal => simple(:v)) { false }

        rule(:string   => simple(:v)) { v.to_s }
        rule(:number   => simple(:v)) { v.match(/[eE.]/) ? Float(v) : Integer(v) }
        rule(:jsonpath => simple(:v)) { Floe::Workflow::Path.value(v.to_s, context, input) }

        rule(:states_array => {:args => subtree(:args)}) do
          Transformer.resolve_args(args)
        end

        rule(:states_array_partition => {:args => subtree(:args)}) do
          args = Transformer.resolve_args(args())
          raise ArgumentError, "wrong number of arguments to States.ArrayPartition (given #{args.size}, expected 2)" unless args.size == 2

          array, chunk = *args
          raise ArgumentError, "wrong type for first argument to States.ArrayPartition (given #{array.class}, expected Array)" unless array.kind_of?(Array)
          raise ArgumentError, "wrong type for second argument to States.ArrayPartition (given #{chunk.class}, expected Integer)" unless chunk.kind_of?(Integer)
          raise ArgumentError, "invalid value for second argument to States.ArrayPartition (given #{chunk}, expected a positive Integer)" unless chunk.positive?

          array.each_slice(chunk).to_a
        end

        rule(:states_array_contains => {:args => subtree(:args)}) do
          args = Transformer.resolve_args(args())
          raise ArgumentError, "wrong number of arguments to States.ArrayContains (given #{args.size}, expected 2)" unless args.size == 2

          array, target = *args
          raise ArgumentError, "wrong type for first argument to States.ArrayContains (given #{array.class}, expected Array)" unless array.kind_of?(Array)

          array.include?(target)
        end

        rule(:states_array_range => {:args => subtree(:args)}) do
          args = Transformer.resolve_args(args())
          raise ArgumentError, "wrong number of arguments to States.ArrayRange (given #{args.size}, expected 3)" unless args.size == 3

          range_begin, range_end, increment = *args
          raise ArgumentError, "wrong type for first argument to States.ArrayRange (given #{range_begin.class}, expected Integer)" unless range_begin.kind_of?(Integer)
          raise ArgumentError, "wrong type for second argument to States.ArrayRange (given #{range_end.class}, expected Integer)" unless range_end.kind_of?(Integer)
          raise ArgumentError, "wrong type for third argument to States.ArrayRange (given #{increment.class}, expected Integer)" unless increment.kind_of?(Integer)
          raise ArgumentError, "invalid value for third argument to States.ArrayRange (given #{increment}, expected a non-zero Integer)" if increment.zero?

          (range_begin..range_end).step(increment).to_a
        end

        rule(:states_uuid => {:args => subtree(:args)}) do
          args = Transformer.resolve_args(args())
          raise ArgumentError, "wrong number of arguments to States.UUID (given #{args.size}, expected 0)" unless args.empty?

          SecureRandom.uuid
        end
      end
    end
  end
end

# rubocop:enable Performance/RegexpMatch, Performance/RedundantMatch
