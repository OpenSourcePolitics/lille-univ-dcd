# frozen_string_literal: true

require "spec_helper"
require "support/tasks"

describe "rake decidim:destroy_inactive_users", type: :task do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, warned_at: warned_at, last_sign_in_at: last_sign_in_at) }
  let!(:admin) { create(:user, :admin, organization: organization) }
  let(:last_log) { Decidim::ActionLog.last }

  let(:last_sign_in_at) { Time.current - 2.years }
  let(:warned_at) { Time.current - 1.month }
  let(:data) do
    {
      delete_reason: "Account was deleted due to inactivity"
    }
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "runs gracefully" do
    expect { task.execute }.not_to raise_error
  end

  it "generates a entry in admin logs" do
    task.execute

    expect(last_log.user).to eq(user)
    expect(last_log.action).to eq("delete")
  end

  context "when user are admins" do
    it "doesn't delete their account" do
      task.execute

      expect(admin.reload.deleted_at).to eq(nil)
    end
  end

  context "when user last_sign_at is before warning date" do
    let(:last_sign_in_at) { Time.current - 1.day }
    let(:warned_at) { nil }

    it "does nothing" do
      task.execute

      expect(user.reload.warned_at).to eq(nil)
      expect(user.reload.deleted_at).to eq(nil)
    end
  end

  context "when user last_sign_at is before deletion date" do
    let(:last_sign_in_at) { Time.current - 1.day }
    let(:warned_at) { nil }

    it "does nothing" do
      task.execute

      expect(user.reload.warned_at).to eq(nil)
      expect(user.reload.deleted_at).to eq(nil)
    end
  end

  context "when user last_sign_in_at is after warning date but before deletion date" do
    let(:last_sign_in_at) { Time.current - (17.months + 1.day) }
    let(:warned_at) { nil }

    it "doesn't delete the account" do
      task.execute

      expect(user.reload.warned_at).not_to eq(nil)
      expect(user.reload.deleted_at).to eq(nil)
    end

    it "sends a warning email" do
      allow(Decidim::DestroyAccountMailer).to receive(:warn_of_deletion).with(user).and_call_original

      task.execute

      expect(Decidim::DestroyAccountMailer)
        .to have_received(:warn_of_deletion)
        .with(user)
    end
  end

  context "when user last_sign_in_at is after deletion date and warned_at is not nil" do
    let(:last_sign_in_at) { Time.current - (18.months + 1.day) }
    let(:warn_at) { Time.current - 1.month }

    it "sends a deletion email to users" do
      allow(Decidim::DestroyAccountMailer).to receive(:notify_of_deletion).with(user).and_call_original

      task.execute

      expect(Decidim::DestroyAccountMailer)
        .to have_received(:notify_of_deletion)
        .with(user)
    end

    it "deletes the account with reason" do
      task.execute

      expect(user.reload.deleted_at).not_to eq(nil)
      expect(user.reload.delete_reason).to eq(data[:delete_reason])
    end
  end

  context "when user last_sign_in_at is after warning date and warned_at is not nil" do
    let(:last_sign_in_at) { Time.current }
    let(:warn_at) { Time.current - 1.month }

    it "resets the warned_at and doesn't delete the user" do
      task.execute

      expect(user.reload.warned_at).to eq(nil)
      expect(user.reload.deleted_at).to eq(nil)
    end
  end
end
