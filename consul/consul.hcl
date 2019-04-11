bootstrap = true
// bootstrap_expect = 1
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
data_dir = "/consul/data"
disable_remote_exec = false
enable_script_checks = false
retry_join = [ "consul" ]
server = true
ui = true
verify_incoming = false
verify_incoming_rpc = true
verify_server_hostname = true
performance {
  raft_multiplier = 1
}
ports {
  dns = 8600
  // server = 8300
  // serf_lan = 8301
  // serf_wan = 8302
  http = -1
  https = 8501
  // grpc = 8502
}
// acl {
//   enabled = true
//   default_policy = "deny"
//   down_policy = "extend-cache"
// }
recursors = [
  "1.0.0.1",
  "1.1.1.1"
]
