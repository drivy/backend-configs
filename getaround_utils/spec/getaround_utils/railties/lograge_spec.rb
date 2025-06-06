# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/NestedGroups
describe GetaroundUtils::Railties::Lograge, type: :controller do
  patched_classes = [
    ActionController::Base,
    ActionController::API,
  ].freeze

  patched_classes.each do |klass|
    context "with #{klass.name}" do
      controller(klass) do
      end

      it 'prepends the default append_info_to_payload to klass' do
        expect(controller.respond_to?(:append_info_to_payload)).to be(true)
      end

      context 'with inheritance' do
        controller(klass) do
          def append_info_to_payload(payload)
            super
            payload[:value] = 1
          end
        end

        it 'allows for children to override values' do
          payload = { value: 0 }
          controller.append_info_to_payload(payload)
          expect(payload[:value]).to eq(1)
        end
      end

      context 'with requests' do
        controller(klass) do
          def dummy
            head :ok
          end

          def redir
            redirect_to('http://next.com')
          end
        end

        before do
          routes.draw {
            get '/dummy' => 'anonymous#dummy'
            get '/redir' => 'anonymous#redir'
          }
        end

        context 'with the newrelic trace infos' do
          it 'return no values when newrelic module is not loaded' do
            expect(Lograge.formatter).to receive(:call) do |payload|
              expect(payload["trace.id"]).to be_nil
              expect(payload["span.id"]).to be_nil
            end
            get(:dummy, params: { key: 'dummy' })
          end

          it 'return ids when newrelic module is loaded' do
            stub_const('NewRelic::Agent::Tracer', Class.new{})
            stub_const('NewRelic::Agent::Hostname', Class.new{})
            allow(NewRelic::Agent).to receive(:config)
              .and_return({ entity_guid: "azerty", app_name: ["my_app_name"] })
            allow(NewRelic::Agent::Tracer).to receive_messages(trace_id: "12345", span_id: "6789")
            allow(NewRelic::Agent::Hostname).to receive(:get)
              .and_return("my_hostname")

            expect(Lograge.formatter).to receive(:call) do |payload|
              expect(payload["trace.id"]).to eq("12345")
              expect(payload["span.id"]).to eq("6789")
              expect(payload["entity.guid"]).to eq("azerty")
              expect(payload["entity.name"]).to eq("my_app_name")
              expect(payload["entity.type"]).to eq("SERVICE")
              expect(payload["hostname"]).to eq("my_hostname")
            end
            get(:dummy, params: { key: 'dummy' })
          end
        end

        # Values set by lograge
        # method, path, format, controller, action, status, duration, view, (db)
        # location,
        it 'logs the default event payload infos' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:method]).to eq('GET')
            expect(payload[:http][:path]).to eq('/dummy')
            expect(payload[:http][:status]).to eq(200)
            expect(payload[:http][:duration]).to be_a(Float)

            expect(payload[:format]).to eq(:html)
            expect(payload[:controller]).to eq('AnonymousController')
            expect(payload[:action]).to eq('dummy')
            expect(payload[:view]).to be_a(Float)
            expect(payload[:origin]).to eq('lograge')
          end
          get(:dummy, params: { key: 'dummy' })
        end

        it 'logs the location when available' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:location]).to eq('http://next.com')
          end
          get(:redir)
        end

        # Value added in payload[:lograge]
        # host, params, user_agent, controller_action, rquest_id, session_id, host, remote_ip, referer, user_id

        it 'logs the extra event payload infos' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:host]).to eq('test.host')
            expect(payload[:http][:user_agent]).to eq('Rails Testing')
            expect(payload[:params]).to eq('key' => 'dummy')
            expect(payload[:session_id]).to match(/^[a-f0-9]{32}$/)
          end
          get(:dummy, params: { key: 'dummy' })
        end

        it 'logs the host when available' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:host]).to eq('dummy.com')
          end
          request.headers['HOST'] = 'dummy.com'
          get(:dummy)
        end

        it 'logs the remote ip when available' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:remote_ip]).to eq('4.4.4.4')
          end
          request.headers['REMOTE_ADDR'] = '4.4.4.4'
          get(:dummy)
        end

        it 'logs the referer when available' do
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:http][:referer]).to eq('previous.com')
          end
          request.headers['HTTP_REFERER'] = 'previous.com'
          get(:dummy)
        end

        it 'logs the current_user id if defined' do
          user = double
          allow(user).to receive(:id).and_return(42)
          allow(controller).to receive(:current_user).and_return(user)
          expect(Lograge.formatter).to receive(:call) do |payload|
            expect(payload[:user_id]).to eq(42)
          end
          get(:dummy)
        end
      end
    end
  end
end

# rubocop:enable RSpec/NestedGroups
