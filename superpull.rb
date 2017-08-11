#!/usr/bin/env ruby

require "open-uri"
require "json"

ignore_file_name = ".superpull_ignore"
stale_repository_criterium = Time.now - (3 * 24 * 60 * 60)

if ARGV.length != 2 || !["user", "org"].include?(ARGV[0])
	abort "Usage: ./superpull.rb [user|org] [account name]"
end

account_type = ARGV[0]
account_name = ARGV[1]

subdirs = Dir["*"].select{|path| File.directory?(path)}
git_subdirs = Dir["**/.git"].select{|path| path.count("/") == 1}.map{|path| path[0...-5]}
non_git_subdirs = subdirs - git_subdirs

if non_git_subdirs.length > 0
	puts "Warning: found #{non_git_subdirs.length} subdirectories that are not git repositories: #{non_git_subdirs.join(", ")}\n\n"
end

page = 1
repository_lookup = {}

loop do
	uri = "https://api.github.com/#{account_type}s/#{account_name}/repos?per_page=100&page=#{page}"
	puts "Doing request for: #{uri}"

	api_result = JSON.load(open(uri).read)
	api_result.each do |repo|
		repository_lookup[repo["name"]] = repo
	end

	break if api_result.length < 100
	page += 1
end

repository_names = repository_lookup.keys
ignored_repository_names = []

if File.exists?(ignore_file_name)
	ignore_file = File.open(ignore_file_name)
	ignored_repository_names = ignore_file.read.split("\n").map(&:strip) & repository_names 
	ignore_file.close
end

new_repository_names = repository_names - git_subdirs - ignored_repository_names
unrecognized_git_subdirs = git_subdirs - repository_names
recognized_git_subdirs = git_subdirs - unrecognized_git_subdirs

if unrecognized_git_subdirs.length > 0
	puts "\nWarning: found local repositories that do not have a corresponding remote repository: #{unrecognized_git_subdirs.join(", ")}"
end

puts "\nFound #{repository_names.length} repositories through Github API. Ignored #{ignored_repository_names.length} through #{ignore_file_name}."
if new_repository_names.length > 0
	puts "There are #{new_repository_names.length} new repositories to clone: #{new_repository_names.join(", ")}."
else
	puts "There are no new repositories to clone."
end

new_repository_names.each do |new_repository_name|
	uri = "git@github.com:#{account_name}/#{new_repository_name}.git"
	puts "\nDoing clone for: #{uri}"

	`git clone #{uri}`
end

# Prepare for updating
stale_git_subdirs = recognized_git_subdirs.select do |git_subdir|
	fetch_file_path = "#{git_subdir}/.git/FETCH_HEAD"
	mtime_file_path = File.exists?(fetch_file_path) ? fetch_file_path : git_subdir
	local_mtime = File.mtime(mtime_file_path)
	
	remote_mtime = Time.parse(repository_lookup[git_subdir]["pushed_at"])

	remote_mtime > local_mtime && stale_repository_criterium > local_mtime
end

puts "\nFound #{stale_git_subdirs.length} git subdirectories that are stale."

stale_git_subdirs.each do |stale_git_subdir|
	puts "\nUpdating repository #{stale_git_subdir}"

	`git -C #{stale_git_subdir} pull --ff-only`
end