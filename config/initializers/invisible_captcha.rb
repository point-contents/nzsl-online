InvisibleCaptcha.setup do |config|
  config.visual_honeypots = Rails.env.test?
  # make them visible during tests

  config.timestamp_enabled = !Rails.env.test?
  # set timestamp false if rails env is in test, this means
  # that it will accept post requests that take less than
  # 4 seconds, in a testing environment
end

ActiveSupport::Notifications.subscribe('invisible_captcha.spam_detected') do |*_args, data|
  Rails.logger.info(data[:message]) # Log spam attemps
end
