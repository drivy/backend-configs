require 'rails/railtie'
require 'getaround_utils/log_formatters/deep_key_value'
require 'lograge'

module GetaroundUtils; end
module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::Lograge < Rails::Railtie
  module LogrageActionController
    def append_info_to_payload(payload)
      super
      payload[:lograge] ||= {}
      payload[:lograge][:host] = request.host
      payload[:lograge][:params] = request.filtered_parameters.except(:action, :controller)
      payload[:lograge][:remote_ip] = request.remote_ip
      payload[:lograge][:request_id] = request.uuid
      payload[:lograge][:user_agent] = request.user_agent
      payload[:lograge][:referer] = request.referer
      payload[:lograge][:controller_action] = "#{params[:controller]}##{params[:action]}" if params
      payload[:lograge][:session_id] = session&.id
      payload[:lograge][:user_id] = current_user&.id if defined?(current_user)
    end
  end

  initializer 'getaround_utils.action_controller' do
    ActionController::Base.prepend LogrageActionController
  end

  config.lograge.enabled = true
  config.lograge.formatter = GetaroundUtils::LogFormatters::DeepKeyValue.new
  config.lograge.custom_options = lambda do |event|
    event.payload[:lograge].compact
  end
end
