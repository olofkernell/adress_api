class Zipcode < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :adress
end
