class AddWarnedAtToDecidimUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_users, :warned_at, :datetime, default: nil
  end
end
