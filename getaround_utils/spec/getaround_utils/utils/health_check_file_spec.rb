# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe GetaroundUtils::Utils::HealthCheckFile do
  subject(:health_file) { described_class.new(name) }

  let(:name) { 'dummy' }

  let(:root_path) { Pathname.new('/') }
  let(:expected_base_path) { root_path.join('tmp', name) }
  let(:expected_file_path) { expected_base_path.join(described_class::FILE_NAME) }

  # Other specs boot a Rails application: hide it, so that each context sets the root it expects.
  before { hide_const('Rails') }

  shared_context 'with Rails rooted in a temporary directory' do
    let(:root_path) { Pathname.new(Dir.mktmpdir) }

    before { stub_const('Rails', double(root: root_path)) }

    after { FileUtils.rm_rf(root_path) }
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

  describe '#create' do
    subject { health_file.create }

    include_context 'with Rails rooted in a temporary directory'

    it 'creates the file' do
      expect(File.exist?(expected_file_path)).to be false
      subject
      expect(File.exist?(expected_file_path)).to be true
    end
  end

  describe '#delete' do
    subject { health_file.delete }

    include_context 'with Rails rooted in a temporary directory'

    before { health_file.create }

    it 'removes the file' do
      expect(File.exist?(expected_file_path)).to be true
      subject
      expect(File.exist?(expected_file_path)).to be false
    end
  end

  describe '#refresh' do
    subject { health_file.refresh }

    include_context 'with Rails rooted in a temporary directory'

    context 'when file is not yet created' do
      it { is_expected.to be false }

      it 'does not create the file' do
        subject
        expect(File.exist?(expected_file_path)).to be false
      end
    end

    context 'when file was already created' do
      before do
        health_file.create
        File.utime(Time.now.utc - 120, Time.now.utc - 120, expected_file_path)
      end

      it { is_expected.to be true }

      it 'refreshes the modification time' do
        expect { subject }.to change { File.mtime(expected_file_path) }.to be_within(5).of(Time.now.utc)
      end
    end
  end

  describe '#exists?' do
    subject { health_file.exists? }

    include_context 'with Rails rooted in a temporary directory'

    context 'when file is not yet created' do
      it { is_expected.to be false }
    end

    context 'when file was already created' do
      before { health_file.create }

      it { is_expected.to be true }
    end
  end
end
