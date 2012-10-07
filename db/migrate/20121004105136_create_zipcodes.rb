class CreateZipcodes < ActiveRecord::Migration
  def change
    create_table :zipcodes do |t|
      t.integer :zip
      t.string :city
      t.integer :zip_mail
      t.integer :storkund
      t.integer :county_nr
      t.string :county_text
      t.string :county_sign

      t.integer :municipality_nr
      t.string :municipality_text

      t.integer :region_nr
      t.string :region_text

      t.integer :prefix_nr
      t.string :prefix_text

      t.integer :teleregister_nr
      t.string :teleregister_text

      t.integer :parish
      t.string :long
      t.string :lat
    end
  end
end
