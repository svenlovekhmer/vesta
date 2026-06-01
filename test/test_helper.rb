ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    teardown do
      status = passed? ? "\e[32m✓ PASS\e[0m" : "\e[31m✗ FAIL\e[0m"
      puts "  #{status}  #{name}"
    end

    # Shared helper to build a full mission with its dependencies
    def create_mission_for(user, title: "Mission test", status_title: "En cours", created_at: nil)
      status   = MissionStatus.find_or_create_by!(title: status_title)
      template = StepTemplate.create!(user: user, name: "Tpl #{SecureRandom.hex(4)}", description: "D")
      client   = Client.create!(
        user_id: user.id,
        first_name: "Client",
        last_name: SecureRandom.hex(4).capitalize,
        email: "#{SecureRandom.hex(4)}@test.com"
      )
      attrs = { title: title, client: client, mission_status: status, step_template: template, portal_token: SecureRandom.hex(10) }
      attrs[:created_at] = created_at if created_at
      Mission.create!(attrs)
    end
  end
end

# Devise helpers for integration tests
ActionDispatch::IntegrationTest.include Devise::Test::IntegrationHelpers
