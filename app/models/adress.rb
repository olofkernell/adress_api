class Adress < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :zipcode
  has_many :adressnr
end
