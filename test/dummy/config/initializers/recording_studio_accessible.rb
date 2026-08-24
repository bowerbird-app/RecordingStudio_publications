# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]
  config.avatar_resolver = lambda do |access_holder|
    next unless access_holder.respond_to?(:email)

    label = access_holder.email.to_s.split("@").first.to_s.titleize.presence || access_holder.email
    { name: label }
  end
end
