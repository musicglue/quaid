require 'ostruct'
require 'monitor'

module Mongoid
  module Quaid
    extend ActiveSupport::Concern

    class << self
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

    included do |klass|
      field :version,     type: Integer,  default: 0

      has_many :versions, class_name: self.to_s + "::Version", foreign_key: "_owner_id", dependent: :destroy

      set_callback :save, :before do |doc|
        if Mongoid::Quaid.config.enabled
          doc.version += 1
        end
      end

      set_callback :save, :after do |doc|
        if Mongoid::Quaid.config.enabled
          attributes = MultiJson.decode MultiJson.encode doc
          attributes = attributes.merge(:_owner_id => doc.id)
          attributes = attributes.merge(:_owner_type => doc._type) if doc.respond_to?(:_type)
          doc.class::Version.create(attributes)
          old = doc.versions.where(version: (doc.version - 1)).first
          if old
            old.set(:deleted_at, DateTime.now)
          end
          if doc.class.versions && doc.versions.count > doc.class.versions
            doc.versions.last.delete
          end
        end
      end

      def last_version
        versions.skip(1).first.try(:attributes)
      end

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        class << self
          attr_accessor :versions
          def quaid opts={}
            return unless opts[:versions]
            @versions = opts[:versions]
          end

          def find_with_version id, version
            Version.where(:_owner_id => id, :version => version).first.try(:attributes)
          end
        end
        class Version
          include Mongoid::Document
          include Mongoid::Timestamps
          include Mongoid::Paranoia

          store_in collection: self.to_s.underscore.gsub("/version", "") + "_versions"

          field :deleted_at, type: DateTime
          field :_owner_id

          def initialize(attrs={}, options=nil)
            attrs.reject!{ |key, val| ["version_ids", "_id"].include?(key) }
            super(attrs)
          end

          index :_owner_id => 1
          index :created_at => -1
          default_scope desc(:created_at)

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

