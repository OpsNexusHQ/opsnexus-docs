#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "yaml"

MANIFEST = ARGV.fetch(0, "engineering/releases/platform-compatibility.yaml")
REPOSITORY_OWNER = "OpsNexusHQ"
KNOWN_COMPONENTS = %w[
  opsnexus-common opsnexus-agent opsnexus-api opsnexus-backend
  opsnexus-dashboard opsnexus-cli opsnexus-deployment opsnexus-docs
].freeze
COMPATIBILITY_VALUES = %w[supported preview informational deprecated].freeze

def fail!(message)
  warn "ci/compatibility-manifest: #{message}"
  exit 1
end

manifest = YAML.safe_load(File.read(MANIFEST), aliases: false)
fail!("manifest must be a mapping") unless manifest.is_a?(Hash)
platform = manifest["platform"]
components = manifest["components"]
fail!("missing platform mapping") unless platform.is_a?(Hash)
fail!("missing components mapping") unless components.is_a?(Hash)

platform_version = platform["version"]
fail!("platform.version is required") unless platform_version.is_a?(String) && !platform_version.empty?
fail!("platform.compatibility is invalid") unless COMPATIBILITY_VALUES.include?(platform["compatibility"])

missing = KNOWN_COMPONENTS - components.keys
fail!("missing components: #{missing.join(', ')}") unless missing.empty?
unexpected = components.keys - KNOWN_COMPONENTS
fail!("unknown components: #{unexpected.join(', ')}") unless unexpected.empty?

components.each do |name, entry|
  fail!("#{name} must be a mapping") unless entry.is_a?(Hash)
  version = entry["version"]
  sha = entry["commit"]
  fail!("#{name}.version is required") unless version.is_a?(String) && !version.empty?
  fail!("#{name}.commit must be a 40-character SHA") unless sha.is_a?(String) && sha.match?(/\A[0-9a-f]{40}\z/)
  fail!("#{name}.compatibility is invalid") unless COMPATIBILITY_VALUES.include?(entry["compatibility"])

  repo = "https://github.com/#{REPOSITORY_OWNER}/#{name}.git"
  remote_refs, remote_status = Open3.capture2("git", "ls-remote", repo)
  fail!("#{name} commit #{sha} does not exist (#{remote_status.exitstatus})") unless remote_status.success? && remote_refs.lines.any? { |line| line.start_with?(sha) }

  tag = entry["tag"]
  if tag
    fail!("#{name}.tag must be a non-empty string") unless tag.is_a?(String) && !tag.empty?
    tag_sha, tag_status = Open3.capture2("git", "ls-remote", repo, "refs/tags/#{tag}", "refs/tags/#{tag}^{}")
    fail!("#{name} tag #{tag} does not exist (#{tag_status.exitstatus})") unless tag_status.success?
    resolved_line = tag_sha.lines.find { |line| line.end_with?("refs/tags/#{tag}^{}\n") } || tag_sha.lines.find { |line| line.end_with?("refs/tags/#{tag}\n") }
    resolved = resolved_line&.split&.first
    fail!("#{name} tag #{tag} resolves to #{resolved}, expected #{sha}") unless resolved == sha
  end

  if name == "opsnexus-api"
    contract = entry["contract_version"]
    fail!("opsnexus-api.contract_version must be numeric x.y.z") unless contract.is_a?(String) && contract.match?(/\A\d+\.\d+\.\d+\z/)
  end

  migration = entry["migration"]
  if migration
    fail!("#{name}.migration must be a mapping") unless migration.is_a?(Hash)
    fail!("#{name}.migration.state is required") unless migration["state"].is_a?(String) && !migration["state"].empty?
    fail!("#{name}.migration.required must be boolean") unless [true, false].include?(migration["required"])
  end

  image = entry["image"]
  unless image.nil? || image.is_a?(String)
    fail!("#{name}.image must be null or a string")
  end
  if image.is_a?(String) && image.include?("@") && !image.match?(/@sha256:[0-9a-f]{64}\z/)
    fail!("#{name}.image digest is malformed")
  end
end

puts "ci/compatibility-manifest: valid platform #{platform_version} (#{components.length} components)"
