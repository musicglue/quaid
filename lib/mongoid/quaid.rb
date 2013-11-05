module Mongoid
  module Quaid
    extend ActiveSupport::Concern

    included do |klass|
      field :version,     type: Integer,  default: 0

      has_many :versions, class_name: self.to_s + "::Version", foreign_key: "owner_id", dependent: :destroy

      def last_version
        self.class.new versions[1].try(:attributes)
      end

      set_callback :save, :before do |doc|
        doc.version += 1
      end

      set_callback :save, :after do |doc|
        attributes = MultiJson.decode MultiJson.encode doc
        attributes = attributes.merge(owner_id: doc.id)
        attributes = attributes.merge(owner_type: doc._type) if doc._type
        doc.class::Version.create(attributes)
        doc.last_version.try(:set, {deleted_at: DateTime.now})
        if doc.class.versions && doc.versions.count > doc.class.versions
          doc.versions.last.delete
        end
      end

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        class << self
          attr_accessor :versions
          def quaid opts={}
            return unless opts[:versions]
            @versions = opts[:versions]
          end

          def find_with_version id, version
            v = Version.where(owner_id: id, version: version).first.try(:attributes)
            if v.nil?
              nil
            else
              new v
            end
          end
        end

        class Version
          include Mongoid::Document
          include Mongoid::Timestamps
          include Mongoid::Paranoia
          include Mongoid::Attributes::Dynamic
          
          store_in collection: self.to_s.underscore.gsub("/version", "") + "_versions"

          def initialize(attributes={}, options=nil)
            attributes.reject!{ |key, val| ["version_ids", "_id"].include?(key) }
            super(attributes)
          end

          index owner_id: 1
          default_scope desc(:created_at)

          field :deleted_at, type: DateTime
        end
      RUBY
    end

    module ClassMethods
      private
      def get_version_classname
        (self.class.to_s.underscore + "_versions").singularize.camelize
      end
    end



  end
end
