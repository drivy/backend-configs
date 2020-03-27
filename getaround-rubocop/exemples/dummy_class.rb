# frozen_string_literal: true

module DummyModule
  class DummyClass
    def empty_method(*args); end

    def dummy_caller_inline
      empty_method({ key: value }, [nil, nil])
    end

    def dummy_caller_spread
      empty_method({
        key1: 'value1',
        key2: 'value2',
      }, [
        nil,
        nil,
      ])
    end

    def dummy_caller_multiline
      empty_method({ key1: 'value1', key2: 'value2' },
        [nil, nil])
    end
  end
end
