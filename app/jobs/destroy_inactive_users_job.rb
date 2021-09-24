# frozen_string_literal: true

require "rake"

class DestroyInactiveUsersJob < ApplicationJob
  queue_as :scheduled

  def perform
    system "rake decidim:destroy_inactive_users"
  end
end
