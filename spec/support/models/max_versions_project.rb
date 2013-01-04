class MaxVersionsProject
  include Mongoid::Document
  include Mongoid::Quaid

  field :name, type: String

  quaid versions: 5
end