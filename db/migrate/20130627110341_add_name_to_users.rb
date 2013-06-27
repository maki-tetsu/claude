class AddNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string, limit: 40, null: false, after: :id
  end
end
