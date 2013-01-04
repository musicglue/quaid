class Project
  include Mongoid::Document
  include Mongoid::Quaid

  field :name, type: String
end