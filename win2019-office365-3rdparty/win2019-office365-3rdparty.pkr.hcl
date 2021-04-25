variable "region" {
  type    = string
  default = "us-west-2"
}

variable "download_url" {
    type    = string
    default = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_13530-20376.exe"
}

locals { 
    timestamp = regex_replace(timestamp(), "[- TZ:]", "") 
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source.
source "amazon-ebs" "firstrun-windows" {
  ami_name      = "win2019-office365-3rdparty-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t3.micro"
  region        = "${var.region}"
  source_ami_filter {
    filters = {
      name                = "*Windows_Server-2019-English-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  user_data_file = "./bootstrap_win.ps1"
  winrm_password = "SuperS3cr3t!!!!"
  winrm_username = "Administrator"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.firstrun-windows"]

  provisioner "powershell" {
    environment_vars = ["download_url=${var.download_url}"]
    script           = "./setup-office-deployment-tool.ps1"
  }
  
  # Download Office 365 apps using the Office Deployment Tool.
  provisioner "windows-shell" {
    script = ".\\scripts\\office365-download.cmd"
  }
}
