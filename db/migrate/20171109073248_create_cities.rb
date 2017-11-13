class CreateCities < ActiveRecord::Migration[5.0]
  def change
    create_table :cities do |t|
      t.string :name
      t.string :iata_code
      t.string :photo_url
      t.string :continent

      t.timestamps
    end
  end
end
