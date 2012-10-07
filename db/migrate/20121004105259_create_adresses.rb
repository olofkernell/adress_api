class CreateAdresses < ActiveRecord::Migration
  def change
    create_table :adresses do |t|
      t.belongs_to :zipcode
      t.string :street
      t.string :street_nrs
    end
  end
end
