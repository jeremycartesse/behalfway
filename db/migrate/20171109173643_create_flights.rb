class CreateFlights < ActiveRecord::Migration[5.0]
  def change
    create_table :flights do |t|
      t.datetime :departure_time
      t.datetime :arrival_time
      t.string :departure_airport_iata_code
      t.string :arrival_airport_iata_code
      t.references :trip, foreign_key: true

      t.timestamps
    end
  end
end
