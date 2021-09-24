# frozen_string_literal: true

namespace :decidim do
  desc "Destroys inactive users"
  task destroy_inactive_users: :environment do
    check_warning_status
    warn_inactive_users
    destroy_inactive_user
  end

  def check_warning_status
    users = Decidim::User.where.not(admin: true)
                         .where.not(warned_at: nil)
                         .where("last_sign_in_at > ?", warning_before_deletion)

    users.find_each do |user|
      user.update!(warned_at: nil)
    end
  end

  def warn_inactive_users
    users = Decidim::User.where.not(admin: true)
                         .where(warned_at: nil)
                         .where("last_sign_in_at < ?", warning_before_deletion)

    users.find_each do |user|
      user.update!(warned_at: Time.current)
      Decidim::DestroyAccountMailer.warn_of_deletion(user).deliver_later
    end
  end

  def destroy_inactive_user
    users = Decidim::User.where.not(admin: true).where.not(warned_at: nil).where("last_sign_in_at < ?", inactivity_before_deletion)

    users.find_each do |user|
      Decidim::DestroyAccount.call(user, Decidim::DeleteAccountForm.from_params(delete_reason: I18n.t("inactive_delete_reason"))) do
        on(:ok) do
          Decidim::ActionLogger.log("delete", user, user, nil, visibility: "admin-only")

          Decidim::DestroyAccountMailer.notify_of_deletion(user).deliver_later
        end
      end
    end
  end

  def inactivity_before_deletion
    inactivity = Rails.application.secrets.dig(:inactivity_before_deletion)

    raise "Missing parameter: warning_before_deletion" if inactivity.empty?

    Time.current - string_to_active_support_duration(inactivity)
  end

  def warning_before_deletion
    warning = Rails.application.secrets.dig(:warning_before_deletion)

    raise "Missing parameter: warning_before_deletion" if warning.empty?

    Time.current - string_to_active_support_duration(warning)
  end

  def string_to_active_support_duration(string)
    time_qty, time_unit = string.split(" ")

    time_qty.to_i.method(time_unit.to_sym).call
  end
end
