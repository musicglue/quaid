module Mongoid
  module Quaid
    extend ActiveSupport::Concern

    included do |klass|
      field :version,     type: Integer,  default: 0

      has_many :versions, class_name: self.to_s + "::Version", foreign_key: "owner_id"

      def last_version
        self.class.new versions[1].attributes
      end

      klass.class_eval %Q{
        set_callback :save, :before do |doc|
          doc.version += 1
        end

        set_callback :save, :after do |doc|
          attributes = MultiJson.decode MultiJson.encode doc
          Version.create(attributes.merge(owner_id: doc.id))
          doc.last_version.set(deleted_at: DateTime.now)
        end

        class Version
          include Mongoid::Document
          include Mongoid::Timestamps

          store_in collection: self.to_s.underscore.gsub("/version", "") + "_versions"

          def initialize(attributes={}, options=nil)
            attributes.reject!{ |key, val| ["version_ids", "_id"].include?(key) }
            super(attributes)
          end

          index owner_id: 1
          default_scope desc(:created_at)

          field :deleted_at, type: DateTime
        end
      }
    end

    module ClassMethods
      private
      def get_version_classname
        (self.class.to_s.underscore + "_versions").singularize.camelize
      end
    end



  end
end