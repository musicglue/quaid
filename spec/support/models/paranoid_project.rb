class ParanoidProject
  include Mongoid::Document
  include Mongoid::Quaid
  include Mongoid::Paranoia

  field :name, type: String

end