# coding: utf-8
require 'rbvmomi'

class VCenter < Object
  attr_accessor :config, :vim, :data_center

public
  def init()
    @config = YAML.load_file("config/vcenter.yml")
    @vim = RbVmomi::VIM.connect host: @config["connection"]["host"], user: @config["connection"]["user"], password: @config["connection"]["pwd"], insecure: true
    @data_center = vim.serviceInstance.find_datacenter(@config["connection"]["datacenter"])
  end

  def backup_vm(vm_path, vm_snapshot='', vm_datastore='')
    vm_name = vm_path.split('/')[-1]
    timestamp = Time.now.utc.strftime('%y%m%d%H%M%S')
    vm = @data_center.find_vm("#{vm_path}")
    backup_folder = @data_center.vmFolder.children.find{|folder| folder.name==@config["backup"]["folder"]}
    iscsi_datastore = @data_center.find_datastore((vm_datastore.nil? || vm_datastore=='') ? @config["backup"]["datastore"] : vm_datastore)
    vm_relocate_spec = { datastore: iscsi_datastore, diskMoveType: :moveAllDiskBackingsAndDisallowSharing, transform: :sparse}
    vm_clone_spec = { location: vm_relocate_spec, powerOn: false, template: false }
    vm_clone_spec[:snapshot] = find_snapshot(vm, vm_snapshot, nil) unless (vm_snapshot.nil? || vm_snapshot=='')
    vm.CloneVM_Task(:folder => backup_folder, :name => "#{vm_name}#{(('_' + vm_snapshot) unless (vm_snapshot.nil? || vm_snapshot=='')).to_s}_#{timestamp}", :spec => vm_clone_spec).wait_for_completion
  end
  
  def find_snapshot(vm, snapshot_name, parent_snapshot)
    found_snapshot = nil
    if parent_snapshot.nil?
      snapshots = vm.snapshot.rootSnapshotList
    else
      snapshots = parent_snapshot.childSnapshotList
    end
    snapshots.each do |snapshot|
      if snapshot.name==snapshot_name
        found_snapshot = snapshot.snapshot
      else
        found_snapshot = find_snapshot(vm, snapshot_name, snapshot) unless snapshot.childSnapshotList.size==0
      end
    end
    return found_snapshot
  end
end