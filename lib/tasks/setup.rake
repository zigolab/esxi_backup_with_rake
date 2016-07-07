require './lib/vcenter'

include RakeHelper

namespace :vcenter do

  desc 'backup vm'
  task :backup_vm, [:vm_name,:vm_snapshot,:vm_datastore] do |t, args|
    abort if args[:vm_name].nil?
    label = "#{args[:vm_name]}#{((' [' + args[:vm_snapshot] + ']') unless (args[:vm_snapshot].nil? || args[:vm_snapshot]=='')).to_s}#{((' [' + args[:vm_datastore] + ']') unless (args[:vm_datastore].nil? || args[:vm_datastore]=='')).to_s}"
    puts "vm: #{label} - starting backup..."
    api = VCenter.new
    api.init
    api.backup_vm args[:vm_name], args[:vm_snapshot], args[:vm_datastore]
    puts "vm: #{label} - backup completed!"
  end
  
end
