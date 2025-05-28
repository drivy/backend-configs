# frozen_string_literal: true

require 'spec_helper'
require 'getaround_utils/engines/health'

RSpec.describe GetaroundUtils::Engines::Health do
  describe '.release_version' do
    subject { described_class.release_version }

    let(:heroku_release_version)  { 'heroku-release-version' }
    let(:porter_stack_revision)   { 'porter-stack-revision' }
    let(:porter_pod_revision)     { 'porter-pod-revision' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HEROKU_RELEASE_VERSION').and_return(heroku_release_version)
      allow(ENV).to receive(:[]).with('PORTER_STACK_REVISION').and_return(porter_stack_revision)
      allow(ENV).to receive(:[]).with('PORTER_POD_REVISION').and_return(porter_pod_revision)
    end

    context 'with HEROKU_RELEASE_VERSION' do
      it { is_expected.to eq heroku_release_version }
    end

    context 'with PORTER_STACK_REVISION' do
      before do
        allow(ENV).to receive(:[]).with('HEROKU_RELEASE_VERSION').and_return(nil)
      end

      it { is_expected.to eq porter_stack_revision }
    end

    context 'with PORTER_POD_REVISION' do
      before do
        allow(ENV).to receive(:[]).with('HEROKU_RELEASE_VERSION').and_return(nil)
        allow(ENV).to receive(:[]).with('PORTER_STACK_REVISION').and_return(nil)
      end

      it { is_expected.to eq porter_pod_revision }
    end

    context 'with no environment variables defined' do
      before do
        allow(ENV).to receive(:[]).with('HEROKU_RELEASE_VERSION').and_return(nil)
        allow(ENV).to receive(:[]).with('PORTER_STACK_REVISION').and_return(nil)
        allow(ENV).to receive(:[]).with('PORTER_POD_REVISION').and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.commit_sha1' do
    subject { described_class.commit_sha1 }

    let(:heroku_slug_commit)  { 'heroku-slug-commit' }
    let(:commit_sha1)         { 'commit-sha1' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HEROKU_SLUG_COMMIT').and_return(heroku_slug_commit)
      allow(ENV).to receive(:[]).with('COMMIT_SHA1').and_return(commit_sha1)
    end

    context 'with HEROKU_SLUG_COMMIT' do
      it { is_expected.to eq heroku_slug_commit }
    end

    context 'with COMMIT_SHA1' do
      before do
        allow(ENV).to receive(:[]).with('HEROKU_SLUG_COMMIT').and_return(nil)
      end

      it { is_expected.to eq commit_sha1 }
    end

    context 'with no environment variables defined' do
      before do
        allow(ENV).to receive(:[]).with('HEROKU_SLUG_COMMIT').and_return(nil)
        allow(ENV).to receive(:[]).with('COMMIT_SHA1').and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.needs_migration?' do
    subject { described_class.needs_migration? }

    context 'when ActiveRecord is not defined' do
      it { is_expected.to be false }
    end

    context 'when ActiveRecord is defined' do
      before do
        stub_const('ActiveRecord', Class.new)
        stub_const('ActiveRecord::Base', double(connection: double(migration_context: double(needs_migration?: needs_migration))))
      end

      # rubocop:disable RSpec/NestedGroups
      context 'when migration is not required' do
        let(:needs_migration) { false }

        it { is_expected.to be false }
      end

      context 'when migration is required' do
        let(:needs_migration) { true }

        it { is_expected.to be true }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.engine' do
    subject(:response) { request.get(path) }

    let(:request) { Rack::MockRequest.new(described_class.engine) }

    let(:release_version) { nil }
    let(:commit_sha1)     { nil }
    let(:needs_migration) { false }

    before do
      allow(described_class).to receive_messages(release_version: release_version, commit_sha1: commit_sha1, needs_migration?: needs_migration)
    end

    shared_examples 'renders undefined' do
      it 'renders undefined', :aggregate_failures do
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'text/plain'
        expect(response.body).to eq described_class::UNDEFINED
      end
    end

    shared_examples 'renders expected body' do
      it 'renders expected body', :aggregate_failures do
        expect(response.status).to eq(200)
        expect(response.content_type).to eq 'text/plain'
        expect(response.body).to eq expected_body
      end
    end

    shared_examples 'only responds to GET' do |content_type:|
      %i[post put patch delete].each do |http_method|
        context "with #{http_method.to_s.upcase} request" do
          subject(:response) { request.send(http_method, path) }

          it 'returns method not allowed', :aggregate_failures do
            expect(response.status).to eq 405
            expect(response.content_type).to eq content_type
            expect(response.body).to eq ""
          end
        end
      end
    end

    context 'when requesting /health/release_version' do
      let(:path) { described_class::RELEASE_VERSION_PATH }

      include_examples 'only responds to GET', content_type: 'text/plain'
      include_examples 'renders undefined'

      # rubocop:disable RSpec/NestedGroups
      context 'when a release version is found' do
        let(:release_version) { 'hello' }

        include_examples 'renders expected body' do
          let(:expected_body) { release_version }
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when requesting /health/commit_sha1' do
      let(:path) { described_class::COMMIT_SHA1_PATH }

      include_examples 'only responds to GET', content_type: 'text/plain'
      include_examples 'renders undefined'

      # rubocop:disable RSpec/NestedGroups
      context 'when a release version is found' do
        let(:commit_sha1) { 'world' }

        include_examples 'renders expected body' do
          let(:expected_body) { commit_sha1 }
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when requesting /health/migration_status' do
      let(:path) { described_class::MIGRATION_STATUS_PATH }

      include_examples 'only responds to GET', content_type: 'application/json'

      it 'renders migration status', :aggregate_failures do
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/json'
        expect(JSON.parse(response.body)).to eq('needs_migration' => needs_migration)
      end
    end

    context 'when requesting unknown path' do
      let(:path) { '/unknown' }

      it 'returns not found', :aggregate_failures do
        expect(response.status).to eq 404
        expect(response.body).to eq "Not Found: #{path}"
      end
    end
  end
end
