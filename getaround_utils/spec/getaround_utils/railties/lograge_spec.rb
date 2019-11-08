require 'rails_helper'

describe GetaroundUtils::Railties::Lograge, type: :controller do
  controller(ActionController::Base) do
  end

  it 'prepends the default append_info_to_payload to ActionController::Base' do
    expect(controller.respond_to?(:append_info_to_payload)).to be(true)
  end

  context 'with inheritance' do
    controller(ActionController::Base) do
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
    controller(ActionController::Base) do
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

    # Values set by lograge
    # method, path, format, controller, action, status, duration, view, (db)
    # location,
    it 'logs the default event payload infos' do
      expect(Rails.logger).to receive(:info) do |payload|
        expect(payload).to match(/method="GET"/)
        expect(payload).to match(%r{path="/dummy"})
        expect(payload).to match(/format="html"/)
        expect(payload).to match(/controller="AnonymousController/)
        expect(payload).to match(/action="dummy"/)

        expect(payload).to match(/status=200/)
        expect(payload).to match(/duration=[.0-9]+/)
        expect(payload).to match(/view=0/)
        # expect(payload).to match(/db=0/)
      end
      get(:dummy, params: { key: 'dummy' })
    end

    it 'logs the location when available' do
      expect(Rails.logger).to receive(:info).with(%r{location="http://next.com"})
      get(:redir)
    end

    # Value added in payload[:lograge]
    # host, params, user_agent, controller_action, rquest_id, session_id, host, remote_ip, referer, user_id

    it 'logs the extra event payload infos' do
      expect(Rails.logger).to receive(:info) do |payload|
        expect(payload).to match(/host="test.host"/)
        expect(payload).to match(/params\.key="dummy"/)
        expect(payload).not_to match(/params\.(action|controller)/)
        expect(payload).to match(/user_agent="Rails Testing"/)
        expect(payload).to match(/controller_action="anonymous#dummy"/)
        expect(payload).to match(/session_id="[a-f0-9]{32}"/)
      end
      get(:dummy, params: { key: 'dummy' })
    end

    it 'logs the host when available' do
      expect(Rails.logger).to receive(:info).with(/host="dummy.com"/)
      request.headers['HOST'] = 'dummy.com'
      get(:dummy)
    end

    it 'logs the remote ip when available' do
      expect(Rails.logger).to receive(:info).with(/remote_ip="4.4.4.4"/)
      request.headers['REMOTE_ADDR'] = '4.4.4.4'
      get(:dummy)
    end

    it 'logs the referer when available' do
      expect(Rails.logger).to receive(:info).with(/referer="previous.com"/)
      request.headers['HTTP_REFERER'] = 'previous.com'
      get(:dummy)
    end

    it 'logs the current_user id if defined' do
      user = double
      allow(user).to receive(:id).and_return(42)
      allow(controller).to receive(:current_user).and_return(user)
      expect(Rails.logger).to receive(:info).with(/user_id=42/)
      get(:dummy)
    end

    it 'logs the complete event payload infos' do
      expect(Rails.logger).to receive(:info).with(
        %r{^method="GET" path="/dummy" format="html" controller="AnonymousController" action="dummy" status=200 duration=[.0-9]+ view=[.0-9]+ host="test.host" remote_ip="0.0.0.0" user_agent="Rails Testing" controller_action="anonymous#dummy" session_id="[a-f0-9]+"$}
      )
      get(:dummy)
    end
  end
end
