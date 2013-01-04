class List
  include Mongoid::Document
  include Mongoid::Quaid

  field :name, type: String
  embeds_many :items

end