require "spec_helper"

describe GetaroundUtils::LogFormatters::DeepKeyValue do
  it 'serializes a flat hash with a simple string correctly' do
    expect(subject.call(key: 'value')).to eq('key="value"')
  end

  it 'serializes a flat hash with complex strings correctly' do
    expect(subject.call(key: 'This \ " is &\' weird one   ')).to eq('key="This \\\\ \\" is &\' weird one   "')
  end

  it 'serializes a flat hash with simple values correctly' do
    expect(subject.call(key: 42.0)).to eq('key=42.0')
  end

  it 'serializes a flat hash with complex values correctly' do
    expect(subject.call(key: Tempfile.new)).to match(/^key="#<File:.+>"$/)
  end

  it 'serializes a flat hash with simple array correctly' do
    expect(subject.call(key: ['a', 'b'])).to eq('key.0="a" key.1="b"')
  end

  it 'serializes a flat hash with complex array correctly' do
    expect(subject.call(key: ['a', 42, 55.123])).to eq('key.0="a" key.1=42 key.2=55.123')
  end

  it 'serializes a deep hash with a simple payload correctly' do
    expect(subject.call(key1: { key2: { key3: 'value' } })).to eq('key1.key2.key3="value"')
  end

  it 'serializes a deep hash with a complex payload correctly' do
    expect(subject.call(
      a1: { b1: { c2: 'value' }, b2: [1, 42.0] }, a2: { b1: 'fifty' }, a3: [{ b3: 'c4' }],
    )).to eq(
      'a1.b1.c2="value" a1.b2.0=1 a1.b2.1=42.0 a2.b1="fifty" a3.0.b3="c4"'
    )
  end

  it 'serializes a number correctly' do
    expect(subject.call(42)).to eq('42')
  end

  it 'serializes a nested number correctly' do
    expect(subject.call(value: 42)).to eq('value=42')
  end

  it 'serializes a string correctly' do
    expect(subject.call(' \ " ')).to eq('" \\\\ \" "')
  end

  it 'serializes a nested string correctly' do
    expect(subject.call(value: ' \ " ')).to eq('value=" \\\\ \" "')
  end

  it 'serializes an inspect-type string correctly' do
    expect(subject.call('" something "')).to eq('" something "')
  end

  it 'serializes a nested inspect-type string correctly' do
    expect(subject.call(value: '" something "')).to eq('value=" something "')
  end

  it 'serializes an object correctly' do
    expect(subject.call(value: Tempfile.new)).to match(/^value="#<File.+>"$/)
  end
end
