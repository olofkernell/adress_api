# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121004105417) do

  create_table "adresses", :force => true do |t|
    t.integer "zipcode_id"
    t.string  "street"
    t.string  "street_nrs"
  end

  create_table "adressnrs", :force => true do |t|
    t.integer "adress_id"
    t.string  "street_nr"
    t.string  "property_label"
    t.string  "street_letters"
  end

  create_table "zipcodes", :force => true do |t|
    t.integer "zip"
    t.string  "city"
    t.integer "zip_mail"
    t.integer "storkund"
    t.integer "county_nr"
    t.string  "county_text"
    t.string  "county_sign"
    t.integer "municipality_nr"
    t.string  "municipality_text"
    t.integer "region_nr"
    t.string  "region_text"
    t.integer "prefix_nr"
    t.string  "prefix_text"
    t.integer "teleregister_nr"
    t.string  "teleregister_text"
    t.integer "parish"
    t.string  "long"
    t.string  "lat"
  end

end
