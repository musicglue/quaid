require 'ostruct'
require 'monitor'
require 'mongoid_paranoia'

module Mongoid
  module Quaid
    extend ActiveSupport::Concern

    class << self

      def enable!
        config.enabled = true
      end

      def disable!
        config.enabled = false
      end

      def configure
        config_mutex.synchronize do
          yield config
        end
      end

      def config
        @config ||= OpenStruct.new(enabled: true)
      end

      private

      def config_mutex
        @config_mutex ||= Monitor.new
      end
    end

    module AttrCloner
      def self.clone(doc)
        doc.attributes.dup.tap do |x|
          x.merge!(_owner_id: doc.id)
          x.merge!(_owner_type: doc._type) if doc.respond_to?(:_type)
        end
      end
    end

    included do |klass|
      field :version, type: Integer, default: 0

      has_many :versions_collection, class_name: self.to_s + "::Version", foreign_key: "_owner_id", dependent: :delete_all

      before_save do
        self.version += 1 if Mongoid::Quaid.config.enabled
      end

      after_save do |doc|
        if Mongoid::Quaid.config.enabled
          doc.class::Version.create(Mongoid::Quaid::AttrCloner.clone(doc))
          old = doc.versions.where(version: doc.version.pred).first
          if old
            old.set(deleted_at: DateTime.now)
          end
          if doc.class.versions && doc.versions.count > doc.class.versions
            doc.versions.last.delete!
          end
        end
      end

      def versions
        versions_collection.unscoped.order_by(version: :desc, created_at: :desc)
      end

      def last_version
        versions.unscoped.skip(1).first.try(:attributes)
      end

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        class << self
          attr_accessor :versions
          def quaid opts={}
            return unless opts[:versions]
            @versions = opts[:versions]
          end

          def find_with_version id, version
            Version.unscoped.where(_owner_id: id, version: version).order_by(created_at: :desc).first.try(:attributes)
          end
        end

        class Version
          include Mongoid::Document
          include Mongoid::Timestamps
          include Mongoid::Paranoia
          include Mongoid::Attributes::Dynamic

          store_in collection: self.to_s.underscore.gsub("/version", "") + "_versions"

          field :deleted_at, type: DateTime
          field :_owner_id

          def initialize(attrs={}, options=nil)
            attrs.reject!{ |key, val| ["version_ids", "_id"].include?(key) }
            super(attrs)
          end

          index({ _owner_id: 1, version: 1, created_at: -1 }, { background: true })
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

