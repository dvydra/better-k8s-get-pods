require 'rubygems'
require 'term/ansicolor'
require 'yaml'
require 'time-lord'
require 'date'

class String
  include Term::ANSIColor
end

def max_length(collection, field)
	collection.max_by{|f| f[field].length}[field].length
end

def aged_colour(time_ago)
	return time_ago.red if time_ago.include?("second")
	return time_ago.orange if time_ago.include?("minute")
	return time_ago.green
end

def phase_colour(phase)
	phase == "Running" ? phase.green : phase.red
end

r = YAML.load(`kubectl get pods --all-namespaces -o yaml`)

pods = []
r['items'].each do |pod|
	containers = []
	pod['status']['containerStatuses'].each do |container|
		containers << {ready: container['ready'], restartCount: container['restartCount']}
	end
	pods << {
		name: pod['metadata']['name'],
		phase: pod['status']['phase'],
		namespace: pod['metadata']['namespace'],
		created: pod['status']['startTime'].ago.to_words,
		containers: containers
	}
end

name_length  = max_length(pods, :name) + 3
phase_length = max_length(pods, :phase) + 3
namespace_length = max_length(pods, :namespace) + 3
created_length = max_length(pods, :created) + 3

printf("%-#{name_length}s%-#{phase_length}s%-#{namespace_length}s%-#{created_length}s\n", "Name", "Phase", "Namespace", "Age")
pods.each do |p|
	printf("%-#{name_length}s", p[:name])
	printf("%-#{phase_length}s", phase_colour(p[:phase]))
	printf("%-#{namespace_length}s", p[:namespace])
	printf("%-#{created_length}s", aged_colour(p[:created]))
	print "\n"

end


