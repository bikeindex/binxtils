# frozen_string_literal: true

require "shellwords"

namespace :binxtils do
  desc "Count non-whitespace characters (excluding comments). Pass paths as args or defaults to app, bin, config, lib"
  task :char_count do
    file_extensions = %w[.rb .erb .haml .html .js .css .scss .yml .yaml .json .md].freeze

    paths = ARGV.drop(1).reject { |arg| arg.start_with?("-") }
    paths = %w[app bin config lib] if paths.empty?

    files = `git ls-files #{paths.shelljoin}`.split("\n")
      .select { |file| file_extensions.include?(File.extname(file)) }

    total_chars = files.sum do |file|
      next 0 unless File.exist?(file)

      content = File.read(file)
      content_without_comments = case File.extname(file)
      when ".rb", ".yml", ".yaml"
        content.gsub(/#.*$/, "")
      when ".erb", ".haml", ".html"
        content.gsub(/#.*$/, "").gsub(/<!--.*?-->/m, "")
      when ".js", ".css", ".scss"
        content.gsub(%r{//.*$}, "").gsub(%r{/\*.*?\*/}m, "")
      when ".md"
        content.gsub(/<!--.*?-->/m, "")
      else
        content
      end
      content_without_comments.gsub(/\s/, "").length
    end

    puts total_chars

    # Prevent rake from interpreting path args as task names
    paths.each { |path| task(path.to_sym) {} }
  end
end
