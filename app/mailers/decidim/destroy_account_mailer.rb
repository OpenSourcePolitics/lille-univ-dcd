# frozen_string_literal: true

module Decidim
  class DestroyAccountMailer < Decidim::ApplicationMailer
    def notify_of_deletion(user)
      with_user(user) do
        @organization = user.organization
        @user = user
        subject = I18n.t("notify_of_deletion.subject", scope: "decidim.destroy_account_mailer")
        mail(to: user.email, subject: subject)
      end
    end

    def warn_of_deletion(user)
      with_user(user) do
        @organization = user.organization
        @user = user
        subject = I18n.t("warn_of_deletion.subject", scope: "decidim.destroy_account_mailer")
        mail(to: user.email, subject: subject)
      end
    end
  end
end
