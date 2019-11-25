require "spec_helper"

describe GetaroundUtils::Utils::DeepKeyValue do
  let(:subject) { described_class }

  describe '.serialize' do
    context 'with numbers' do
      it 'serializes a number correctly' do
        expect(subject.serialize(42)).to eq('42')
      end

      it 'serializes a nested number correctly' do
        expect(subject.serialize(value: 42)).to eq('value=42')
      end
    end

    context 'with strings' do
      it 'serializes a string correctly' do
        expect(subject.serialize(' \ " ')).to eq('" \\\\ \" "')
      end

      it 'serializes a nested string correctly' do
        expect(subject.serialize(value: ' \ " ')).to eq('value=" \\\\ \" "')
      end

      it 'serializes an inspect-type string correctly' do
        expect(subject.serialize('" something "')).to eq('" something "')
      end

      it 'serializes a nested inspect-type string correctly' do
        expect(subject.serialize(value: '" something "')).to eq('value=" something "')
      end

      it 'truncates a value that is too long' do
        expect(subject.serialize(value: 'a' * 1000)).to eq(%{value="#{'a' * 512} ..."})
      end
    end

    context 'with arrays' do
      it 'serializes an array correctly' do
        expect(subject.serialize(['a', 'b', 'c'])).to eq('0="a" 1="b" 2="c"')
      end

      it 'serializes a nested array correctly' do
        expect(subject.serialize(value: ['a', 'b', 'c'])).to eq('value.0="a" value.1="b" value.2="c"')
      end

      it 'truncates an array that is too deep' do
        expect(subject.serialize([[[[[['value']]]]]])).to eq('0.0.0.0.0.0="..."')
      end
    end

    context 'with hashes' do
      it 'serializes a flat hash with a simple string correctly' do
        expect(subject.serialize(key: 'value')).to eq('key="value"')
      end

      it 'serializes a flat hash with complex strings correctly' do
        expect(subject.serialize(key: 'This \ " is &\' weird one   ')).to eq('key="This \\\\ \\" is &\' weird one   "')
      end

      it 'serializes a flat hash with simple values correctly' do
        expect(subject.serialize(key: 42.0)).to eq('key=42.0')
      end

      it 'serializes a flat hash with complex values correctly' do
        expect(subject.serialize(key: Tempfile.new)).to match(/^key="#<File:.+>"$/)
      end

      it 'serializes a flat hash with simple array correctly' do
        expect(subject.serialize(key: ['a', 'b'])).to eq('key.0="a" key.1="b"')
      end

      it 'serializes a flat hash with complex array correctly' do
        expect(subject.serialize(key: ['a', 42, 55.123])).to eq('key.0="a" key.1=42 key.2=55.123')
      end

      it 'serializes a deep hash with a simple payload correctly' do
        expect(subject.serialize(key1: { key2: { key3: 'value' } })).to eq('key1.key2.key3="value"')
      end

      it 'serializes a deep hash with a complex payload correctly' do
        expect(subject.serialize(
          a1: { b1: { c2: 'value' }, b2: [1, 42.0] }, a2: { b1: 'fifty' }, a3: [{ b3: 'c4' }],
        )).to eq(
          'a1.b1.c2="value" a1.b2.0=1 a1.b2.1=42.0 a2.b1="fifty" a3.0.b3="c4"'
        )
      end

      it 'truncates a hash that is too deep' do
        expect(subject.serialize(a: { b: { c: { d: { e: { f: 'value' } } } } })).to eq('a.b.c.d.e.f="..."')
      end
    end

    context 'with objects' do
      it 'serializes an object correctly' do
        expect(subject.serialize(value: Tempfile.new)).to match(/^value="#<File.+>"$/)
      end
    end
  end
end
