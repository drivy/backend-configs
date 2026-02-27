# frozen_string_literal: true

require 'spec_helper'
require 'i18n'
require 'getaround_utils/i18n_backend/flat_keys'

describe GetaroundUtils::I18nBackend::FlatKeys do
  subject{
    klass = Class.new(I18n.backend.class)
    klass.include(described_class)
    klass.new
  }

  describe '#expand_dot_keys' do
    it 'expands keys containing a dot' do
      data = {
        'this.should.expand': 'value',
        'this.should.also_expand': 'value',
        'this': { should: { stay: 'value' } },
      }

      expect(subject.send(:expand_dot_keys, data)).to eq(
        { this: { should: { also_expand: 'value', expand: 'value', stay: 'value' } } },
      )
    end

    it 'preserves the values type' do
      data = {
        'an.array': [1, 'string', true],
        'a.string': 'string',
        'a.boolean': true,
        'a.number': 42
      }
      expect(subject.send(:expand_dot_keys, data)).to eq(
        { a: { boolean: true, number: 42, string: "string" }, an: { array: [1, "string", true] } },
      )
    end
  end

  describe 'when used a a backend' do
    around do |example|
      original_backend = I18n.backend
      I18n.backend = subject
      example.run
    ensure
      I18n.backend = original_backend
    end

    it 'stores its translation and resolves them' do
      I18n.backend.store_translations(:en, {
        'a.flat.key': 'en_value',
        'a': { nested: { key: 'en_value' } }
      })

      expect(I18n.translate('a.flat.key', locale: :en))
        .to eq('en_value')
      expect(I18n.translate('a.nested.key', locale: :en))
        .to eq('en_value')
    end
  end
end
