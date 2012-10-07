class CreateAdressnrs < ActiveRecord::Migration
  def change
    create_table :adressnrs do |t|
      t.belongs_to :adress
      t.string :street_nr
      t.string :property_label
      t.string :street_letters      
    end
  end
end
