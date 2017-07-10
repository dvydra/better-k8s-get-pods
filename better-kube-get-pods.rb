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
	return Term::ANSIColor.red if time_ago.include?("second") || time_ago.include?("minute")
	return Term::ANSIColor.yellow if time_ago.include?("hour")
	return Term::ANSIColor.green
end

def phase_colour(phase)
	phase == "Running" ? Term::ANSIColor.green : Term::ANSIColor.red
end

def container_status(container)
	colour = container[:ready] ? Term::ANSIColor.green : Term::ANSIColor.red
	status = "#{colour}#{container[:name]}#{Term::ANSIColor.clear}(#{container[:restartCount]})"
end
r = YAML.load(`kubectl get pods -o yaml`)

pods = []
r['items'].each do |pod|
	containers = []
	pod['status']['containerStatuses'].each do |container|
		containers << {name: container['name'], ready: container['ready'], restartCount: container['restartCount']}
	end
	pods << {
		name: pod['metadata']['name'],
		phase: pod['status']['phase'],
		namespace: pod['metadata']['namespace'],
		created: pod['status']['startTime'].ago.to_words,
		node: pod['spec']['nodeName'],
		containers: containers
	}
end

name_length  = max_length(pods, :name) + 3
phase_length = max_length(pods, :phase) + 3
namespace_length = max_length(pods, :namespace) + 4
created_length = max_length(pods, :created) + 3
node_length = max_length(pods, :node) + 3

printf("%-#{name_length}s%-#{phase_length}s%-#{namespace_length}s%-#{created_length}s\n", "Name", "Phase", "Namespace", "Node", "Age")
pods.each do |p|
	printf("%-#{name_length}s", p[:name])
	printf("%s%-#{phase_length}s#{Term::ANSIColor.clear}", phase_colour(p[:phase]),p[:phase])
	printf("%-#{namespace_length}s", p[:namespace])
	printf("%s%-#{created_length}s#{Term::ANSIColor.clear}", aged_colour(p[:created]), p[:created])
	printf("%-#{node_length}s", p[:node])
	printf(p[:containers].map{|c| container_status(c) }.join(' '))
	print "\n"

end


