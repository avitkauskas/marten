require "spec"

require "./spec/ext/**"

module Marten
  module Spec
    def self.clear_collected_emails
      return unless Marten.settings.emailing.backend.is_a?(Marten::Emailing::Backend::Dev)

      Marten.settings.emailing.backend.as(Marten::Emailing::Backend::Dev).delivered_emails.clear
    end

    def self.flush_databases
      Marten::DB::Connection.registry.values.each do |conn|
        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.flush_model_tables
        end
      end
    end

    def self.setup_databases
      Marten::DB::Connection.registry.values.each do |conn|
        if !conn.test_database?
          raise "No test database name is explicitly defined for database connection '#{conn.alias}', cancelling..."
        end

        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.sync_models
        end
      end
    end
  end
end

Spec.before_suite &->Marten.setup
Spec.before_suite &->Marten::Spec.setup_databases
Spec.after_each &->Marten::Spec.flush_databases
Spec.after_each &->Marten::Spec.clear_collected_emails
