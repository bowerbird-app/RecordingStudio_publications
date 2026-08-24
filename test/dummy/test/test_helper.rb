# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module AccessGrantTestHelper
  def bootstrap_owner_access!(actor, recording)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    return result.value if result.success?

    manager = access_manager_for(actor)
    if manager && already_bootstrapped?(result)
      result = RecordingStudioAccessible.grant_access(
        recording: recording,
        actor: actor,
        role: :admin,
        manager_actor: manager
      )
    end

    raise result.error if result.failure?

    result.value
  end

  def grant_admin_access_for_test!(recording:, actor:, role: :admin)
    return bootstrap_owner_access!(actor, recording) if role.to_s == "admin"

    manager = access_manager_for(actor) || actor
    original = RecordingStudioAccessible.configuration.access_management_authorizer
    RecordingStudioAccessible.configuration.access_management_authorizer = ->(**) { true }
    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: role,
      manager_actor: manager
    )
    raise result.error if result.failure?

    result.value
  ensure
    RecordingStudioAccessible.configuration.access_management_authorizer = original
  end

  def already_bootstrapped?(result)
    result.error.to_s.include?(
      RecordingStudioAccessible::Services::BootstrapOwnerAccess::ALREADY_BOOTSTRAPPED_MESSAGE
    )
  end

  def access_manager_for(actor)
    manager = User.find_by(email: "admin@admin.com")
    return manager if manager && manager.id != actor.id

    User.where.not(id: actor.id).first
  end

  def admin_root_recording_for_test
    admin_root = AdminRoot.find_or_create_by!(name: "Admin")
    RecordingStudio.root_recording_for(admin_root)
  end
end

class ActionDispatch::IntegrationTest
  include AccessGrantTestHelper
end

class ActiveSupport::TestCase
  include AccessGrantTestHelper
end
