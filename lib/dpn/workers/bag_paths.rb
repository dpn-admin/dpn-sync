require 'forwardable'
require 'pairtree'

module DPN
  module Workers
    ##
    # BagPaths manages file system paths used in DPN bag replication
    class BagPaths
      extend Forwardable

      # Public accessors for SyncSettings.replication parameters
      def_delegators :settings, :staging_dir, :storage_dir

      # Initialize accessors for SyncSettings.replication parameters
      # @raise RuntimeError
      def initialize
        @settings = SyncSettings.replication
        raise "Cannot write to staging directory: #{staging_dir}" unless File.writable? staging_dir
        raise "Cannot write to storage directory: #{storage_dir}" unless File.writable? storage_dir
        @pairtree = ::Pairtree.at(storage_dir, create: true)
      end

      # Create a staging directory for 'location'
      #
      # @param [String] location in staging_dir
      # @return [String] path for staging location
      def staging(location)
        destination = File.join(staging_dir, location)
        FileUtils.mkpath(destination).first
      end

      # Create a storage pairtree for 'location'
      #
      # @param [String] location in storage_dir
      # @return [String] path of pairtree for storage location
      def storage(location)
        ppath = pairtree.mk(location)
        ppath.path
      end

      private

      attr_reader :pairtree
      attr_reader :settings # accessor for SyncSettings.replication
    end
  end
end
