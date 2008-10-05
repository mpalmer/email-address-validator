require "rake/testtask"
require "rake/clean"
require "rake/rdoctask"
require "rake/gempackagetask"

begin
	require 'rcov/rcovtask'
rescue LoadError
	puts "You do not have rcov installed."
	puts "Coverage tasks won't work for you."
end

PROJECT_VERSION = '0.0.1'

# Ruby library code.
LIB_FILES = FileList["lib/**/*.rb"]

# Options common to RDocTask AND Gem::Specification.
#   The --main argument specifies which file appears on the index.html page
GENERAL_RDOC_OPTS = {
  "--title" => "E-mail validation library"
}

# Output directory for the rdoc html files.
RDOC_HTML_DIR = "doc"

# Filelist with Test::Unit test cases.
TEST_FILES = FileList["test/**/*_test.rb"]

# Files included in distribution
DIST_FILES = FileList["**/*.rb", "**/*.rdoc"]
DIST_FILES.include("Rakefile")
# Don't package files which are autogenerated by RDocTask
DIST_FILES.exclude(/^(\.\/)?#{RDOC_HTML_DIR}(\/|$)/)

# Run the tests if rake is invoked without arguments.
task "default" => ["test"]

Rake::TestTask.new do |t|
  t.test_files = TEST_FILES
  t.libs = ["lib"]
end

Rcov::RcovTask.new('rcov') do |t|
	t.libs << "test"
	t.test_files = TEST_FILES
	t.output_dir = "test/coverage"
	t.verbose = true
	t.rcov_opts << "--exclude '\\A/usr/local/lib'"
	t.rcov_opts << "--exclude '\\A/var/lib/gems'"
end

GEM_SPEC = Gem::Specification.new do |s|
  s.name = 'email-address-validator'
  s.version = PROJECT_VERSION
  s.summary = 'A class to assist in validating e-mail addresses'
  s.homepage = "http://theshed.hezmatt.org/email-address-validator"
  s.author = 'Matt Palmer'
  s.email = 'mpalmer@hezmatt.org'
  s.files = DIST_FILES
  s.test_files = TEST_FILES
  s.has_rdoc = true
  s.rdoc_options = GENERAL_RDOC_OPTS.to_a.flatten
end

Rake::GemPackageTask.new(GEM_SPEC) do |pkg|
  pkg.need_tar_gz = true
  pkg.package_dir = File.dirname(File.dirname(File.expand_path(__FILE__))) + '/builds'
end

Rake::RDocTask.new("rdoc") do |t|
  t.rdoc_files = LIB_FILES
  t.title = GENERAL_RDOC_OPTS["--title"]
  t.main = GENERAL_RDOC_OPTS["--main"]
  t.rdoc_dir = RDOC_HTML_DIR
end
