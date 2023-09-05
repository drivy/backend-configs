# frozen_string_literal: true

require 'rails/railtie'
require 'lograge'

module GetaroundUtils; end

module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::Lograge < Rails::Railtie
  module LogrageActionController
    def append_info_to_payload(payload)
      super
      payload[:lograge] = {}
      payload[:lograge][:host] = request.host
      payload[:lograge][:params] = request.filtered_parameters.except(:action, :controller)
      payload[:lograge][:remote_ip] = request.remote_ip
      payload[:lograge][:user_agent] = request.user_agent
      payload[:lograge][:referer] = request.referer
      payload[:lograge][:session_id] = session.is_a?(Hash) ? session[:id] : session.id.to_s if defined?(session)
      payload[:lograge][:user_id] = current_user&.id if defined?(current_user)
      payload[:lograge][:origin] = 'lograge'

      if defined?(NewRelic::Agent::Tracer)
        if span_id = NewRelic::Agent::Tracer.span_id
          payload[:lograge]['span.id'] = span_id
        end
        if trace_id = NewRelic::Agent::Tracer.trace_id
          payload[:lograge]['trace.id'] = trace_id
        end
        payload[:lograge]['entity.type'] = 'SERVICE'
        payload[:lograge]['entity.guid'] = NewRelic::Agent.config[:entity_guid]
        payload[:lograge]['entity.name'] = NewRelic::Agent.config[:app_name]&.first
      end

      if defined?(NewRelic::Agent::Hostname)
        payload[:lograge]['hostname'] = NewRelic::Agent::Hostname.get
      end

      nil
    end
  end

  initializer 'getaround_utils.action_controller' do
    ActionController::Base.prepend LogrageActionController
    ActionController::API.prepend LogrageActionController
  end

  HTTP_PARAMS = [:method, :path, :host, :remote_ip,
                 :status, :duration, :location,
                 :user_agent, :referer].freeze

  config.lograge.enabled = true
  config.lograge.custom_options = ->(event) {
    event.payload[:lograge]
  }
  config.lograge.before_format = ->(data, _) {
    data.except(*HTTP_PARAMS).deep_merge(http: data.slice(*HTTP_PARAMS))
  }
end
