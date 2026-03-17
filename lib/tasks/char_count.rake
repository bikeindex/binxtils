# frozen_string_literal: true

require "shellwords"

FILE_EXTENSIONS = %w[.rb .erb .haml .html .js .css .scss .yml .yaml .json .md].freeze

def remove_comments(content, file_path)
  case File.extname(file_path)
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
end

def count_chars(paths)
  files = `git ls-files #{paths.shelljoin}`.split("\n")
    .select { |file| FILE_EXTENSIONS.include?(File.extname(file)) }

  files.sum do |file|
    next 0 unless File.exist?(file)

    content = File.read(file)
    remove_comments(content, file).gsub(/\s/, "").length
  end
end

desc "Count non-whitespace characters (excluding comments). Pass paths as args or defaults to app, bin, config, lib"
task :char_count do
  paths = ARGV.drop(1).reject { |arg| arg.start_with?("-") }
  paths = %w[app bin config lib] if paths.empty?

  puts count_chars(paths)

  # Prevent rake from interpreting path args as task names
  paths.each { |path| task(path.to_sym) {} }
end
