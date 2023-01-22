module ManageIQ
  module Floe
    class Workflow
      class Runner
        class Podman < ManageIQ::Floe::Workflow::Runner
          def run!(resource, env = {}, secrets = {})
            raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

            image = resource.gsub("docker://", "")

            secret_guid = nil

            if secrets && !secrets.empty?
              require "securerandom"
              secret_guid = SecureRandom.uuid
              AwesomeSpawn.run!("podman", :params => ["secret", "create", secret_guid, "-"], :in_data => secrets.to_json)
            end

            params = ["run", :rm]
            params += env.map { |k, v| [:e, "#{k}=#{v}"] } if env && !env.empty?
            params << [:secret, secret_guid] if secret_guid
            params << image

            require "awesome_spawn"
            logger.debug("Running podman: #{AwesomeSpawn.build_command_line("docker", params)}")
            result = AwesomeSpawn.run!("podman", :params => params)

            [result.exit_status, result.output]
          ensure
            AwesomeSpawn.run("podman secret rm #{secret_guid}") if secret_guid
          end
        end
      end
    end
  end
end
