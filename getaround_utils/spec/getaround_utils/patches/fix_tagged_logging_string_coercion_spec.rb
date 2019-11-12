require 'spec_helper'

describe GetaroundUtils::Patches::FixTaggedLoggingStringCoercion do
  before do
    stub_formatter = Module.new { include ActiveSupport::TaggedLogging::Formatter }
    stub_formatter.prepend(GetaroundUtils::Patches::FixTaggedLoggingStringCoercion::TaggedLoggingFormatter)
    stub_const('ActiveSupport::TaggedLogging::Formatter', stub_formatter)
  end

  let(:output) { Tempfile.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(output)) }

  it 'does nothing in the absence of tags' do
    expect(output).to receive(:write)
      .with("string01\n")
    logger.error('string01')
  end

  it 'insert tags at the end of strings' do
    expect(output).to receive(:write).with("string02 [tag01] [tag02]\n")
    logger.tagged(['tag01', 'tag02']) { |logger| logger.error('string02') }
  end

  it 'delegates formating to the logger formatter' do
    base_logger = Logger.new(output)
    base_logger.formatter = ->(_a, _b, _c, d) { "#{d.class}|\n" }
    logger = ActiveSupport::TaggedLogging.new(base_logger)

    expect(output).to receive(:write).with("Hash| [tag01] [tag02]\n")
    logger.tagged(['tag01', 'tag02']) { logger.error(key: :value) }
  end
end
