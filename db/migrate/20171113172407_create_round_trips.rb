class CreateRoundTrips < ActiveRecord::Migration[5.0]
  def change
    create_table :round_trips do |t|

      t.timestamps
    end
  end
end
