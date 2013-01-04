class Item
  include Mongoid::Document

  field :name, type: String

  embedded_in :list
end