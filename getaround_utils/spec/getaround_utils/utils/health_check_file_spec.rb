# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetaroundUtils::Utils::HealthCheckFile do
  subject(:health_file) { described_class.new(name) }

  let(:name) { 'dummy' }

  let(:root_path) { Pathname.new(ENV.fetch('CI_WORKING_DIR', '/')) }
  let(:expected_base_path) { root_path.join('tmp', name) }
  let(:expected_file_path) { expected_base_path.join(described_class::FILE_NAME) }

  shared_context 'with clean filesystem' do
    around do |example|
      FileUtils.rm_rf(expected_base_path)
      example.run
      FileUtils.rm_rf(expected_base_path)
    end
  end

  context 'with invalid name' do
    let(:name) { '' }

    it { expect { subject }.to raise_error(ArgumentError, /Expected name as String/) }
  end

  describe '#path' do
    subject { health_file.path }

    it { is_expected.to eq(expected_file_path) }

    context 'with Rails defined' do
      let(:root_path) { Pathname.new('/dummy') }

      before do
        stub_const('Rails', double(root: root_path))
      end

      it { is_expected.to eq(expected_file_path) }
    end
  end

  describe '#touch' do
    subject { health_file.touch }

    include_context 'with clean filesystem'

    it 'creates the file' do
      expect(File.exist?(expected_file_path)).to be false
      subject
      expect(File.exist?(expected_file_path)).to be true
    end
  end

  describe '#unlink' do
    subject { health_file.unlink }

    include_context 'with clean filesystem'

    before { health_file.touch }

    it 'removes the file' do
      expect(File.exist?(expected_file_path)).to be true
      subject
      expect(File.exist?(expected_file_path)).to be false
    end
  end

  describe '#exists?' do
    subject { health_file.exists? }

    include_context 'with clean filesystem'

    context 'when file is not yet created' do
      it { is_expected.to be false }
    end

    context 'when file was already created' do
      before { health_file.touch }

      it { is_expected.to be true }
    end
  end
end
